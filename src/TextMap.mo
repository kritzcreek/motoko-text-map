/// A HashMap with Text keys
///
/// TODO: Write an example
// Follows the Hash-Tables chapter in "Algorithms 4th Edition" from Sedgewick and Wayne
// Uses open addressing with linear probing. Hashes with djb2
//
// Slight modification is that we store full hashes as well, because comparing text
// equality is expensive, and we can avoid rehashing when resizing
import Array "mo:base/Array";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";

module {

  /// Constructs an empty TextMap.
  ///
  /// If you'd like to specify the initial capacity yourself
  /// you can call the `TextMap` constructor instead.
  public func new<A>() : TextMap<A> {
    TextMap<A>(16)
  };

  /// Constructs a TextMap from an iterator.
  ///
  /// ```motoko
  /// import TextMap "mo:text-map/TextMap";
  /// let map = TextMap.fromIter<Nat>(
  ///     [("A", 1), ("B", 2), ("C", 3)].vals()
  /// );
  /// assert(map.toText(Nat.toText) == "{ A => 1; B => 2; C => 3; }")
  /// ```
  public func fromIter<A>(iter : Iter.Iter<(Text, A)>) : TextMap<A> {
    let map = new<A>();
    for ((key, value) in iter) {
      map.put(key, value);
    };
    return map
  };

  // This is used in `TextMap.resize`. Its differences to the usual `put` are:
  // 1. We don't need to hash, as we already stored the full hash for existing keys
  // 2. We don't check whether we need to resize again
  // 3. We don't check for the case of overwriting an existing key
  // 4. We don't keep track of the element count
  func putResize<A>(map : TextMap<A>, capacity : Nat, hsh : Nat32, key : Text, value : A) {
    var i : Nat = Nat32.toNat(hsh) % capacity;
    while(map.keys[i] != null) {
      i := (i + 1) % capacity;
    };
    map.keys[i] := ?key;
    map.hashes[i] := hsh;
    map.vals[i] := ?value;
  };

  /// A hashmap with `Text` keys.
  public class TextMap<A>(initialCapacity : Nat) {
    // Hate having to make these public (see resize() for why)
    public var keys : [var ?Text] = Array.init(initialCapacity, null);
    public var hashes : [var Nat32] = Array.init(initialCapacity, 0 : Nat32);
    public var vals : [var ?A] = Array.init(initialCapacity, null);
    var capacity : Nat = initialCapacity;
    var count : Nat = 0;

    public func size() : Nat {
      return count
    };

    /// Inserts a value into the `TextMap`. Existing entries with the same key are overriden.
    /// ```motoko
    /// import TextMap "mo:text-map/TextMap";
    /// let map = TextMap.new<Nat>();
    ///
    /// map.put("A", 10);
    /// assert(map.toText(Nat.toText) == "{ A => 10; }");
    ///
    /// map.put("A", 20);
    /// assert(map.toText(Nat.toText) == "{ A => 20; }");
    /// ```
    public func put(key : Text, value : A) {
      ignore replace(key, value)
    };

    /// Inserts a value into the `TextMap`. If there's an existing value with the same key,
    /// returns that value otherwise `null`.
    /// ```motoko
    /// import TextMap "mo:text-map/TextMap";
    /// let map = TextMap.new<Nat>();
    ///
    /// let old1 = map.replace("A", 10);
    /// assert(old1 == null);
    /// assert(map.toText(Nat.toText) == "{ A => 10; }");
    ///
    /// let old2 = map.replace("A", 20);
    /// assert(old2 == ?10);
    /// assert(map.toText(Nat.toText) == "{ A => 20; }");
    /// ```
    public func replace(key : Text, value : A) : ?A {
      if (count >= capacity / 2) {
        resize(capacity * 2)
      };

      let hsh = djb2(key);
      var i : Nat = Nat32.toNat(hsh) % capacity;
      while(keys[i] != null) {
        // If the keys are textually equal, we override the
        // value for an existing key
        if (hashes[i] == hsh and keys[i] == ?key) {
          let old = vals[i];
          vals[i] := ?value;
          return old;
        };
        i := (i + 1) % capacity;
      };
      keys[i] := ?key;
      hashes[i] := hsh;
      vals[i] := ?value;
      count += 1;
      return null;
    };

    /// Gets the value at the given key. Returns `null` if the value can't be found.
    ///
    /// ```motoko
    /// let map = TextMap.new<Nat>();
    ///
    /// let notFound = map.get("A");
    /// assert(notFound == null);
    ///
    /// map.put("A", 10);
    /// let found = map.get("A",);
    /// assert(found == ?10);
    /// ```
    public func get(key : Text) : ?A {
      let hsh = djb2(key);
      var i : Nat = Nat32.toNat(hsh) % capacity;
      while(keys[i] != null) {
        if (hashes[i] == hsh and keys[i] == ?key) {
          return vals[i]
        };
        i := (i + 1) % capacity;
      };
      return null;
    };

    /// Removes the given key from the map. Does nothing if the key didn't exist.
    public func delete(key : Text) {
      if (not contains(key)) { return };
      let hsh = djb2(key);
      var i : Nat = Nat32.toNat(hsh) % capacity;
      while(hashes[i] != hsh and keys[i] != ?key) {
        i := (i + 1) % capacity;
      };
      keys[i] := null;
      vals[i] := null;
      hashes[i] := 0;

      i := (i + 1) % capacity;

      while(keys[i] != null) {
        let keyToRedo = Option.unwrap(keys[i]);
        let valToRedo = Option.unwrap(vals[i]);
        keys[i] := null;
        vals[i] := null;
        hashes[i] := 0;
        count -= 1;
        put(keyToRedo, valToRedo);
        i := (i + 1) % capacity;
      };

      count -= 1;
      if (count > 0 and count == capacity / 8) {
        resize(capacity / 2)
      };
    };

    /// Checks whether the given key is present in the map.
    public func contains(key : Text) : Bool {
      Option.isSome(get(key))
    };

    /// Iterates over all key value pairs in this map.
    ///
    /// Careful! This Iterator is invalidated when its
    /// underlying TextMap is modified.
    // TODO: Maybe this shouldn't be exposed?
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

    /// Returns an Array of all key value pairs contained in this map.
    public func toArray() : [(Text, A)] {
      Iter.toArray(entries())
    };

    /// Creates a copy of this map. Modifying the copy does not modify this instance.
    public func clone() : TextMap<A> {
      fromIter(entries())
    };

    /// Primarily useful for debugging
    public func toText(toTextA : A -> Text) : Text {
      var res : Text = "{";
      for ((k, v) in entries()) {
        res #= " " # k # " => " # toTextA(v) # ";";
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
          // We're not making `putResize` a member function as it would have to be
          // public for me to call it here. Unfortunately that means I have to make
          // the internal representation public so `putResize` can access it.
          // This is not a problem in Java where visibility is not "instance based",
          // but class based
          putResize(newMap, newCapacity, hashes[ix], keys[ix]!, vals[ix]!)
        }
      };
      keys := newMap.keys;
      vals := newMap.vals;
      hashes := newMap.hashes;
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
