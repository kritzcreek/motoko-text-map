/// A HashMap with Text keys
///
/// TODO: Write me
import Array "mo:base/Array";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";

module {

  public func new<A>() : TextMap<A> {
    TextMap<A>(16)
  };

  public func fromIter<A>(iter : Iter.Iter<(Text, A)>) : TextMap<A> {
    let map = new<A>();
    for ((key, value) in iter) {
      map.put(key, value);
    };
    return map
  };

  public class TextMap<A>(initialCapacity : Nat) {
    // Hate having to make these public (see resize() for why)
    public var keys : [var ?Text] = Array.init(initialCapacity, null);
    public var vals : [var ?A] = Array.init(initialCapacity, null);
    var capacity : Nat = initialCapacity;
    var count : Nat = 0;

    public func size() : Nat {
      return count
    };

    public func put(key : Text, value : A) {
      ignore replace(key, value)
    };

    public func replace(key : Text, value : A) : ?A {
      if (count >= capacity / 2) {
        resize(capacity * 2)
      };
      var i : Nat = hash(key);
      while(keys[i] != null) {
        // If the keys are textually equal, we override the
        // value for an existing key
        if (keys[i] == ?key) {
          let old = vals[i];
          vals[i] := ?value;
          return old;
        };
        i := (i + 1) % capacity;
      };
      keys[i] := ?key;
      vals[i] := ?value;
      count += 1;
      return null;
    };

    public func get(key : Text) : ?A {
      var i : Nat = hash(key);
      while(keys[i] != null) {
        if (keys[i] == ?key) {
          return vals[i]
        };
        i := (i + 1) % capacity;
      };
      return null;
    };

    public func delete(key : Text) {
      if (not contains(key)) { return };
      var i = hash(key);
      while(keys[i] != ?key) {
        i := (i + 1) % capacity;
      };
      keys[i] := null;
      vals[i] := null;

      i := (i + 1) % capacity;

      while(keys[i] != null) {
        let keyToRedo = Option.unwrap(keys[i]);
        let valToRedo = Option.unwrap(vals[i]);
        keys[i] := null;
        vals[i] := null;
        count -= 1;
        put(keyToRedo, valToRedo);
        i := (i + 1) % capacity;
      };

      count -= 1;
      if (count > 0 and count == capacity / 8) {
        resize(capacity / 2)
      };
    };

    public func contains(key : Text) : Bool {
      Option.isSome(get(key))
    };

    /// Careful: This Iterator is invalidated when its TextMap is modified
    /// Maybe this should be private?
    public func entries() : Iter.Iter<(Text, A)> {
      var i : Nat = 0;
      { next = func() : ?(Text, A) {
          while(i < capacity) {
            switch (keys[i], vals[i]) {
              case (?k, ?v) {
                i += 1;
                return (?(k, v))
              };
              case _ { i += 1 };
            };
          };
          return null;
        }
      }
    };

    public func toArray() : [(Text, A)] {
      Iter.toArray(entries())
    };

    public func clone() : TextMap<A> {
      fromIter(entries())
    };

    /// Primarily useful for debugging
    public func toText(toTextA : A -> Text) : Text {
      var res : Text = "{";
      for ((k, v) in entries()) {
          res #= " " # k # " = " # toTextA(v) # ";";
      };
      res # " }"
    };

    func hash(key : Text) : Nat {
      Nat32.toNat(djb2(key)) % capacity
    };

    func resize(newCapacity : Nat) {
      let newMap : TextMap<A> = TextMap(newCapacity);
      for (ix in Iter.range(0, capacity - 1)) {
        ignore do? {
          newMap.put(keys[ix]!, vals[ix]!)
        }
      };
      keys := newMap.keys;
      vals := newMap.vals;
      capacity := newCapacity;
    };
  };

  // Copied from http://www.cse.yorku.ca/~oz/hash.html.
  // This should be a little better than base's current text hash.
  func djb2(t : Text) : Nat32 {
    var hash : Nat32 = 5381;
    for (char in t.chars()) {
      let c : Nat32 = Char.toNat32(char);
      hash := ((hash << 5) +% hash) +% c;
    };
    return hash
  };
}
