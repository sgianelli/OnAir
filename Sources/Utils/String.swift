import Glibc

extension String {

  // MARK: Subscripting

  public subscript(index: Int) -> Character {
    return self[self.startIndex.advancedBy(index)]
  }

  public subscript(range: Range<Int>) -> String {
    return String(self.characters[Range<String.Index>(start: startIndex.advancedBy(range.startIndex), end: startIndex.advancedBy(range.endIndex))])
  }

  /**
   * Conveniencer for getting String length
   */
  public var length: Int {
    get {
      return self.characters.count
    }
  }

  /**
   * Returns a CString representation of String because I don't like always
   * having to use .withCString() { $0 }
   */
  public func cstring() -> UnsafePointer<Int8> {
    return self.withCString() { $0 }
  }

  public func trim() -> String {
    var frontIndex: Int = 0, backIndex: Int = self.length - 1

    while self[frontIndex].isWhitespace() {
      frontIndex += 1
    }

    while self[backIndex].isWhitespace() {
      backIndex -= 1
    }

    return self[frontIndex ... backIndex]
  }
}

public extension Character {
  public func isWhitespace() -> Bool {
    return self == " " || self == "\t" || self == "\r" || self.isNewline()
  }

  public func isNewline() -> Bool {
    return String(self) == "\n" || String(self) == "\r\n"
  }
}
