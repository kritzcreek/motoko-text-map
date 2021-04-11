import Array "mo:base/Array";
import M "mo:matchers/Matchers";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import TMM "../src/Matchers";
import TextMap "../src/TextMap";

func arrayOpt(xs : [?Nat]) : T.TestableItem<[?Nat]> {
    T.array(T.optionalTestable(T.natTestable), xs)
};

func natOpt(x : ?Nat) : T.TestableItem<?Nat> {
    T.optional(T.natTestable, x)
};

let putGet = S.suite("PutGet", [
    S.test(
        "Fail to look up a missing key",
        TextMap.new<Nat>().get("A"),
        M.equals(natOpt(null))
    ),
    S.test(
        "Gets a value after inserting it",
        do {
            let map = TextMap.new<Nat>();
            map.put("Hello", 10);
            map
        },
        TMM.containsElement("Hello", T.nat(10))
    ),
    S.test(
        "Overrides a value with the same key",
        do {
            let map = TextMap.new<Nat>();
            map.put("Hello", 10);
            let old = map.replace("Hello", 20);
            [old, map.get("Hello")]
        },
        M.equals(arrayOpt([?10, ?20]))
    )
]);

let resizeTests = S.suite("ResizeTests", [
    S.test(
        "The map handles resizing",
        do {
            let map = TextMap.TextMap<Nat>(4);
            map.put("A", 10);
            map.put("B", 20);
            let aBefore = map.get("A");
            let bBefore = map.get("B");
            map.put("C", 30);
            let aAfter = map.get("A");
            let bAfter = map.get("B");
            let cAfter = map.get("C");
            [aBefore, bBefore, aAfter, bAfter, cAfter]
        },
        M.equals(arrayOpt([?10, ?20, ?10, ?20, ?30]))
    )
]);

let testMatchers = do {
    let simpleMap = TextMap.new<Nat>();
    simpleMap.put("Hello", 10);
    simpleMap.put("World", 20);

    S.suite("Matchers", [
        S.test(
            "TestableItem",
            simpleMap,
            M.equals(TMM.textMap(T.natTestable, simpleMap))
        ),
        S.test(
            "containsElement",
            simpleMap,
            TMM.containsElement("Hello", T.nat(10))
        ),
        S.test(
            "containsExactly",
            simpleMap,
            TMM.containsExactly(T.natTestable, [("Hello", 10), ("World", 20)])
        )
    ])
};

let deleteTests = S.suite("Deletion", [
    S.test(
        "Simple deletion",
        do {
            let map = TextMap.new<Nat>();
            map.put("Hello", 10);
            map.delete("Hello");
            map
        },
        TMM.containsExactly<Nat>(T.natTestable, [])
    ),
    S.test(
        "Deleting non-existent elements",
        do {
            let map = TextMap.new<Nat>();
            map.delete("Hello");
            map
        },
        TMM.containsExactly<Nat>(T.natTestable, [])
    ),
    S.test(
        "Delete only the requested element",
        do {
            let map = TextMap.new<Nat>();
            map.put("Hello", 10);
            map.put("World", 20);
            map.delete("Hello");
            map
        },
        TMM.containsExactly(T.natTestable, [("World", 20)])
    ),
]);

let collisionTest = do {
    let map = TextMap.new<Nat>();
    // These two collide
    map.put("hetairas", 10);
    map.put("mentioner", 20);
    S.suite("Collisions", [
        S.test("insertion worked", map, M.allOf([
            TMM.containsElement("hetairas", T.nat(10)),
            TMM.containsElement("mentioner", T.nat(20)),
        ])),
        S.test("simple lookup", map, TMM.containsElement("hetairas", T.nat(10))),
        S.test("simple lookup2", map, TMM.containsElement("mentioner", T.nat(20))),
        S.test("delete1",
            do {
                let myMap = map.clone();
                myMap.delete("hetairas");
                myMap
            },
            TMM.containsExactly(
                T.natTestable,
                [("mentioner", 20)]
            )
        ),
        S.test("delete2",
            do {
                let myMap = map.clone();
                myMap.delete("mentioner");
                myMap
            },
            TMM.containsExactly(
                T.natTestable,
                [("hetairas", 10)]
            )
        )
    ])
};

S.run(S.suite("TextMap", [putGet, resizeTests, testMatchers, deleteTests, collisionTest]));
