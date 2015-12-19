import Utils

/**
 * A representation of the request received by the server with headers and body
 * parsed out, including some convenient methods for parsing the body data into
 * JSON, String, or raw data
 */
public class HTTPRequest {

  /**
   * Structure representing the w3c defined HTTP protocol headers and status
   * information
   */
  public struct HTTPRequestHeader {
    // HTTP Method: GET, POST, PUT, DELETE
    public let method: String

    // Requested HTTP route
    public let path: String

    // HTTP version used in request
    public let version: String

    // HTTP header field hash map
    public var fields: [String: String]
  }

  /**
   * Parses the Data object passed into the initializer into a header and body
   * Data object in one linear pass. This parses the HTTP method, requested
   * path, HTTP version, HTTP headers (without parsing each attribute just
   * yet), and the remaining body data.
   */
  private static func parse(data: Data) throws -> (HTTPRequestHeader, String) {

    /**
     * Given a string, scan until the next whitespace and return the string up
     * to that point
     */
    func parseToSpace(content: String, startIndex: Int) -> (String, Int) {
      var index = startIndex

      while !content[index].isWhitespace() { index += 1 }

      return (content[startIndex ..< index], index)
    }

    /**
     * Given a string, scan until the next newline character and return the
     * string up to that point
     */
    func parseToNewline(content: String, startIndex: Int) -> (String, Int) {
      var index = startIndex

      while !content[index].isNewline() { index += 1 }

      return (content[startIndex ..< index], index)
    }

    /**
     * Returns the parsed status line of the reeived HTTP reader. The HTTP
     * status line takes the form:
     *
     * [GET|POST|PUT|DELETE] (/path/requested/from/server) HTTP/(version)
     */
    func parseStatusLine(content: String) -> (String, String, String, Int) {
      var index = 0, info = [String](), char = content[0]

      while !char.isNewline() {
        let (prop, end) = parseToSpace(content, startIndex: index)

        info.append(prop)

        char = content[end]
        index = end + 1
      }

      return (info[0], info[1], info[2], index + 1)
    }

    /**
     * Simple check for the end of the HTTP header which is denoted with a
     * double-newline, after which the body of the request starts
     */
    func isDoubleNewline(content: String, startIndex: Int) -> Bool {
      if content.length < startIndex + 1 {
        return false
      }

      let data = Data(string: content[startIndex ... startIndex + 1])

      if data.raw.count == 4 {
        return data[0] == 0x0d && data[1] == 0x0a && data[2] == 0x0d && data[3] == 0x0a
      }

      return false
    }

    /**
     * Splits a line of the HTTP header fields into a key and value as denoted
     * by a colon (:) and returns the tuple. This does none of the key-specific
     * parsing (e.g. User-Agent)
     */
    func parseHeaderFields(content: String, startIndex: Int) -> ([String: String], Int) {
      var index = startIndex - 1, result = [String: String]()

      // Keep parsing until the end of the HTTP header
      while !isDoubleNewline(content, startIndex: index) {
        index += 1

        let (key, keyEnd) = parseToSpace(content, startIndex: index)

        index = keyEnd + 1

        let (value, valueEnd) = parseToNewline(content, startIndex: index)

        index = valueEnd

        result[key[0 ..< key.length - 1]] = value
      }

      return (result, index + 2)
    }

    // Convert data to a string
    guard let content = data.stringValue() else { throw HTTPError.IncompleteRequestData }

    // Keep track of the current seek position in the content
    var index = 0

    // Parse status line
    let (method, path, version, statusEnd) = parseStatusLine(content)

    index = statusEnd + 1

    // Parse header fields
    let (fields, fieldsEnd) = parseHeaderFields(content, startIndex: index)

    // Coerce valuse into a meaningful data structure
    let header = HTTPRequestHeader(method: method, path: path, version: version, fields: fields)
    // Extract the rest of the content as the body of the request
    let body = (fieldsEnd >= content.length ? "" : content[fieldsEnd ..< content.length])

    return (header, body)
  }

  // The raw body of the HTTP request
  public let body: String

  // The parsed header data of the HTTP request
  public let header: HTTPRequestHeader

  // Convenience method for converting the body to a raw data object
  private var _bodyAsData: Data?
  public var bodyAsData: Data? {
    get {
      if self._bodyAsData == nil {
        self._bodyAsData = Data(string: self.body)
      }

      return self._bodyAsData
    }
  }

  // Convenience method for parsing the body as a JSON object
  private var _bodyAsJson: Any?
  public var bodyAsJson: Any? {
    get {
      if self._bodyAsJson == nil {

        do {
          try self._bodyAsJson = JSON.parse(self.body)
        } catch {
          print(error)
        }
      }

      return self._bodyAsJson
    }
  }

  // Default constructor for creating an HTTPRequest with a raw data object
  public init(data: Data) throws {
    try (self.header, self.body) = HTTPRequest.parse(data)
  }

  // Constructs an HTTPRequest by copying one and setting a body
  public init(request: HTTPRequest, body: String) {
    self.header = request.header
    self.body = body
  }
}


