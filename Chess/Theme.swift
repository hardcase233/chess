import SwiftUI

enum Deco {
    static let gold = Color(red: 0.83, green: 0.69, blue: 0.22)
    static let paleGold = Color(red: 0.95, green: 0.85, blue: 0.55)
    static let deepGold = Color(red: 0.55, green: 0.42, blue: 0.10)
    static let ivory = Color(red: 0.96, green: 0.93, blue: 0.84)
    static let cream = Color(red: 0.90, green: 0.85, blue: 0.72)
    static let ink = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let onyx = Color(red: 0.13, green: 0.13, blue: 0.15)
    static let goldGradient = LinearGradient(colors: [paleGold, gold, deepGold],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// A fan of rays radiating from the bottom centre, the classic Art Deco sunburst.
struct Sunburst: Shape {
    var rays = 24
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.maxY)
        let r = max(rect.width, rect.height) * 1.2
        for i in 0..<rays where i % 2 == 0 {
            let a0 = Double.pi + Double.pi * Double(i) / Double(rays)
            let a1 = Double.pi + Double.pi * Double(i + 1) / Double(rays)
            p.move(to: c)
            p.addLine(to: CGPoint(x: c.x + r * cos(a0), y: c.y + r * sin(a0)))
            p.addLine(to: CGPoint(x: c.x + r * cos(a1), y: c.y + r * sin(a1)))
            p.closeSubpath()
        }
        return p
    }
}

/// A stepped, chevron-style divider.
struct DecoDivider: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(Deco.gold).frame(height: 1.5)
            Diamond().fill(Deco.gold).frame(width: 10, height: 10)
            Diamond().stroke(Deco.gold, lineWidth: 1.5).frame(width: 16, height: 16)
            Diamond().fill(Deco.gold).frame(width: 10, height: 10)
            Rectangle().fill(Deco.gold).frame(height: 1.5)
        }
    }
}

struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.midY))
            p.closeSubpath()
        }
    }
}
