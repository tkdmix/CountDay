//
//  ContentView.swift
//  CountDay
//

import SwiftUI

struct ContentView: View {
    @AppStorage("dailyCounts") private var dailyCountsJSON = "{}"
    @State private var isShowingResetConfirmation = false
    @State private var isShowingAboutPrivacy = false
    @State private var isShowingHistory = false

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var todayKey: String {
        Self.dayKeyFormatter.string(from: .now)
    }

    private var todayText: String {
        Date.now.formatted(.dateTime.year().month().day().weekday())
    }

    private var dailyCounts: [String: Int] {
        guard let data = dailyCountsJSON.data(using: .utf8),
              let counts = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }

        return counts
    }

    private var count: Int {
        dailyCounts[todayKey, default: 0]
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let layout = MainLayout(size: proxy.size)

                VStack(spacing: layout.sectionSpacing) {
                    VStack(spacing: layout.headerSpacing) {
                        Text("CountDay")
                            .font(layout.titleFont)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(todayText)
                            .font(layout.dateFont)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Text(count, format: .number)
                        .font(.system(size: layout.countFontSize, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .accessibilityLabel("Current count")
                        .accessibilityValue("\(count)")

                    HStack(spacing: layout.buttonSpacing) {
                        Button {
                            decrement()
                        } label: {
                            CounterButtonLabel(title: "Decrease", systemImage: "minus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(count == 0)

                        Button {
                            increment()
                        } label: {
                            CounterButtonLabel(title: "Increase", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button("Reset", role: .destructive) {
                        isShowingResetConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .disabled(count == 0)
                }
                .padding(.horizontal, layout.horizontalPadding)
                .padding(.vertical, layout.verticalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("CountDay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")

                    Button {
                        isShowingAboutPrivacy = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("About and Privacy")
                }
            }
            .sheet(isPresented: $isShowingAboutPrivacy) {
                AboutPrivacyView(dailyCountsJSON: $dailyCountsJSON)
            }
            .sheet(isPresented: $isShowingHistory) {
                HistoryView(dailyCountsJSON: dailyCountsJSON)
            }
            .onAppear {
                migrateLegacyCountIfNeeded()
            }
            .confirmationDialog(
                "Reset count?",
                isPresented: $isShowingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    resetTodayCount()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will set today's count back to 0.")
            }
        }
    }

    private func decrement() {
        setTodayCount(max(0, count - 1))
    }

    private func increment() {
        setTodayCount(count + 1)
    }

    private func resetTodayCount() {
        setTodayCount(0)
    }

    private func setTodayCount(_ newCount: Int) {
        var counts = dailyCounts
        counts[todayKey] = max(0, newCount)

        if let data = try? JSONEncoder().encode(counts),
           let json = String(data: data, encoding: .utf8) {
            dailyCountsJSON = json
        }
    }

    private func migrateLegacyCountIfNeeded() {
        guard dailyCounts.isEmpty,
              UserDefaults.standard.object(forKey: "count") != nil else {
            return
        }

        setTodayCount(UserDefaults.standard.integer(forKey: "count"))
        UserDefaults.standard.removeObject(forKey: "count")
    }
}

private struct MainLayout {
    let size: CGSize

    private var isLandscape: Bool {
        size.width > size.height
    }

    private var isNarrow: Bool {
        min(size.width, size.height) < 390
    }

    var sectionSpacing: CGFloat {
        isLandscape ? 18 : 32
    }

    var headerSpacing: CGFloat {
        isLandscape ? 6 : 8
    }

    var buttonSpacing: CGFloat {
        isNarrow ? 12 : 16
    }

    var countFontSize: CGFloat {
        isLandscape ? 60 : 88
    }

    var titleFont: Font {
        isLandscape ? .title : .largeTitle
    }

    var dateFont: Font {
        .subheadline
    }

    var horizontalPadding: CGFloat {
        isLandscape || isNarrow ? 16 : 24
    }

    var verticalPadding: CGFloat {
        isLandscape ? 8 : 16
    }
}

private struct CounterButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)

            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    let dailyCountsJSON: String

    private var entries: [(date: String, count: Int)] {
        guard let data = dailyCountsJSON.data(using: .utf8),
              let counts = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return []
        }

        return counts
            .filter { $0.value > 0 }
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, count: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "まだ記録がありません",
                        systemImage: "calendar.badge.clock"
                    )
                } else {
                    List(entries, id: \.date) { entry in
                        LabeledContent(entry.date, value: entry.count.formatted())
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AboutPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var dailyCountsJSON: String
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text("CountDay is a simple counter app for keeping track of daily counts.")
                    LabeledContent("Version", value: "1.1")
                }

                Section("Privacy") {
                    Label("Data is saved only on this device.", systemImage: "iphone")
                    Label("No network communication.", systemImage: "wifi.slash")
                    Label("No account required.", systemImage: "person.crop.circle.badge.xmark")
                    Label("No ads.", systemImage: "megaphone")
                    Label("No tracking.", systemImage: "hand.raised")
                }

                Section("Data") {
                    Button("Delete All Data", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("About / Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete all data?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Data", role: .destructive) {
                    deleteAllData()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove every saved count on this device.")
            }
        }
    }

    private func deleteAllData() {
        dailyCountsJSON = "{}"
        UserDefaults.standard.removeObject(forKey: "count")
    }
}

#Preview {
    ContentView()
}
