import Foundation

#if DEBUG

public var MOCK_DATE = false
private var current_date: TimeInterval = 0

extension Date {
    static var current: Date {
        if MOCK_DATE {
            current_date += 1
            return Date(timeIntervalSince1970: current_date)
        } else {
            return Date()
        }
    }
}

#else

extension Date {
    static var current: Date {
        return Date()
    }
}

#endif
