//===--- Range.swift ------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A type that can be used to slice a collection.
///
/// A type that conforms to `RangeExpression` can convert itself to a
/// `Range<Bound>` of indices within a given collection.
public protocol RangeExpression {
  /// The type for which the expression describes a range.
  associatedtype Bound: Comparable

  /// Returns the range of indices described by this range expression within
  /// the given collection.
  ///
  /// You can use the `relative(to:)` method to convert a range expression,
  /// which could be missing one or both of its endpoints, into a concrete
  /// range that is bounded on both sides. The following example uses this
  /// method to convert a partial range up to `4` into a half-open range,
  /// using an array instance to add the range's lower bound.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     let upToFour = ..<4
  ///
  ///     let r1 = upToFour.relative(to: numbers)
  ///     // r1 == 0..<4
  ///
  /// The `r1` range is bounded on the lower end by `0` because that is the
  /// starting index of the `numbers` array. When the collection passed to
  /// `relative(to:)` starts with a different index, that index is used as the
  /// lower bound instead. The next example creates a slice of `numbers`
  /// starting at index `2`, and then uses the slice with `relative(to:)` to
  /// convert `upToFour` to a concrete range.
  ///
  ///     let numbersSuffix = numbers[2...]
  ///     // numbersSuffix == [30, 40, 50, 60, 70]
  ///
  ///     let r2 = upToFour.relative(to: numbersSuffix)
  ///     // r2 == 2..<4
  ///
  /// Use this method only if you need the concrete range it produces. To
  /// access a slice of a collection using a range expression, use the
  /// collection's generic subscript that uses a range expression as its
  /// parameter.
  ///
  ///     let numbersPrefix = numbers[upToFour]
  ///     // numbersPrefix == [10, 20, 30, 40]
  ///
  /// - Parameter collection: The collection to evaluate this range expression
  ///   in relation to.
  /// - Returns: A range suitable for slicing `collection`. The returned range
  ///   is *not* guaranteed to be inside the bounds of `collection`. Callers
  ///   should apply the same preconditions to the return value as they would
  ///   to a range provided directly by the user.
  func relative<C: Collection>(
    to collection: C
  ) -> Range<Bound> where C.Index == Bound
  
  /// Returns a Boolean value indicating whether the given element is contained
  /// within the range expression.
  ///
  /// - Parameter element: The element to check for containment.
  /// - Returns: `true` if `element` is contained in the range expression;
  ///   otherwise, `false`.
  func contains(_ element: Bound) -> Bool
}

extension RangeExpression {
  @_inlineable
  public static func ~= (pattern: Self, value: Bound) -> Bool {
    return pattern.contains(value)
  }  
}

/// A half-open interval over a comparable type, from a lower bound up to, but
/// not including, an upper bound.
///
/// You create `Range` instances by using the half-open range operator (`..<`).
///
///     let underFive = 0.0..<5.0
///
/// You can use a `Range` instance to quickly check if a value is contained in
/// a particular range of values. For example:
///
///     print(underFive.contains(3.14))     // Prints "true"
///     print(underFive.contains(6.28))     // Prints "false"
///     print(underFive.contains(5.0))      // Prints "false"
///
/// `Range` instances can represent an empty interval, unlike `ClosedRange`.
///
///     let empty = 0.0..<0.0
///     print(empty.contains(0.0))          // Prints "false"
///     print(empty.isEmpty)                // Prints "true"
@_fixed_layout
public struct Range<Bound : Comparable> {
  /// The range's lower bound.
  ///
  /// In an empty range, `lowerBound` is equal to `upperBound`.
  public let lowerBound: Bound

  /// The range's upper bound.
  ///
  /// In an empty range, `upperBound` is equal to `lowerBound`. A `Range`
  /// instance does not contain its upper bound.
  public let upperBound: Bound

  /// Creates an instance with the given bounds.
  ///
  /// Because this initializer does not perform any checks, it should be used
  /// as an optimization only when you are absolutely certain that `lower` is
  /// less than or equal to `upper`. Using the half-open range operator
  /// (`..<`) to form `Range` instances is preferred.
  ///
  /// - Parameter bounds: A tuple of the lower and upper bounds of the range.
  @_inlineable
  public init(uncheckedBounds bounds: (lower: Bound, upper: Bound)) {
    self.lowerBound = bounds.lower
    self.upperBound = bounds.upper
  }

  /// Returns a Boolean value indicating whether the given element is contained
  /// within the range.
  ///
  /// Because `Range` represents a half-open range, a `Range` instance does not
  /// contain its upper bound. `element` is contained in the range if it is
  /// greater than or equal to the lower bound and less than the upper bound.
  ///
  /// - Parameter element: The element to check for containment.
  /// - Returns: `true` if `element` is contained in the range; otherwise,
  ///   `false`.
  @_inlineable
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element && element < upperBound
  }

  /// A Boolean value indicating whether the range contains no elements.
  ///
  /// An empty `Range` instance has equal lower and upper bounds.
  ///
  ///     let empty: Range = 10..<10
  ///     print(empty.isEmpty)
  ///     // Prints "true"
  @_inlineable
  public var isEmpty: Bool {
    return lowerBound == upperBound
  }
}

extension Range: Sequence
where Bound: Strideable, Bound.Stride : SignedInteger {
  public typealias Element = Bound
  public typealias Iterator = IndexingIterator<Range<Bound>>
}

// FIXME: should just be RandomAccessCollection
extension Range: Collection, BidirectionalCollection, RandomAccessCollection
where Bound : Strideable, Bound.Stride : SignedInteger
{
  /// A type that represents a position in the range.
  public typealias Index = Bound
  public typealias Indices = Range<Bound>
  public typealias SubSequence = Range<Bound>

  @_inlineable
  public var startIndex: Index { return lowerBound }

  @_inlineable
  public var endIndex: Index { return upperBound }

  @_inlineable
  public func index(after i: Index) -> Index {
    _failEarlyRangeCheck(i, bounds: startIndex..<endIndex)

    return i.advanced(by: 1)
  }

  @_inlineable
  public func index(before i: Index) -> Index {
    _precondition(i > lowerBound)
    _precondition(i <= upperBound)

    return i.advanced(by: -1)
  }

  @_inlineable
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    let r = i.advanced(by: numericCast(n))
    _precondition(r >= lowerBound)
    _precondition(r <= upperBound)
    return r
  }

  @_inlineable
  public func distance(from start: Index, to end: Index) -> Int {
    return numericCast(start.distance(to: end))
  }

  /// Accesses the subsequence bounded by the given range.
  ///
  /// - Parameter bounds: A range of the range's indices. The upper and lower
  ///   bounds of the `bounds` range must be valid indices of the collection.
  @_inlineable
  public subscript(bounds: Range<Index>) -> Range<Bound> {
    return bounds
  }

  /// The indices that are valid for subscripting the range, in ascending
  /// order.
  @_inlineable
  public var indices: Indices {
    return self
  }

  @_inlineable
  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return lowerBound <= element && element < upperBound
  }

  /// Accesses the element at specified position.
  ///
  /// You can subscript a collection with any valid index other than the
  /// collection's end index. The end index refers to the position one past
  /// the last element of a collection, so it doesn't correspond with an
  /// element.
  ///
  /// - Parameter position: The position of the element to access. `position`
  ///   must be a valid index of the range, and must not equal the range's end
  ///   index.
  @_inlineable
  public subscript(position: Index) -> Element {
    // FIXME: swift-3-indexing-model: tests for the range check.
    _debugPrecondition(self.contains(position), "Index out of range")
    return position
  }
}

extension Range where Bound: Strideable, Bound.Stride : SignedInteger {
  /// Now that Range is conditionally a collection when Bound: Strideable,
  /// CountableRange is no longer needed. This is a deprecated initializer
  /// for any remaining uses of Range(countableRange).
  @available(*,deprecated: 4.2, 
    message: "CountableRange is now Range. No need to convert any more.")
  public init(_ other: Range<Bound>) {
    self = other
  }  
  
  /// Creates an instance equivalent to the given `ClosedRange`.
  ///
  /// - Parameter other: A closed range to convert to a `Range` instance.
  ///
  /// An equivalent range must be representable as an instance of Range<Bound>.
  /// For example, passing a closed range with an upper bound of `Int.max`
  /// triggers a runtime error, because the resulting half-open range would
  /// require an upper bound of `Int.max + 1`, which is not representable as
  public init(_ other: ClosedRange<Bound>) {
    let upperBound = other.upperBound.advanced(by: 1)
    self.init(uncheckedBounds: (lower: other.lowerBound, upper: upperBound))
  }
}

extension Range: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))
  }
}

extension Range {
  /// Returns a copy of this range clamped to the given limiting range.
  ///
  /// The bounds of the result are always limited to the bounds of `limits`.
  /// For example:
  ///
  ///     let x: Range = 0${op}20
  ///     print(x.clamped(to: 10${op}1000))
  ///     // Prints "10${op}20"
  ///
  /// If the two ranges do not overlap, the result is an empty range within the
  /// bounds of `limits`.
  ///
  ///     let y: Range = 0${op}5
  ///     print(y.clamped(to: 10${op}1000))
  ///     // Prints "10${op}10"
  ///
  /// - Parameter limits: The range to clamp the bounds of this range.
  /// - Returns: A new range clamped to the bounds of `limits`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func clamped(to limits: Range) -> Range {
    let lower =         
      limits.lowerBound > self.lowerBound ? limits.lowerBound
          : limits.upperBound < self.lowerBound ? limits.upperBound
          : self.lowerBound
    let upper =
      limits.upperBound < self.upperBound ? limits.upperBound
          : limits.lowerBound > self.upperBound ? limits.lowerBound
          : self.upperBound
    return Range(uncheckedBounds: (lower: lower, upper: upper))
  }
}

extension Range : CustomStringConvertible {
  /// A textual representation of the range.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return "\(lowerBound)..<\(upperBound)"
  }
}

extension Range : CustomDebugStringConvertible {
  /// A textual representation of the range, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "Range(\(String(reflecting: lowerBound))"
    + "..<\(String(reflecting: upperBound)))"
  }
}

extension Range : CustomReflectable {
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(
      self, children: ["lowerBound": lowerBound, "upperBound": upperBound])
  }
}

extension Range: Equatable {
  /// Returns a Boolean value indicating whether two ranges are equal.
  ///
  /// Two ranges are equal when they have the same lower and upper bounds.
  /// That requirement holds even for empty ranges.
  ///
  ///     let x: Range = 5..<15
  ///     print(x == 5..<15)
  ///     // Prints "true"
  ///
  ///     let y: Range = 5..<5
  ///     print(y == 15..<15)
  ///     // Prints "false"
  ///
  /// - Parameters:
  ///   - lhs: A range to compare.
  ///   - rhs: Another range to compare.
  @_inlineable
  public static func == (lhs: Range<Bound>, rhs: Range<Bound>) -> Bool {
    return
      lhs.lowerBound == rhs.lowerBound &&
      lhs.upperBound == rhs.upperBound
  }
}

/// A partial half-open interval up to, but not including, an upper bound.
///
/// You create `PartialRangeUpTo` instances by using the prefix half-open range
/// operator (prefix `..<`).
///
///     let upToFive = ..<5.0
///
/// You can use a `PartialRangeUpTo` instance to quickly check if a value is
/// contained in a particular range of values. For example:
///
///     upToFive.contains(3.14)       // true
///     upToFive.contains(6.28)       // false
///     upToFive.contains(5.0)        // false
///
/// You can use a `PartialRangeUpTo` instance of a collection's indices to
/// represent the range from the start of the collection up to, but not
/// including, the partial range's upper bound.
///
///     let numbers = [10, 20, 30, 40, 50, 60, 70]
///     print(numbers[..<3])
///     // Prints "[10, 20, 30]"
@_fixed_layout
public struct PartialRangeUpTo<Bound: Comparable> {
  public let upperBound: Bound
  
  @_inlineable // FIXME(sil-serialize-all)
  public init(_ upperBound: Bound) { self.upperBound = upperBound }
}

extension PartialRangeUpTo: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return collection.startIndex..<self.upperBound
  }
  
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func contains(_ element: Bound) -> Bool {
    return element < upperBound
  }
}

/// A partial half-open interval up to, and including, an upper bound.
///
/// You create `PartialRangeThrough` instances by using the prefix closed range
/// operator (prefix `...`).
///
///     let throughFive = ...5.0
///
/// You can use a `PartialRangeThrough` instance to quickly check if a value is
/// contained in a particular range of values. For example:
///
///     throughFive.contains(4.0)     // true
///     throughFive.contains(5.0)     // true
///     throughFive.contains(6.0)     // false
///
/// You can use a `PartialRangeThrough` instance of a collection's indices to
/// represent the range from the start of the collection up to, and including,
/// the partial range's upper bound.
///
///     let numbers = [10, 20, 30, 40, 50, 60, 70]
///     print(numbers[...3])
///     // Prints "[10, 20, 30, 40]"
@_fixed_layout
public struct PartialRangeThrough<Bound: Comparable> {  
  public let upperBound: Bound
  
  @_inlineable // FIXME(sil-serialize-all)
  public init(_ upperBound: Bound) { self.upperBound = upperBound }
}

extension PartialRangeThrough: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return collection.startIndex..<collection.index(after: self.upperBound)
  }
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func contains(_ element: Bound) -> Bool {
    return element <= upperBound
  }
}

/// A partial interval extending upward from a lower bound that forms a
/// sequence of increasing values.
///
/// You create `PartialRangeFrom` instances by using the postfix range
/// operator (postfix `...`).
///
///     let atLeastFive = 5...
///
/// You can use a countable partial range to quickly check if a value is
/// contained in a particular range of values. For example:
///
///     atLeastFive.contains(4)     // false
///     atLeastFive.contains(5)     // true
///     atLeastFive.contains(6)     // true
///
/// You can use a countable partial range of a collection's indices to
/// represent the range from the partial range's lower bound up to the end of
/// the collection.
///
///     let numbers = [10, 20, 30, 40, 50, 60, 70]
///     print(numbers[3...])
///     // Prints "[40, 50, 60, 70]"
///
/// You can create a countable partial range over any type that conforms to the
/// `Strideable` protocol and uses an integer as its associated `Stride` type.
/// By default, Swift's integer and pointer types are usable as the bounds of
/// a countable range.
///
/// Using a Partial Range as a Sequence
/// ===================================
///
/// You can iterate over a countable partial range using a `for`-`in` loop, or
/// call any sequence method that doesn't require that the sequence is finite.
///
///     func isTheMagicNumber(_ x: Int) -> Bool {
///         return x == 3
///     }
///
///     for x in 1... {
///         if isTheMagicNumber(x) {
///             print("\(x) is the magic number!")
///             break
///         } else {
///             print("\(x) wasn't it...")
///         }
///     }
///     // "1 wasn't it..."
///     // "2 wasn't it..."
///     // "3 is the magic number!"
///
/// Because a `PartialRangeFrom` sequence counts upward indefinitely,
/// do not use one with methods that read the entire sequence before
/// returning, such as `map(_:)`, `filter(_:)`, or `suffix(_:)`. It is safe to
/// use operations that put an upper limit on the number of elements they
/// access, such as `prefix(_:)` or `dropFirst(_:)`, and operations that you
/// can guarantee will terminate, such as passing a closure you know will
/// eventually return `true` to `first(where:)`.
///
/// In the following example, the `asciiTable` sequence is made by zipping
/// together the characters in the `alphabet` string with a partial range
/// starting at 65, the ASCII value of the capital letter A. Iterating over
/// two zipped sequences continues only as long as the shorter of the two
/// sequences, so the iteration stops at the end of `alphabet`.
///
///     let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
///     let asciiTable = zip(65..., alphabet)
///     for (code, letter) in asciiTable {
///         print(code, letter)
///     }
///     // "65 A"
///     // "66 B"
///     // "67 C"
///     // ...
///     // "89 Y"
///     // "90 Z"
///
/// The behavior of incrementing indefinitely is determined by the type of
/// `Bound`. For example, iterating over an instance of
/// `PartialRangeFrom<Int>` traps when the sequence's next value
/// would be above `Int.max`.
@_fixed_layout
public struct PartialRangeFrom<Bound: Comparable> {
  public let lowerBound: Bound

  @_inlineable // FIXME(sil-serialize-all)
  public init(_ lowerBound: Bound) { self.lowerBound = lowerBound }
}

extension PartialRangeFrom: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func relative<C: Collection>(
    to collection: C
  ) -> Range<Bound> where C.Index == Bound {
    return self.lowerBound..<collection.endIndex
  }
  @_inlineable // FIXME(sil-serialize-all)
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element
  }
}

extension PartialRangeFrom: Sequence
  where Bound : Strideable, Bound.Stride : SignedInteger
{
  public typealias Element = Bound

  @_fixed_layout
  public struct Iterator: IteratorProtocol {
    @_versioned
    internal var _current: Bound
    @_inlineable
    public init(_current: Bound) { self._current = _current }
    @_inlineable
    public mutating func next() -> Bound? {
      defer { _current = _current.advanced(by: 1) }
      return _current
    }
  }
  @_inlineable
  public func makeIterator() -> Iterator { 
    return Iterator(_current: lowerBound) 
  }
}

extension Comparable {
  /// Returns a half-open range that contains its lower bound but not its upper
  /// bound.
  ///
  /// Use the half-open range operator (`..<`) to create a range of any type that
  /// conforms to the `Comparable` protocol. This example creates a
  /// `Range<Double>` from zero up to, but not including, 5.0.
  ///
  ///     let lessThanFive = 0.0..<5.0
  ///     print(lessThanFive.contains(3.14))  // Prints "true"
  ///     print(lessThanFive.contains(5.0))   // Prints "false"
  ///
  /// - Parameters:
  ///   - minimum: The lower bound for the range.
  ///   - maximum: The upper bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func ..< (minimum: Self, maximum: Self) -> Range<Self> {
    _precondition(minimum <= maximum,
      "Can't form Range with upperBound < lowerBound")
    return Range(uncheckedBounds: (lower: minimum, upper: maximum))
  }

  /// Returns a partial range up to, but not including, its upper bound.
  ///
  /// Use the prefix half-open range operator (prefix `..<`) to create a
  /// partial range of any type that conforms to the `Comparable` protocol.
  /// This example creates a `PartialRangeUpTo<Double>` instance that includes
  /// any value less than `5.0`.
  ///
  ///     let upToFive = ..<5.0
  ///
  ///     upToFive.contains(3.14)       // true
  ///     upToFive.contains(6.28)       // false
  ///     upToFive.contains(5.0)        // false
  ///
  /// You can use this type of partial range of a collection's indices to
  /// represent the range from the start of the collection up to, but not
  /// including, the partial range's upper bound.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     print(numbers[..<3])
  ///     // Prints "[10, 20, 30]"
  ///
  /// - Parameter maximum: The upper bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static prefix func ..< (maximum: Self) -> PartialRangeUpTo<Self> {
    return PartialRangeUpTo(maximum)
  }

  /// Returns a partial range up to, and including, its upper bound.
  ///
  /// Use the prefix closed range operator (prefix `...`) to create a partial
  /// range of any type that conforms to the `Comparable` protocol. This
  /// example creates a `PartialRangeThrough<Double>` instance that includes
  /// any value less than or equal to `5.0`.
  ///
  ///     let throughFive = ...5.0
  ///
  ///     throughFive.contains(4.0)     // true
  ///     throughFive.contains(5.0)     // true
  ///     throughFive.contains(6.0)     // false
  ///
  /// You can use this type of partial range of a collection's indices to
  /// represent the range from the start of the collection up to, and
  /// including, the partial range's upper bound.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     print(numbers[...3])
  ///     // Prints "[10, 20, 30, 40]"
  ///
  /// - Parameter maximum: The upper bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static prefix func ... (maximum: Self) -> PartialRangeThrough<Self> {
    return PartialRangeThrough(maximum)
  }

  /// Returns a partial range extending upward from a lower bound.
  ///
  /// Use the postfix range operator (postfix `...`) to create a partial range
  /// of any type that conforms to the `Comparable` protocol. This example
  /// creates a `PartialRangeFrom<Double>` instance that includes any value
  /// greater than or equal to `5.0`.
  ///
  ///     let atLeastFive = 5.0...
  ///
  ///     atLeastFive.contains(4.0)     // false
  ///     atLeastFive.contains(5.0)     // true
  ///     atLeastFive.contains(6.0)     // true
  ///
  /// You can use this type of partial range of a collection's indices to
  /// represent the range from the partial range's lower bound up to the end
  /// of the collection.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     print(numbers[3...])
  ///     // Prints "[40, 50, 60, 70]"
  ///
  /// - Parameter minimum: The lower bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static postfix func ... (minimum: Self) -> PartialRangeFrom<Self> {
    return PartialRangeFrom(minimum)
  }
}

// FIXME: replace this with a computed var named `...` when the language makes
// that possible.
@_fixed_layout // FIXME(sil-serialize-all)
public enum UnboundedRange_ {
  @_inlineable // FIXME(sil-serialize-all)
  public static postfix func ... (_: UnboundedRange_) -> () {
    fatalError("uncallable")
  }
}
public typealias UnboundedRange = (UnboundedRange_)->()

extension Collection {
  @_inlineable
  public subscript<R: RangeExpression>(r: R)
  -> SubSequence where R.Bound == Index {
    return self[r.relative(to: self)]
  }
  
  @_inlineable
  public subscript(x: UnboundedRange) -> SubSequence {
    return self[startIndex...]
  }
}
extension MutableCollection {
  @_inlineable
  public subscript<R: RangeExpression>(r: R) -> SubSequence
  where R.Bound == Index {
    get {
      return self[r.relative(to: self)]
    }
    set {
      self[r.relative(to: self)] = newValue
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  public subscript(x: UnboundedRange) -> SubSequence {
    get {
      return self[startIndex...]
    }
    set {
      self[startIndex...] = newValue
    }
  }
}

// TODO: enhance RangeExpression to make this generic and available on
// any expression.
extension Range {
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: Range = 0..<20
  ///     print(x.overlaps(10...1000))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable
  public func overlaps(_ other: Range<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(self.lowerBound))
  }

  @_inlineable
  public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
    return self.contains(other.lowerBound)
        || (!self.isEmpty && other.contains(self.lowerBound))
  }
}

@available(*, deprecated, renamed: "Range")
public typealias CountableRange<Bound: Comparable> = Range<Bound>

