import Foundation
import CJSONC

/**
 * This protocol, and the following extension, allows the ability to accurately
 * determine if a value typed as Any is a Dictionary of any type.
 */
protocol JSONDictionary {
  func asAny() -> [String: Any]
}

/**
 * Provides type checking ability and value normalization
 */
extension Dictionary: JSONDictionary {

  /**
   * Given some Dictionary<String, _>, functionally casts it to a
   * Dictionary<String, Any>. This was more of an issue than I thought it
   * would be
   */
  func asAny() -> [String: Any] {
    var result: [String: Any] = [String: Any]()

    for (k, v) in self {
      guard let key = k as? String else { continue }
      result[key] = v
    }

    return result
  }
}

/**
 * This protocol, and the following extension, allows the ability to accurately
 * determine if a value typed as Any is an Array any type.
 */
protocol JSONArray {
  func asAny() -> [Any]
}

/**
 * Provides type checking ability and value normalization
 */
extension Array: JSONArray {

  /**
   * Given an Array<_>, functionally casts it to an Array<Any>. This may not
   * have been as necessary as the Dictionary equivelant.
   */
  func asAny() -> [Any] {
    return self.map() { $0 as Any }
  }
}

/**
 * A simple JSON parser and builder to be used until NSJSONSerializer is added
 * to the linux port of Foundation
 */
public class JSON {

  /**
   * Possible error types that can be thrown when attempting to build a json
   * representation of a data structure
   */
  public enum JSONError: ErrorType {
    // A value specified was not of the proper type to be converted to json
    case InvalidType
  }

  /**
   * Given a json string, returns a data structure constructed with swift
   * primative types.
   */
  public static func parse(json: String) throws -> Any? {
    let parser = JSONParser(json: json)

    return try parser.parse()
  }

  /**
   * Given a data structure comprised of swift primatives (Bool, Int, String,
   * Array, Dictionary), returns a json formatted string representation
   */
  public static func format(any: Any) throws -> String {
    if let asDict = any as? JSONDictionary {
      return try self.format(asDict.asAny())
    }

    return ""
  }

  // MARK: Private Methods

  /**
   * Given a swift array, construct a string representation and return it
   */
  private static func format(array: [Any]) throws -> String {
    var result = "", index = 0

    for value in array {
      try result += self.handleValue(value)

      if index < array.count - 1 {
        result += ","
      }

      index += 1
    }

    return "[\(result)]"
  }

  /**
   * Given a swift dictionary, construct a string representation and return it
   */
  private static func format(dictionary: [String: Any]) throws -> String {
    var result = "", index = 0

    for (key, value) in dictionary {
      try result += "\"\(key)\": \(self.handleValue(value))"

      if index < dictionary.values.count - 1 {
        result += ","
      }

      index += 1
    }

    return "{\(result)}"
  }

  /**
   * Handles the conversion of json values into strings, routing to helper
   * methods for more complex types like Array and Dictionary
   */
  private static func handleValue(value: Any) throws -> String {
    if let asBool = value as? Bool {
      return "\(asBool)"
    } else if let asInt = value as? Int {
      return "\(asInt)"
    } else if let asFloat = value as? Float {
      return "\(asFloat)"
    } else if let asString = value as? String {
      return "\"\(asString)\""
    } else if value is JSONDictionary {
      if let dict = value as? JSONDictionary {
        return try "\(JSON.format(dict.asAny()))"
      }
    } else if value is JSONArray {
      if let array = value as? JSONArray {
        return try "\(JSON.format(array.asAny()))"
      }
    } else if let _ = value as? NSNull {
      return "null"
    } else {
      print("Unsupported type in JSON conversion: \(value) -- Type: \(value.dynamicType)")
      throw JSONError.InvalidType
    }

    return ""
  }

}

private class JSONParser {

  enum JSONParserState {
    case Object, Array, String, Int, Float, Bool
  }

  enum JSONParserError: ErrorType {
    case InvalidSyntax
  }

  let json: String

  init(json: String) {
    self.json = json
  }

  func parse() throws -> Any {
    let json = self.json.trim()

    if json[0] == "{" {
      let (result, _) = try JSONParser.parseObject(json)
      return result
    } else if json[0] == "[" {
      return try JSONParser.parseArray(json)
    } else {
      print("Top level error [\(json[0])]")
      throw JSONParserError.InvalidSyntax
    }
  }

  static func iterate(json: String, startIndex: Int = 0, handler: (Character) -> Bool) -> Int {
    var index = startIndex, start = json.startIndex.advancedBy(startIndex), length = json.endIndex

    for char in json.characters[start ..< length] {
      if !handler(char) {
        break
      }

      index += 1
    }

    return index
  }

  static func skipWhitespace(json: String, startIndex: Int = 0) -> Int {
    return JSONParser.iterate(json, startIndex: startIndex) { (char) -> Bool in
      return char.isWhitespace()
    }
  }

  static func getKey(json: String, startIndex: Int = 0) throws -> (String, Int) {
    if json[startIndex] != "\"" {
      print("Key issue: \(startIndex) [\(json[(startIndex - 1) ... (startIndex + 1)])] \(json)")
      throw JSONParserError.InvalidSyntax
    }

    var escaped = false

    let end = JSONParser.iterate(json, startIndex: startIndex + 1) { (char) -> Bool in
      if char == "\"" && !escaped {
        return false
      } else if char == "\\" && !escaped {
        escaped = true
      } else if char == "\\" {
        escaped = false
      }

      return true
    }

    return (json[(startIndex + 1) ..< end], end + 1)
  }

  static func getValue(json: String, startIndex: Int = 0) throws -> (Any, Int) {
    var char = json[startIndex], index = startIndex, result: Any = ""

    print("Getting value: \(startIndex) [\(json[(startIndex - 1) ... (startIndex + 1)])]")
    if char == "{" {
      print("-- OBJECT")
      (result, index) = try JSONParser.parseObject(json, startIndex: startIndex)
    } else if char == "[" {
      print("-- ARRAY")
      (result, index) = try JSONParser.parseArray(json, startIndex: startIndex)
    } else if char == "\"" {
      var escaped = false

      repeat {
        escaped = char == "\\"

        index += 1
        char = json[index]
      } while char != "\"" || escaped

      result = json[startIndex + 1 ..< index]
      index += 1
    } else {
      var decimal = false

      while char != "," && char != "]" && char != "}" {
        index += 1
        char = json[index]

        decimal = decimal || char == "."
      }

      let value = json[startIndex ..< index]

      if value == "true" {
        result = true
      } else if value == "false" {
        result = false
      } else if decimal {
        guard let float = Float(value) else { throw JSONParserError.InvalidSyntax }
        result = float
      } else {
        guard let int = Int(value) else { throw JSONParserError.InvalidSyntax }
        result = int
      }
    }

    return (result, index)
  }

  static func parseObject(json: String, startIndex: Int = 0) throws -> (Any, Int) {
    var index = JSONParser.skipWhitespace(json, startIndex: startIndex + 1)
    var result = [String: Any](), char = json[index]

    while char != "}" {
      while json[index].isWhitespace() {
        index += 1
      }

      if json[index] == "}" {
        break
      }

      var (key, keyEnd) = try JSONParser.getKey(json, startIndex: index)

      while json[keyEnd].isWhitespace() || json[keyEnd] == ":" {
        keyEnd += 1
      }

      let (value, valueEnd) = try JSONParser.getValue(json, startIndex: keyEnd)

      char = json[valueEnd]
      index = valueEnd + 1

      print("[\(key)]: [\(value)] (\(char))")
      result[key] = value
    }

    return (result, index)
  }

  static func parseArray(json: String, startIndex: Int = 0) throws -> (Any, Int) {
    var index = JSONParser.skipWhitespace(json, startIndex: startIndex + 1)
    var result = [Any](), char = json[index]

    while char != "]" {
      while json[index].isWhitespace() {
        index += 1
      }

      if json[index] == "]" {
        break
      }

      let (value, valueEnd) = try JSONParser.getValue(json, startIndex: index)

      char = json[valueEnd]
      index = valueEnd + 1
      print(" \(result.count): \(value) (\(char))")
      result.append(value)
    }

    return (result, index)
  }
}
