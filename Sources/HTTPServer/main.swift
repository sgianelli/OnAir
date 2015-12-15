import Glibc
import Foundation
import CJSONC
import Utils

let router = HTTPRouter()

var d: [String: [String: Any]] = ["key1": ["id": 123,"enabled": true,"disabled": false,"friends": [1,2,3,4]]]

try print(JSON.format(d))

var s = "{\"test\": 2, \"test2\": false, \"test3\": true, \"test4\": 1.34, \"key1\": {\"id\": 123,\"enabled\": true,\"disabled\": false,\"friends\": [1,2,3,4]}}"

try JSON.parse(s)

func sample(request: HTTPRequest, params: [String: String]) -> HTTPResponse {
  let response = HTTPResponse()

  do {
    try response.body = JSON.format(params)
  } catch {
    print(error)
  }

  return response
}

router.get("/", handler: sample)
router.get("/sample", handler: sample)
router.get("/schools/:id/classes", handler: sample)
router.get("/schools/:id/:score/classes/:disco", handler: sample)

let server = HTTPServer(port: 8080, router: router)

server.start()

