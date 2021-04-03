/// Matchers for TextMap
///
/// The definitions in this module help you write unit tests using the `motoko-matchers` library.
import TextMap "TextMap";
import Nat "mo:base/Nat";

module {

    // Copying Matchers type definitions to avoid adding the dependency
    type Testable<A> = {
        display : A -> Text;
        equals : (A, A) -> Bool
    };

    type TestableItem<A> = {
        display : A -> Text;
        equals : (A, A) -> Bool;
        item : A;
    };

    type Matcher<A> = {
        matches : (item: A) -> Bool;
        describeMismatch : (item : A, description : Description) -> ();
    };

    type Description = {
        appendText : Text -> ();
    };

    public func textMapTestable<A>(aTestable : Testable<A>) : Testable<TextMap.TextMap<A>> {
        {
            display = func (map : TextMap.TextMap<A>) : Text {
                map.toText(aTestable.display)
            };
            equals = func (map1 : TextMap.TextMap<A>, map2 : TextMap.TextMap<A>) : Bool {
                if (map1.size() != map2.size()) {
                    return false
                };
                for ((k, v) in map1.entries()) {
                    switch (map2.get(k)) {
                        case null { return false };
                        case (?a) {
                            if (not aTestable.equals(a, v)) {
                                return false
                            }
                        }
                    }
                };
                return true
            };
        }
    };

    public func textMap<A>(aTestable : Testable<A>, item : TextMap.TextMap<A>) : TestableItem<TextMap.TextMap<A>>  {
        let testable = textMapTestable(aTestable);
        {
            item = item;
            display = testable.display;
            equals = testable.equals;
        }
    };

    public func containsExactly<A>(aTestable : Testable<A>, xs : [(Text, A)]) : Matcher<TextMap.TextMap<A>> {
        {
            matches = func (item : TextMap.TextMap<A>) : Bool {
                textMapTestable(aTestable).equals(TextMap.fromIter(xs.vals()), item)
            };
            describeMismatch = func (item : TextMap.TextMap<A>, description : { appendText : Text -> () }) {
                if (xs.size() != item.size()) {
                    description.appendText(
                        "Size mismatch. Should've been " # Nat.toText(xs.size()) #
                        ", but was " # Nat.toText(item.size()) # "\n"
                    );
                };
                for ((k, v) in xs.vals()) {
                    switch (item.get(k)) {
                        case null {
                            description.appendText(
                                "Missing key: " # k # "\n"
                            );
                        };
                        case (?a) {
                            if (not aTestable.equals(a, v)) {
                                description.appendText(
                                    "Wrong value at key \"" # k #
                                    "\"\nExpected: " # aTestable.display(v) #
                                    "\nActual: " # aTestable.display(a)
                                );
                            };
                        };
                    };
                };
            };
        };
    };

    public func containsElement<A>(key : Text, val : TestableItem<A>) : Matcher<TextMap.TextMap<A>> {
        {
            matches = func (item : TextMap.TextMap<A>) : Bool {
                switch (item.get(key)) {
                    case null { false };
                    case (?v) { val.equals(val.item, v) }
                };
            };
            describeMismatch = func (item : TextMap.TextMap<A>, description : Description) {
                switch (item.get(key)) {
                    case null { description.appendText("Did not contain the key \"" # key # "\"") };
                    case (?v) {
                        if (not val.equals(val.item, v)) {
                            description.appendText("Value at key \"" # key # "\" didn't match\nExpected: " # val.display(val.item)# "\nActual: " # val.display(v))
                        }
                    }
                };
            }
        }
    };
}
