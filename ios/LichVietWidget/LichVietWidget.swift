import WidgetKit
import SwiftUI

// MARK: - Shared data keys (must match widget_service.dart)
private let appGroupId = "group.com.example.mobile_base.lichviet"

struct LunarEntry: TimelineEntry {
    let date: Date
    let solarDay: String
    let weekday: String
    let lunarDay: String
    let lunarMonth: String
    let canChiDay: String
    let canChiYear: String
    let isAuspicious: Bool
    let holiday: String
}

// MARK: - Provider
struct LichVietProvider: TimelineProvider {
    func placeholder(in context: Context) -> LunarEntry {
        LunarEntry(date: Date(), solarDay: "4", weekday: "Fri",
                   lunarDay: "23", lunarMonth: "7",
                   canChiDay: "Quý Tỵ", canChiYear: "Bính Ngọ",
                   isAuspicious: true, holiday: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (LunarEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunarEntry>) -> Void) {
        // Refresh at midnight so the widget shows the correct day
        let e = entry()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        let midnight = Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)
        completion(Timeline(entries: [e], policy: .after(midnight)))
    }

    private func entry() -> LunarEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return LunarEntry(
            date: Date(),
            solarDay:    defaults?.string(forKey: "solar_day")     ?? "--",
            weekday:     defaults?.string(forKey: "solar_weekday") ?? "---",
            lunarDay:    defaults?.string(forKey: "lunar_day")     ?? "--",
            lunarMonth:  defaults?.string(forKey: "lunar_month")   ?? "--",
            canChiDay:   defaults?.string(forKey: "can_chi_day")   ?? "---",
            canChiYear:  defaults?.string(forKey: "can_chi_year")  ?? "---",
            isAuspicious: (defaults?.string(forKey: "is_auspicious") ?? "0") == "1",
            holiday:     defaults?.string(forKey: "holiday")       ?? ""
        )
    }
}

// MARK: - Colours (Nocturne palette)
private extension Color {
    static let nocBg      = Color(red: 0.086, green: 0.094, blue: 0.149)  // #161826
    static let nocAccent  = Color(red: 0.569, green: 0.518, blue: 0.851)  // #9184D9
    static let nocMuted   = Color(red: 0.576, green: 0.592, blue: 0.671)  // #9397AB
    static let nocGood    = Color(red: 0.569, green: 0.518, blue: 0.851)
    static let nocBad     = Color(red: 0.459, green: 0.424, blue: 0.651)  // subdued
    static let nocText    = Color(red: 0.914, green: 0.914, blue: 0.929)  // #E9E9ED
}

// MARK: - Lock Screen (accessoryRectangular) view
struct LockScreenRectView: View {
    let entry: LunarEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.weekday.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(entry.solarDay)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                Text(entry.isAuspicious ? "Hoàng đạo" : "Hắc đạo")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(entry.isAuspicious ? Color.nocGood : Color.nocBad)
            }
            Text("Âm \(entry.lunarDay)/\(entry.lunarMonth) · \(entry.canChiDay)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            if !entry.holiday.isEmpty {
                Text(entry.holiday)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.nocAccent)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Lock Screen (accessoryCircular) view
struct LockScreenCircleView: View {
    let entry: LunarEntry
    var body: some View {
        VStack(spacing: 0) {
            Text(entry.solarDay)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(entry.lunarDay + "/" + entry.lunarMonth)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Home Screen (systemSmall) view
struct SmallWidgetView: View {
    let entry: LunarEntry
    var body: some View {
        ZStack {
            Color.nocBg
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.weekday)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.nocMuted)
                    Spacer()
                    Text(entry.isAuspicious ? "✦" : "✧")
                        .font(.system(size: 11))
                        .foregroundColor(Color.nocAccent)
                }
                Text(entry.solarDay)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color.nocText)
                    .lineLimit(1)
                Spacer()
                Text("Âm \(entry.lunarDay)/\(entry.lunarMonth)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.nocAccent)
                Text(entry.canChiDay)
                    .font(.system(size: 10))
                    .foregroundColor(Color.nocMuted)
                if !entry.holiday.isEmpty {
                    Text(entry.holiday)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.nocAccent)
                        .lineLimit(1)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Widget entry view dispatcher
struct LichVietWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: LunarEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenRectView(entry: entry)
        case .accessoryCircular:
            LockScreenCircleView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget configuration
@main
struct LichVietWidget: Widget {
    let kind: String = "LichVietWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LichVietProvider()) { entry in
            LichVietWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Lịch Việt")
        .description("Âm lịch · Can chi · Ngày hoàng đạo")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}
