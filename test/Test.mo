import M "mo:matchers/Matchers";
import TextMap "../src/TextMap";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

let putGet = S.suite("PutGet", [
    S.test(
        "Fail to look up a missing key",
        TextMap.new<Nat>().get("A"),
        M.equals(T.optional(T.natTestable, null))
    ),
    S.test(
        "Gets a value after inserting it",
        do {
            let map = TextMap.new<Nat>();
            map.put("Hello", 10);
            map.get("Hello")
        },
        M.equals(T.optional(T.natTestable, ?10))
    ),
    S.test(
        "Overrides a value with the same key",
        do {
            let map = TextMap.new<Nat>();
            map.put("Hello", 10);
            map.put("Hello", 20);
            map.get("Hello")
        },
        M.equals(T.optional(T.natTestable, ?20))
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
        M.equals(T.array(T.optionalTestable(T.natTestable), [?10, ?20, ?10, ?20, ?30]))
    )
]);

S.run(putGet);