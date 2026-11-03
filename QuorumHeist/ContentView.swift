import SwiftUI

struct ContentView: View {
    let nodes = makeStartingCluster()

    var body: some View {
        VStack(spacing: 24) {
            Text("Quorum Heist")
                .font(.largeTitle.bold())
            ClusterRing(nodes: nodes)
                .frame(width: 420, height: 420)
            Text("Money supply: $\(nodes.first?.ledger.total ?? 0)")
                .font(.title2.monospacedDigit())
        }
        .padding(40)
        .onAppear { valueSemanticsDemo() }
    }
}

struct ClusterRing: View {
    let nodes: [ServerNode]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 50
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                let angle = Double(index) / Double(nodes.count) * 2 * .pi - .pi / 2
                NodeBadge(node: node)
                    .position(x: center.x + radius * cos(angle),
                              y: center.y + radius * sin(angle))
            }
        }
    }
}

struct NodeBadge: View {
    let node: ServerNode

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(.green.gradient)
                .frame(width: 70, height: 70)
                .overlay(Text(node.name).font(.headline).foregroundStyle(.white))
            Text("$\(node.ledger.total)")
                .font(.caption.monospacedDigit())
        }
    }
}

#Preview { ContentView() }
