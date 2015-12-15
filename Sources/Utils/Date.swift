import Foundation
import Glibc

public class DateHelper {

  public static func stringFromNow(format format: String) -> String? {
    let buffer = UnsafeMutablePointer<Int8>.alloc(26)
    var tv = timeval()

    setenv("TZ", "GMT0", 1)
    tzset()
    gettimeofday(&tv, UnsafeMutablePointer<timezone>(nil))
    strftime(buffer, 26, format, gmtime(&tv.tv_sec))

    return String.fromCString(buffer)
  }

  public static func rfc1123StringNow() -> String {
    let format = "%a, %d %b %Y %H:%M"

    return DateHelper.stringFromNow(format: format)! + " GMT"
  }
}
