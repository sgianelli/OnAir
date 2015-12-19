import Foundation
import Utils

/**
 * The format for handling route responses
 */
public typealias HTTPResponseHandler = (HTTPRequest, Dictionary<String, String>) -> HTTPResponse

/**
 * The HTTPRouter handles the routing of HTTPRequests received by the
 * HTTPServer and returns an HTTPResponse object to the server
 */
public class HTTPRouter {

  /**
   * An internal representation of a route that is used to more efficiently
   * match requested paths by matching against a decomposed version of the
   * user defined route
   */
  struct HTTPRoute {
    /**
     * The raw path defined by the user
     */
    let path: String

    /**
     * The callback function that is evaluated when a path matches the route
     */
    let handler: HTTPResponseHandler

    /**
     * Decomposed list of path components. Each component is guaranteed to be
     * at least one character long.
     */
    let pathComponents: [String]

    /**
     * Convenience method that digests a path string into its constituent
     * components in a way that is normally faster than executing a split()
     */
    static func splitPath(path: String) -> [String] {
      var collect: [String] = []
      var temp: String = ""

      for char in path.characters {
        if char == "/" {
          if temp != "" {
            collect.append(temp)
            temp = ""
          }
        } else {
          temp += String(char)
        }
      }

      if temp != "" {
        collect.append(temp)
      }

      return collect
    }

    static func matches(patternPiece: String, requestedPiece: String) -> Bool {
      if patternPiece.characters.first! == ":" {
        return true
      }

      return patternPiece == requestedPiece
    }
  }

  /**
   * Defines all supported HTTP methods as an enum
   */
  public enum HTTPMethod {
    case GET, POST, PUT, DELETE
  }

  /**
   * All defined routes for the server
   */
  var routes: [HTTPRoute] = []

  public init() {}

  public func handle(request: HTTPRequest) -> HTTPResponse {
    let requestedPath: [String] = HTTPRoute.splitPath(request.header.path)
    var matchedRoute: HTTPRoute?

    for route in self.routes {
      if route.pathComponents.count != requestedPath.count {
        continue
      }

      var matches = true

      for index in 0 ..< requestedPath.count {
        if !HTTPRoute.matches(route.pathComponents[index], requestedPiece: requestedPath[index]) {
          matches = false

          break
        }
      }

      if matches {
        matchedRoute = route

        break
      }
    }

    if let route = matchedRoute {
      var params = Dictionary<String, String>()

      for index in 0 ..< route.pathComponents.count {
        let matchedPiece: String = route.pathComponents[index]
        let requestedPiece: String = requestedPath[index]

        if matchedPiece.characters.first == ":" {
          params[matchedPiece[1 ..< matchedPiece.characters.count]] = requestedPiece
        }
      }

      return route.handler(request, params)
    }

    return HTTPResponse()
  }

  private func path(method: HTTPMethod, path: String, handler: HTTPResponseHandler) {
    let components = HTTPRoute.splitPath(path)

    self.routes.append(HTTPRoute(path: path, handler: handler, pathComponents: components))
  }

  public func get(path: String, handler: HTTPResponseHandler) {
    self.path(.GET, path: path, handler: handler)
  }

  public func post(path: String, handler: HTTPResponseHandler) {
    self.path(.POST, path: path, handler: handler)
  }

  public func put(path: String, handler: HTTPResponseHandler) {
    self.path(.PUT, path: path, handler: handler)
  }

  public func delete(path: String, handler: HTTPResponseHandler) {
    self.path(.DELETE, path: path, handler: handler)
  }

}
