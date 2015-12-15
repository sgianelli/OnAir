import Utils

public class HTTPRequest {
  public struct HTTPRequestHeader {
    public let method: String
    public let path: String
    public let version: String
    public let properties: Dictionary<String, String>

    public func description() -> String {
      return "\(self.version) [\(self.method)]: \(self.path)\n\(self.properties)"
    }
  }

  /**
   * Parses the Data object passed into the initializer into a header and body
   * Data object in one linear pass. This parses the HTTP method, requested
   * path, HTTP version, HTTP headers (without parsing each attribute just
   * yet), and the remaining body data.
   */
  private static func parse(data: Data) -> (HTTPRequestHeader, Data) {
    /**
     * httpInfo keeps track of the pieces of the first header line which
     * usually takes the form:
     * [POST|GET|...] /this/is/a/route HTTP/1.1
     *
     * httpIndex keeps track of what component we are currently on in that line
     */
    var httpInfo: [String] = ["", "", ""], httpIndex: Int = 0

    // The processed HTTP header key values
    var properties = Dictionary<String, String>()

    // Temp variables to keep track of current strings and whether or not we
    // are currently parsing a header key
    var temp: String = "", key: String = "", isKey: Bool = true

    // State of parser -- whether or not we are parsing the info line
    var keyValueStep: Bool = false

    // Body data object
    let body: Data = Data()

    // The current position of the data being inspected
    var index = 0

    while index < data.raw.count {
      // Current byte being inspected
      var char: UInt8 = data.raw[index]

      // Advance to next byte
      index += 1

      // Check to see if we are at the end of the HTTP header which will be
      // defined as a double new line -- 0xdada
      if index < data.raw.count - 3 {
        if char == 0x0d &&
          data.raw[index] == 0x0a &&
          data.raw[index + 1] == 0x0d &&
          data.raw[index + 2] == 0x0a {

          // The header has ended, append the remaining data to the body and
          // break from the loop
          body.append([UInt8](data.raw[(index + 3) ..< data.raw.count]))

          break
        }
      }

      // Processing information line
      if !keyValueStep {
        // Check for whitespace and skip over it
        if char == 0x0a || char == 0x0d || char == 0x20 {
          // If we have read something into temp before hitting whitespace,
          // it means that term has ended and we should get ready to start the
          // next one
          if temp.characters.count > 0 {
            // Check to see if we are at the end of the info line
            keyValueStep = char == 0x0a || char == 0xd

            // Store info value
            httpInfo[httpIndex] = temp
            temp = ""
            httpIndex += 1
          }

          continue
        }

        // Append byte to temporary storage
        temp += String(UnicodeScalar(char))
      } else {
        // Skip over whitespace until we hit a valid character
        if temp.characters.count == 0 && (char == 0x20 || char == 0x0a || char == 0x0d) {
          continue
        }

        if isKey {
          // Read key into memory until we hit a colon (:)
          while char != 0x3a {
            temp += String(UnicodeScalar(char))

            char = data.raw[index]

            index += 1
          }

          isKey = false
          key = temp
          temp = ""

          continue
        } else {
          while !(char == 0x0a || char == 0x0d) {
            temp += String(UnicodeScalar(char))

            char = data.raw[index]

            if char == 0x0a || char == 0x0d {
              break
            }

            index += 1
          }

          properties[key] = temp
          key = ""
          temp = ""
          isKey = true

          continue
        }
      }
    }

    let header: HTTPRequestHeader = HTTPRequestHeader(method: httpInfo[0],
                                                      path: httpInfo[1],
                                                      version: httpInfo[2],
                                                      properties: properties)
    return (header, body)
  }

  public let bodyData: Data
  public let header: HTTPRequestHeader

  public init(data: Data) {
    (self.header, self.bodyData) = HTTPRequest.parse(data)
  }

  // MARK: Private Methods
}


