import SwiftUI
import SwiftData

struct ExportView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @State private var range: ExportRange = .thisMonth
    @State private var format: ExportFormat = .csv
    @State private var shareItem: ShareItem?

    enum ExportRange: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case allTime = "All Time"
    }

    enum ExportFormat: String, CaseIterable { case csv = "CSV / Excel"; case pdf = "PDF" }

    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private var filtered: [Transaction] {
        let now = Date()
        let cal = Calendar.current
        return all.filter { txn in
            switch range {
            case .thisWeek:  return cal.isDate(txn.date, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth: return cal.isDate(txn.date, equalTo: now, toGranularity: .month)
            case .thisYear:  return cal.isDate(txn.date, equalTo: now, toGranularity: .year)
            case .allTime:   return true
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Summary
            VStack(spacing: 4) {
                Text("\(filtered.count) transactions").font(.title2.bold())
                Text(range.rawValue).font(.subheadline).foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cardStyle()
            .padding(.horizontal)

            // Range picker
            VStack(alignment: .leading) {
                Text("Date Range").font(.headline).padding(.horizontal)
                Picker("Range", selection: $range) {
                    ForEach(ExportRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipped()
            }
            .cardStyle()
            .padding(.horizontal)

            // Format picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Format").font(.headline)
                HStack(spacing: 12) {
                    ForEach(ExportFormat.allCases, id: \.self) { fmt in
                        Button {
                            format = fmt
                        } label: {
                            HStack {
                                Image(systemName: fmt == .csv ? "tablecells" : "doc.richtext")
                                Text(fmt.rawValue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(format == fmt ? AppTheme.violet.opacity(0.12) : Color(.systemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(format == fmt ? AppTheme.violet : .clear, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(format == fmt ? AppTheme.violet : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .cardStyle()
            .padding(.horizontal)

            // Export button
            Button { export() } label: {
                Label("Export & Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.gradient)
                    .foregroundColor(.white)
                    .font(.headline)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .disabled(filtered.isEmpty)

            Spacer()
        }
        .padding(.top, 16)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Export Records")
        .sheet(item: $shareItem) { item in
            ShareSheet(url: item.url)
        }
    }

    private func export() {
        switch format {
        case .csv: exportCSV()
        case .pdf: exportPDF()
        }
    }

    private func exportCSV() {
        var csv = "Date,Type,Category,Amount,Note\n"
        let df = DateFormatter(); df.dateStyle = .short
        for t in filtered {
            csv += "\(df.string(from: t.date)),\(t.isExpense ? "Expense" : "Income"),\(t.category),\(t.amount),\(t.note)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sripada_export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareItem = ShareItem(url: url)
    }

    private func exportPDF() {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x:0,y:0,width:595,height:842))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 20)]
            let bodyAttr:  [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            "Sripada Expense Buddy — Export".draw(at: CGPoint(x:40,y:40), withAttributes: titleAttr)
            "\(range.rawValue) · \(filtered.count) transactions".draw(at: CGPoint(x:40,y:70), withAttributes: bodyAttr)
            let df = DateFormatter(); df.dateStyle = .short
            var y = 110.0
            for t in filtered.prefix(50) {
                let line = "\(df.string(from: t.date))  \(t.isExpense ? "EXP" : "INC")  \(t.category)  ₹\(Int(t.amount))  \(t.note)"
                line.draw(at: CGPoint(x:40,y:y), withAttributes: bodyAttr)
                y += 20
                if y > 800 { break }
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sripada_export.pdf")
        try? data.write(to: url)
        shareItem = ShareItem(url: url)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
