import Glibc
import TCPSocketServer
import Utils

public class HTTPServer {
  // MARK: Public Properties

  let port: UInt16
  let router: HTTPRouter

  // MARK: Private Properties

  private var socket: TCPSocketServer?

  // MARK: Initialization

  init(port: UInt16, router: HTTPRouter) {
    self.port = port
    self.router = router

  }

  // MARK: Public Methods

  func start() {
    let socket = TCPSocketServer(port: self.port)

    socket.start() { (data) -> Data in
      print("\(data.description())")
      let request = HTTPRequest(data: data)
      let response = self.router.handle(request)

      return Data(string: response.string)
    }
  }

  // MARK: Private Methods
}
