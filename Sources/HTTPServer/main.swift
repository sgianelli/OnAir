import Glibc
import Foundation
import CJSONC
import Utils

let router = HTTPRouter()

func sample(request: HTTPRequest, params: [String: String]) -> HTTPResponse {
  let response = HTTPResponse()

  if let json = request.bodyAsJson, body = try? JSON.format(json) {
    response.body = body
  }

  return response
}

router.get("/", handler: sample)
router.get("/sample", handler: sample)
router.get("/schools/:id/classes", handler: sample)
router.get("/schools/:id/:score/classes/:disco", handler: sample)

let server = HTTPServer(port: 8080, router: router)

server.start()

