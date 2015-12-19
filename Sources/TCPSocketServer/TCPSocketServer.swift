import Glibc
import Utils

/**
 * This class encapsulates the C API for socket communication that allows us to
 * open a TCP port on listening for arbitrary external communications. When
 * run, it provides a callback that is called every time data is passed to the
 * socket so that other parsers can be placed on top to interpret messages and
 * provide responses.
 */
public class TCPSocketServer {

  /**
   * Encapsulates the C struct sockaddr_in and handles the casting to struct
   * sockaddr when necessary. struct casting in swift isn't pretty.
   */
  private class SocketAddressIn {
    private var saddress = UnsafeMutablePointer<sockaddr_in>.alloc(1)

    /**
     * Exposes the pointer to the internal sockaddr_in
     */
    var pointer: UnsafeMutablePointer<sockaddr_in> {
      get {
        return self.saddress
      }
    }

    /**
     * Returns a casting of sockaddr_in to sockaddr
     */
    var socketAddressPointer: UnsafeMutablePointer<sockaddr> {
      get {
        return withUnsafeMutablePointer(&self.saddress) {
          UnsafeMutablePointer($0.memory)
        }
      }
    }

    /**
     * Constructs and initializes a SocketAddressIn with a port, host address,
     * and family configuration in the same format as sockaddr_in.
     */
    init(port: UInt16, host: in_addr_t, family: UInt16) {
      self.saddress.memory.sin_family = family
      self.saddress.memory.sin_port = htons(port)
      self.saddress.memory.sin_addr.s_addr = host
    }

    deinit {
      self.saddress.dealloc(1)
    }
  }

  /**
   * Socket provides an interface to the actual lifecycle of creating,
   * receiving, and sending over a TCP socket and encapsulates all data as
   * instances of Data.
   */
  private class Socket {
    // MARK: Constants

    /**
     * Maximum amount of data to receive from the client at a time
     */
    static let ReceiveSize: Int = 65535

    // MARK: Private Variables

    /**
     * File descriptor of the listening socket
     */
    private let serverfd: Int32

    /**
     * Socket address description that defines what to listen for
     */
    private let saddress_in: SocketAddressIn

    /**
      * Callback called when a client connects to the server
      */
    var onConnect: ((Int) -> Void)?

    /**
      * Callback called when a client disconnect from the server
      */
    var onClose: ((Int) -> Void)?

    /**
     * Constructs and initializes a Socket object with the necessary parameters
     * to construct a listening TCP socket in the same format as expect by the
     * C socket() API as well as a SocketAddressIn descriptor.
     */
    init(domain: Int32, type: Int32, proto: Int32, socketAddressIn: SocketAddressIn) {
      self.serverfd = socket(domain, type, proto)
      self.saddress_in = socketAddressIn
    }

    /**
     * Starts the server with a callback that will receive all the data once it
     * has been received by the server.
     */
    func start(dataHandler: (Int, Data) -> Data) {
      let bindStatus = bind(self.serverfd, &self.saddress_in.socketAddressPointer.memory, socklen_t(sizeof(sockaddr)))

      if bindStatus < 0 {
        return
      }

      let listenStatus = listen(self.serverfd, 20);

      if listenStatus < 0 {
        return
      }

      while true {
        let clientAddr: UnsafeMutablePointer<sockaddr> = UnsafeMutablePointer<sockaddr>()
        var len = socklen_t(sizeof(sockaddr_in))

        let clientfd: Int32 = accept(self.serverfd, &clientAddr.memory, &len)

        self.handleConversation(clientfd, dataHandler: dataHandler)
      }
    }

    /**
     * When a client connects, this method takes control of handeling
     * bidirectional communication with the client using the dataHandler
     * callback to process and construct messages. Some day this may be on its
     * own thread for each client.
     */
    private func handleConversation(clientfd: Int32, dataHandler: (Int, Data) -> Data) {
      var pieceSize: Int = 0, buffer: [UInt8]

      if let onConnect = self.onConnect {
        onConnect(Int(clientfd))
      }

      repeat {
        buffer = [UInt8](count: Socket.ReceiveSize, repeatedValue: 0)
        pieceSize = recv(clientfd, &buffer, Socket.ReceiveSize, 0)

        if pieceSize > 0 {
          let trimmed: [UInt8] = [UInt8](buffer[0..<pieceSize])

          let response = dataHandler(Int(clientfd), Data(data: trimmed))

          send(clientfd, response.buffer, response.bufferLength, 0)
        }
      } while pieceSize > 0

      if let onClose = self.onClose {
        onClose(Int(clientfd))
      }

      close(clientfd)
    }
  }

  // MARK: Private Methods

  private var running: Bool = false

  /**
   * The port the server will listen on
   */
  private let port: UInt16

  /**
   * Constructs a new TCPSocketServer and specifies a port to listen on
   */
  public init(port: UInt16 = 8000) {
    self.port = port
  }

  // MARK: Public Variables

  /**
    * Callback called when a client connects to the server
    */
  public var onConnect: ((Int) -> Void)?

  /**
    * Callback called when a client disconnect from the server
    */
  public var onClose: ((Int) -> Void)?

  // MARK: Server State

  /**
   * Unimplemented
   *
   * Returns the state of the server being run in the background
   */
  public func isRunning() -> Bool {
    return self.running;
  }

  /**
   * Sets up the TCP socket to start listening for requests on the specified
   * interface.
   */
  public func start(dataHandler: (Int, Data) -> Data) {
    let sockAddr = SocketAddressIn(port: self.port, host: 0, family: UInt16(AF_INET))
    let socket = Socket(domain: AF_INET, type: Int32(SOCK_STREAM.rawValue), proto: 0, socketAddressIn: sockAddr)
    socket.onConnect = self.onConnect
    socket.onClose = self.onClose

    socket.start(dataHandler)
  }

  /**
   * Unimplemented
   *
   * Stops the server when being run on a separate thread.
   */
  public func stop() {

  }
}


