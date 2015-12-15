import Glibc

/**
 * This is just a swiftier way of managing an arbitrary byte array of data and
 * allowing for mutation of that data set.
 */
public class Data: SequenceType {
  public var raw: [UInt8] = [UInt8]()

  // MARK: Initialization

  /**
   * Creates and initializes an empty Data object
   */
  public init() {

  }

  /**
   * Creates and initializes a Data object with an initial set of data
   */
  public init(data: [UInt8]) {
    self.raw.appendContentsOf(data)
  }

  /**
   * Creates and initializes a Data object with the value of a string. The
   * string is just copied over as a CString into memory.
   */
  public init(string: String) {
    // Grab pointer to CString
    string.withCString() { (raw) -> Void in
      var cstring = raw

      // Traverse to null byte
      while cstring.memory != 0 {
        self.raw.append(UInt8(cstring.memory))
        cstring = cstring.advancedBy(1)
      }
    }
  }

  // MARK: Enumerable

  /**
   * Currently we just expose the iterator for the internal data store
   */
  public func generate() -> IndexingGenerator<[UInt8]> {
    return self.raw.generate()
  }

  // MARK: Getters

  /**
   * Convenience method for accessing the internal data as byte array. Used
   * for passing data through C functions that require a byte array.
   */
  public var buffer: [UInt8] {
    get {
      return self.raw
    }
  }

  /**
   * Convenience method for accessing size of returned buffer object. Currently
   * this doesn't offer much but if/when Data's underlying structure changes
   * this may become more useful.
   */
  public var bufferLength: size_t {
    get {
      return size_t(self.raw.count)
    }
  }

  // MARK: Public Methods

  /**
   * Appends a block of data.
   */
  public func append(data: [UInt8]) {
    self.raw.appendContentsOf(data)
  }

  /**
   * Appends a byte of data.
   */
  public func append(data: UInt8) {
    self.raw.append(data)
  }

  public func stringValue() -> String? {
    return String.fromCString(UnsafePointer<Int8>(self.raw.withUnsafeBufferPointer({ $0.baseAddress })))
  }

  // MARK: Debugging

  public func description() -> String {
    var description = ""
    var text = ""

    for i in 0..<self.raw.count {
      description += String(self.raw[i], radix: 16, uppercase: false) + " "//"\(UnicodeScalar(self.raw[i]))"
      text += "\(UnicodeScalar(self.raw[i]))"
    }

    return "\n\(description)\n\n\(text)\nData Length: \(self.raw.count)"
  }
}
