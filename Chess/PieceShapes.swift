import SwiftUI

/// Angular Art Deco silhouettes drawn in a unit square (0...1), scaled to the rect.
struct PieceShape: Shape {
    let kind: PieceKind

    func path(in rect: CGRect) -> Path {
        let pts: [[CGPoint]] = PieceShape.polygons(kind)
        var p = Path()
        for poly in pts {
            guard let first = poly.first else { continue }
            p.move(to: map(first, rect))
            for pt in poly.dropFirst() { p.addLine(to: map(pt, rect)) }
            p.closeSubpath()
        }
        return p
    }

    private func map(_ pt: CGPoint, _ r: CGRect) -> CGPoint {
        CGPoint(x: r.minX + pt.x * r.width, y: r.minY + pt.y * r.height)
    }

    private static func P(_ a: [(CGFloat, CGFloat)]) -> [CGPoint] { a.map { CGPoint(x: $0.0, y: $0.1) } }

    // Shared stepped plinth used by every piece.
    private static let base: [[CGPoint]] = [
        P([(0.18, 0.92), (0.82, 0.92), (0.78, 0.86), (0.22, 0.86)]),
        P([(0.25, 0.84), (0.75, 0.84), (0.72, 0.79), (0.28, 0.79)])
    ]

    static func polygons(_ k: PieceKind) -> [[CGPoint]] {
        switch k {
        case .pawn:
            return base + [
                P([(0.36, 0.77), (0.64, 0.77), (0.56, 0.52), (0.44, 0.52)]),
                P([(0.38, 0.50), (0.62, 0.50), (0.60, 0.46), (0.40, 0.46)]),
                P([(0.50, 0.24), (0.63, 0.34), (0.50, 0.44), (0.37, 0.34)])          // faceted head
            ]
        case .rook:
            return base + [
                P([(0.32, 0.77), (0.68, 0.77), (0.64, 0.38), (0.36, 0.38)]),
                P([(0.28, 0.36), (0.72, 0.36), (0.72, 0.20), (0.64, 0.20), (0.64, 0.27),
                   (0.555, 0.27), (0.555, 0.20), (0.445, 0.20), (0.445, 0.27),
                   (0.36, 0.27), (0.36, 0.20), (0.28, 0.20)])
            ]
        case .knight:
            return base + [
                P([(0.30, 0.77), (0.72, 0.77), (0.70, 0.55), (0.64, 0.40), (0.68, 0.26),
                   (0.56, 0.14), (0.50, 0.20), (0.42, 0.20), (0.24, 0.40), (0.28, 0.48),
                   (0.42, 0.42), (0.36, 0.60)])                                       // angular horse head
            ]
        case .bishop:
            return base + [
                P([(0.36, 0.77), (0.64, 0.77), (0.57, 0.50), (0.43, 0.50)]),
                P([(0.36, 0.48), (0.64, 0.48), (0.62, 0.44), (0.38, 0.44)]),
                P([(0.50, 0.14), (0.64, 0.30), (0.50, 0.42), (0.36, 0.30)]),          // mitre
                P([(0.48, 0.10), (0.52, 0.10), (0.52, 0.14), (0.48, 0.14)])
            ]
        case .queen:
            return base + [
                P([(0.34, 0.77), (0.66, 0.77), (0.58, 0.44), (0.42, 0.44)]),
                P([(0.32, 0.42), (0.68, 0.42), (0.66, 0.38), (0.34, 0.38)]),
                P([(0.34, 0.36), (0.66, 0.36), (0.76, 0.16), (0.62, 0.27), (0.56, 0.12),
                   (0.50, 0.25), (0.44, 0.12), (0.38, 0.27), (0.24, 0.16)])            // fanned crown
            ]
        case .king:
            return base + [
                P([(0.34, 0.77), (0.66, 0.77), (0.58, 0.44), (0.42, 0.44)]),
                P([(0.32, 0.42), (0.68, 0.42), (0.66, 0.38), (0.34, 0.38)]),
                P([(0.34, 0.36), (0.66, 0.36), (0.70, 0.22), (0.30, 0.22)]),
                P([(0.47, 0.20), (0.53, 0.20), (0.53, 0.14), (0.58, 0.14), (0.58, 0.10),
                   (0.53, 0.10), (0.53, 0.05), (0.47, 0.05), (0.47, 0.10), (0.42, 0.10),
                   (0.42, 0.14), (0.47, 0.14)])                                       // cross
            ]
        }
    }
}

struct PieceView: View {
    let piece: Piece

    var body: some View {
        let shape = PieceShape(kind: piece.kind)
        ZStack {
            if piece.color == .white {
                shape.fill(LinearGradient(colors: [.white, Deco.ivory, Deco.cream],
                                          startPoint: .top, endPoint: .bottom))
                shape.stroke(Deco.deepGold, lineWidth: 1.2)
            } else {
                shape.fill(LinearGradient(colors: [Deco.onyx, Deco.ink],
                                          startPoint: .top, endPoint: .bottom))
                shape.stroke(Deco.gold, lineWidth: 1.4)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1.5)
    }
}
