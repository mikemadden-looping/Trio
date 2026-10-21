import Foundation

struct GlucoseAlertConfiguration: Codable, Equatable {
    var dayStart: TimeOfDay
    var nightStart: TimeOfDay
    /// Force Trio alarms on even when the CGM advertises its own.
    var forceTrioAlertsWhenCGMProvidesOwn: Bool
    /// Minutes without a loop before the first Not Looping warning, during the
    /// Day window. Earlier warning steps are skipped; later ones still fire.
    var notLoopingFirstWarningDayMinutes: Int
    /// Same, for the Night window.
    var notLoopingFirstWarningNightMinutes: Int

    /// Choices offered for the first Not Looping warning. These match the
    /// warning steps in `NotLoopingMonitor`; the Critical alarm at 120 minutes
    /// is not affected by either setting.
    static let notLoopingFirstWarningChoices: [Int] = [20, 40, 60, 80, 100]
    static let defaultNotLoopingFirstWarningMinutes = 20

    init(
        dayStart: TimeOfDay = TimeOfDay(hour: 6, minute: 0),
        nightStart: TimeOfDay = TimeOfDay(hour: 22, minute: 0),
        forceTrioAlertsWhenCGMProvidesOwn: Bool = false,
        notLoopingFirstWarningDayMinutes: Int = GlucoseAlertConfiguration.defaultNotLoopingFirstWarningMinutes,
        notLoopingFirstWarningNightMinutes: Int = GlucoseAlertConfiguration.defaultNotLoopingFirstWarningMinutes
    ) {
        self.dayStart = dayStart
        self.nightStart = nightStart
        self.forceTrioAlertsWhenCGMProvidesOwn = forceTrioAlertsWhenCGMProvidesOwn
        self.notLoopingFirstWarningDayMinutes = notLoopingFirstWarningDayMinutes
        self.notLoopingFirstWarningNightMinutes = notLoopingFirstWarningNightMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case dayStart
        case nightStart
        case forceTrioAlertsWhenCGMProvidesOwn
        case notLoopingFirstWarningDayMinutes
        case notLoopingFirstWarningNightMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dayStart = try container.decode(TimeOfDay.self, forKey: .dayStart)
        nightStart = try container.decode(TimeOfDay.self, forKey: .nightStart)
        forceTrioAlertsWhenCGMProvidesOwn = try container.decodeIfPresent(
            Bool.self,
            forKey: .forceTrioAlertsWhenCGMProvidesOwn
        ) ?? false
        notLoopingFirstWarningDayMinutes = try container.decodeIfPresent(
            Int.self,
            forKey: .notLoopingFirstWarningDayMinutes
        ) ?? Self.defaultNotLoopingFirstWarningMinutes
        notLoopingFirstWarningNightMinutes = try container.decodeIfPresent(
            Int.self,
            forKey: .notLoopingFirstWarningNightMinutes
        ) ?? Self.defaultNotLoopingFirstWarningMinutes
    }

    /// First Not Looping warning threshold that applies at `date`.
    func notLoopingFirstWarningMinutes(at date: Date, calendar: Calendar = .current) -> Int {
        isNight(at: date, calendar: calendar)
            ? notLoopingFirstWarningNightMinutes
            : notLoopingFirstWarningDayMinutes
    }

    /// Resolve whether `date` falls into the user's "night" window. Mirrors
    /// LoopFollow's logic: handles both same-day (06→22) and wrap-around
    /// (22→06) ranges. When `nightStart >= dayStart`, night is "later than
    /// nightStart OR earlier than dayStart"; otherwise night is the slice
    /// between nightStart and dayStart.
    func isNight(at date: Date, calendar: Calendar = .current) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        guard
            let dayStartDate = calendar.date(
                bySettingHour: dayStart.hour,
                minute: dayStart.minute,
                second: 0,
                of: startOfDay
            ),
            let nightStartDate = calendar.date(
                bySettingHour: nightStart.hour,
                minute: nightStart.minute,
                second: 0,
                of: startOfDay
            )
        else { return false }

        if nightStartDate >= dayStartDate {
            return date >= nightStartDate || date < dayStartDate
        } else {
            return date >= nightStartDate && date < dayStartDate
        }
    }
}
