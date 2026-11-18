import SwiftUI
import AppKit
import SwiftData

struct ContentView: View {
    @State private var cluster = Cluster()
    @Environment(\.modelContext) private var modelContext
    @State private var showResults = false

    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            // LEFT: the game
            VStack(spacing: 24) {
                Text("Quorum Heist")
                    .font(.largeTitle.bold())
                ClusterRing(nodes: cluster.nodes, packets: cluster.packets, partitioned: cluster.partitioned) { id in
                    cluster.toggle(nodeID: id)
                }
                .frame(width: 420, height: 420)

                HStack(spacing: 32) {
                    Text("Money supply: $\(cluster.moneySupply)")
                        .foregroundStyle(cluster.moneySupply == 10_000 ? Color.primary : Color.red)
                    Text("Servers up: \(cluster.healthyCount)/\(cluster.nodes.count)")
                }
                .font(.title2.monospacedDigit())

                HStack(spacing: 24) {
                    Stepper("Read quorum R: \(cluster.r)", value: $cluster.r, in: 1...5)
                    Stepper("Write quorum W: \(cluster.w)", value: $cluster.w, in: 1...5)
                    Toggle("Partition network: {A, B} | {C, D, E}", isOn: $cluster.partitioned)
                }
                .fixedSize()

                Text(cluster.r + cluster.w > cluster.nodes.count
                     ? "R + W > N: every read overlaps the latest write ✅"
                     : "R + W ≤ N: reads can miss the latest write ⚠️")
                    .foregroundStyle(cluster.r + cluster.w > cluster.nodes.count ? .green : .orange)

                HStack {
                    Button("Send 1 transfer") { Task { _ = await cluster.sendTransfers(1) } }
                    Button("Send 20 transfers") {
                        Task {
                            let run = await cluster.sendTransfers(20)
                            modelContext.insert(run)
                        }
                    }
                    Button("Reset") { cluster.reset() }
                    Button("Results") { showResults = true }
                }

                if let ok = cluster.lastResult, let c = cluster.lastClient {
                    Text("Client \(c + 1)\(cluster.partitioned ? (c == 0 ? " (A,B side)" : " (C,D,E side)") : ""): \(ok ? "committed" : "FAILED")")
                        .foregroundStyle(ok ? .green : .orange)
                }
            }

            // RIGHT: the heist log
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🚨 Heist log (\(cluster.anomalies.count))").font(.headline)
                    Spacer()
                    Button("Copy log as JSON") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cluster.exportLog(), forType: .string)
                    }
                    .disabled(cluster.anomalies.isEmpty)
                }
                if cluster.anomalies.isEmpty {
                    Text("No heists yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(cluster.anomalies) { a in
                                Text("#\(a.transferNumber)  \(a.message)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(a.kind == .conflict ? .red : .orange)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                Spacer()
            }
            .frame(width: 380)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(40)
        .background(cluster.alarm ? Color.red.opacity(0.15) : Color.clear)
        .animation(.easeOut(duration: 0.3), value: cluster.alarm)
        .sheet(isPresented: $showResults) { ResultsView() }
    }
        
}

struct ClusterRing: View {
    let nodes: [ServerNode]
    let packets: [Packet]
    let partitioned: Bool
    let onTap: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 50

            if partitioned {
                Path { p in
                    p.move(to: point(4.5, center, radius + 60))
                    p.addLine(to: point(1.5, center, radius + 60))
                }
                .stroke(.red, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
            }

            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                NodeBadge(node: node)
                    .onTapGesture { onTap(node.id) }
                    .position(point(Double(index), center, radius))
            }
            ForEach(packets) { packet in
                PacketDot(state: packet.state,
                          from: center,
                          to: point(Double(packet.target), center, radius))
            }
        }
    }

    private func point(_ index: Double, _ center: CGPoint, _ radius: CGFloat) -> CGPoint {
        let angle = index / Double(nodes.count) * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + radius * cos(angle),
                       y: center.y + radius * sin(angle))
    }
}

struct PacketDot: View {
    let state: PacketState
    let from: CGPoint
    let to: CGPoint
    @State private var launched = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .scaleEffect(state == .dropped ? 2.5 : 1)
            .opacity(state == .dropped ? 0 : 1)
            .position(launched ? to : from)
            .animation(.easeOut(duration: 0.4), value: state)
            .onAppear {
                withAnimation(.easeOut(duration: 0.15)) { launched = true }
            }
    }

    private var color: Color {
        switch state {
        case .flying: .blue
        case .delivered: .green
        case .dropped: .red
        }
    }
}
struct NodeBadge: View {
    let node: ServerNode

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(node.status.isUp ? Color.green.gradient : Color.red.gradient)
                .frame(width: 70, height: 70)
                .overlay(Text(node.name).font(.headline).foregroundStyle(.white))
                .opacity(node.status.isUp ? 1 : 0.5)
            Text("\(node.applied) ops")
                .font(.caption.monospacedDigit())
            if case .crashed(let since) = node.status {
                Text(since, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.red)
            }
        }
        .animation(.spring, value: node.status.isUp)
    }
}

#Preview { ContentView().modelContainer(for: Run.self, inMemory: true) }
