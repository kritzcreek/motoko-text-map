import Array "mo:base/Array";
import M "mo:matchers/Matchers";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import TextMap "../src/TextMap";
import TMM "../src/Matchers";

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

S.run(S.suite("TextMap", [putGet, resizeTests, testMatchers]));
