import Foundation

extension Calendar {
    static func endOfDay(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components)!.addingTimeInterval(86399) // 23:59:59
    }
}
