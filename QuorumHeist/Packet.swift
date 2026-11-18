import Foundation
enum PacketState {
    case flying, delivered, dropped
}

struct Packet: Identifiable {
    let id = UUID()
    let target: Int          // index of the server it's flying to
    var state: PacketState = .flying
}
