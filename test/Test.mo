import M "mo:matchers/Matchers";
import TextMap "../src/TextMap";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Debug "mo:base/Debug";


// let suite = S.suite("TextMap", [
//     S.test("anna is a palindrome",
//       Library.isPalindrome("anna"),
//       M.equals(T.bool(true))),
//     S.test("christoph is not a palindrome",
//       Library.isPalindrome("christoph"),
//       M.equals(T.bool(false))),
// ]);

// S.run(suite);

let map = TextMap.new<Nat>();
map.put("A", 10);
map.put("B", 20);

Debug.print(debug_show map.toArray())