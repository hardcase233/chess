import SwiftUI

struct ContentView: View {
    @State private var board = Board.standard()

    var body: some View {
        ZStack {
            Deco.ink.ignoresSafeArea()
            Sunburst()
                .fill(Deco.gold.opacity(0.07))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("CHESS")
                        .font(.system(size: 38, weight: .light, design: .serif))
                        .tracking(14)
                        .foregroundStyle(Deco.goldGradient)
                    DecoDivider().frame(maxWidth: 220)
                }

                BoardView(board: board)
                    .padding(.horizontal, 10)

                DecoDivider().frame(maxWidth: 220)
            }
        }
    }
}

struct BoardView: View {
    let board: Board

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 8
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { c in
                                SquareView(dark: (r + c) % 2 == 1, piece: board.squares[r][c])
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .overlay(Rectangle().stroke(Deco.gold, lineWidth: 2))
            .padding(6)
            .overlay(Rectangle().stroke(Deco.gold.opacity(0.6), lineWidth: 1))
            .overlay(CornerOrnaments().stroke(Deco.gold, lineWidth: 1.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct SquareView: View {
    let dark: Bool
    let piece: Piece?

    var body: some View {
        ZStack {
            Rectangle().fill(dark ? Deco.deepGold.opacity(0.9) : Deco.ivory)
            // inset geometric motif: a thin diamond on every square
            Diamond()
                .stroke(dark ? Deco.gold.opacity(0.35) : Deco.cream, lineWidth: 0.8)
                .padding(5)
            if let piece {
                PieceView(piece: piece).padding(2)
            }
        }
    }
}

/// Stepped L-shaped ornaments on the four outer corners of the frame.
struct CornerOrnaments: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let s: CGFloat = 16
        for (x, y, dx, dy) in [(r.minX, r.minY, 1.0, 1.0), (r.maxX, r.minY, -1.0, 1.0),
                               (r.minX, r.maxY, 1.0, -1.0), (r.maxX, r.maxY, -1.0, -1.0)] {
            let ox = x - dx * 6, oy = y - dy * 6
            p.move(to: CGPoint(x: ox, y: oy + dy * s * 2))
            p.addLine(to: CGPoint(x: ox, y: oy))
            p.addLine(to: CGPoint(x: ox + dx * s * 2, y: oy))
            p.move(to: CGPoint(x: ox + dx * 4, y: oy + dy * s * 1.2))
            p.addLine(to: CGPoint(x: ox + dx * 4, y: oy + dy * 4))
            p.addLine(to: CGPoint(x: ox + dx * s * 1.2, y: oy + dy * 4))
        }
        return p
    }
}
