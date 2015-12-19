import Glibc
import TCPSocketServer
import Utils

/**
 * An interface for constructing and running and HTTP complient server that
 * handles routing of requests to the appropriate handlers
 */
public class HTTPServer {
  // MARK: Public Properties

  // The port the HTTP server is listening on
  public let port: UInt16

  // The user-defined router object which handles response building when the
  // server receives a request
  public let router: HTTPRouter

  // MARK: Private Properties

  // The TCP socket the HTTP server is using to listen and talk on
  private var socket: TCPSocketServer?

  // Tracks open requests to handle multiple connected peers
  private var openRequests: [Int: HTTPRequest] = [:]

  // MARK: Initialization

  /**
   * Default HTTPServer constructor
   */
  public init(port: UInt16, router: HTTPRouter) {
    self.port = port
    self.router = router
  }

  // MARK: Public Methods

  /**
   * Starts the HTTP server synchronously on the current thread
   */
  public func start() {
    let socket = TCPSocketServer(port: self.port)
    var activeRequest: HTTPRequest?

    socket.onClose = { (clientId) -> Void in
      print("Client closed \(clientId)")
    }

    socket.onConnect = { (clientId) -> Void in
      print("Client connected \(clientId)")
    }

    socket.start() { (clientId, data) -> Data in
      do {
        if let currentRequest = activeRequest, body = data.stringValue() {
          let request = HTTPRequest(request: currentRequest, body: body)
          activeRequest = nil

          return Data(string: self.router.handle(request).string)
        } else {
          let request = try HTTPRequest(data: data)

          if let expect = request.header.fields["Expect"] {
            if expect == "100-continue" {
              activeRequest = request

              let response = HTTPResponse()
              response.status = 100

              return Data(string: response.string)
            }
          }

          return Data(string: self.router.handle(request).string)
        }
      } catch {
        print(error)
      }

      // TODO: Handle the case where the received request is invalid for some
      // reason or another -- should be handled in router
      return Data()
    }
  }
}
