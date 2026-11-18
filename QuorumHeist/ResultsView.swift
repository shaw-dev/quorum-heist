import SwiftUI
import SwiftData
import Charts

struct ResultsView: View {
    @Query(sort: \Run.date) private var runs: [Run]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Latency by run").font(.title2.bold())

            if runs.isEmpty {
                Text("No runs yet. Send 20 transfers to record one.")
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(Array(runs.enumerated()), id: \.element.id) { i, run in
                        let name = "#\(i + 1) \(run.label)"
                        BarMark(x: .value("Run", name), y: .value("ms", run.p50))
                            .foregroundStyle(by: .value("Percentile", "p50"))
                            .position(by: .value("Percentile", "p50"))
                        BarMark(x: .value("Run", name), y: .value("ms", run.p95))
                            .foregroundStyle(by: .value("Percentile", "p95"))
                            .position(by: .value("Percentile", "p95"))
                        BarMark(x: .value("Run", name), y: .value("ms", run.p99))
                            .foregroundStyle(by: .value("Percentile", "p99"))
                            .position(by: .value("Percentile", "p99"))
                    }
                }
                .chartYAxisLabel("Latency (ms)")
                .frame(height: 260)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(runs.enumerated()), id: \.element.id) { i, run in
                            Text("#\(i + 1) \(run.label): \(run.committed)/\(run.transfers) committed · p50 \(Int(run.p50)) · p95 \(Int(run.p95)) · p99 \(Int(run.p99)) ms · \(run.conflicts) conflicts")
                                .font(.caption.monospaced())
                        }
                    }
                }
            }

            HStack {
                Button("Delete all runs", role: .destructive) {
                    try? modelContext.delete(model: Run.self)
                }
                Spacer()
                Button("Done") { dismiss() }
            }
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 520)
    }
}
