import Foundation

public class HTTPResponse {

  private let statusMap: Dictionary<Int, String> = [
    100: "Continue",
    101: "Switching Protocols",
    200: "OK",
    201: "Created",
    202: "Accepted",
    203: "Non-Authoritative Information",
    204: "No Content",
    205: "Reset Content",
    206: "Partial Content",
    300: "Multiple Choices",
    301: "Moved Permanently",
    302: "Found",
    303: "See Other",
    304: "Not Modified",
    305: "Use Proxy",
    307: "Temporary Redirect",
    400: "Bad Request",
    401: "Unauthorized",
    402: "Payment Required",
    403: "Forbidden",
    404: "Not Found",
    405: "Method Not Allowed",
    406: "Not Acceptable",
    407: "Proxy Authentication Required",
    408: "Request Time-out",
    409: "Conflict",
    410: "Gone",
    411: "Length Required",
    412: "Precondition Failed",
    413: "Request Entity Too Large",
    414: "Request-URI Too Large",
    415: "Unsupported Media Type",
    416: "Requested range not satisfiable",
    417: "Expectation Failed",
    500: "Internal Server Error",
    501: "Not Implemented",
    502: "Bad Gateway",
    503: "Service Unavailable",
    504: "Gateway Time-out",
    505: "HTTP Version not supported"
  ]

  public var status: Int = 200
  public var body: String = ""
  public var contentType: String = "text/html"
  public var additionalHeaders = [String: String]()

  private var statusMessage: String {
    get {
      guard let message = self.statusMap[self.status] else { return "Custom" }

      return message
    }
  }

  public init() {}

  public var string: String {
    get {
      var str = "HTTP/1.1 \(self.status) \(self.statusMessage)\n"
      str += "Content-Type: \(self.contentType)\n"
      str += "Content-Length: \(self.body.characters.count)\n"

      for (key, value) in self.additionalHeaders {
        str += "\(key): \(value)\n"
      }

      str += "\n"
      str += self.body

      return str
    }
  }
}
