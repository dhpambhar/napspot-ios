import SwiftUI

/// Our own napping cat: a round head with ears, closed eyes and a little nose.
struct CatView: View {
    var color: Color = Theme.cat
    var faceColor: Color = Theme.catFace
    var awake = false

    var body: some View {
        Canvas { gc, size in
            let s = min(size.width, size.height)
            let ox = (size.width - s) / 2, oy = (size.height - s) / 2
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            let pink = Color(hex: 0xF4A3A8)

            // Ears
            var ears = Path()
            ears.move(to: p(0.16, 0.42)); ears.addLine(to: p(0.22, 0.10)); ears.addLine(to: p(0.46, 0.30)); ears.closeSubpath()
            ears.move(to: p(0.84, 0.42)); ears.addLine(to: p(0.78, 0.10)); ears.addLine(to: p(0.54, 0.30)); ears.closeSubpath()
            gc.fill(ears, with: .color(color))

            // Head
            gc.fill(Path(ellipseIn: CGRect(origin: p(0.10, 0.22), size: CGSize(width: 0.80 * s, height: 0.66 * s))),
                    with: .color(color))

            // Inner ears
            var inner = Path()
            inner.move(to: p(0.24, 0.36)); inner.addLine(to: p(0.26, 0.20)); inner.addLine(to: p(0.38, 0.31)); inner.closeSubpath()
            inner.move(to: p(0.76, 0.36)); inner.addLine(to: p(0.74, 0.20)); inner.addLine(to: p(0.62, 0.31)); inner.closeSubpath()
            gc.fill(inner, with: .color(pink.opacity(0.9)))

            if awake {
                let eye = CGSize(width: 0.11 * s, height: 0.13 * s)
                gc.fill(Path(ellipseIn: CGRect(origin: p(0.30, 0.44), size: eye)), with: .color(faceColor))
                gc.fill(Path(ellipseIn: CGRect(origin: p(0.59, 0.44), size: eye)), with: .color(faceColor))
            } else {
                // Closed, sleepy eyes: two little smiles
                var eyes = Path()
                eyes.addArc(center: p(0.355, 0.48), radius: 0.08 * s, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                eyes.move(to: p(0.720, 0.507))
                eyes.addArc(center: p(0.645, 0.48), radius: 0.08 * s, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                gc.stroke(eyes, with: .color(faceColor), style: StrokeStyle(lineWidth: max(1.2, s * 0.055), lineCap: .round))
            }

            // Nose and mouth
            var nose = Path()
            nose.move(to: p(0.46, 0.63)); nose.addLine(to: p(0.54, 0.63)); nose.addLine(to: p(0.50, 0.68)); nose.closeSubpath()
            gc.fill(nose, with: .color(pink))
            var mouth = Path()
            mouth.move(to: p(0.50, 0.68))
            mouth.addQuadCurve(to: p(0.42, 0.73), control: p(0.47, 0.74))
            mouth.move(to: p(0.50, 0.68))
            mouth.addQuadCurve(to: p(0.58, 0.73), control: p(0.53, 0.74))
            gc.stroke(mouth, with: .color(faceColor), style: StrokeStyle(lineWidth: max(1, s * 0.035), lineCap: .round))

            // Whiskers
            var whiskers = Path()
            for (y0, y1) in [(0.62, 0.58), (0.68, 0.70)] as [(CGFloat, CGFloat)] {
                whiskers.move(to: p(0.28, y0)); whiskers.addLine(to: p(0.02, y1))
                whiskers.move(to: p(0.72, y0)); whiskers.addLine(to: p(0.98, y1))
            }
            gc.stroke(whiskers, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: max(0.8, s * 0.025), lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        CatView().frame(width: 120, height: 120)
        CatView(awake: true).frame(width: 120, height: 120)
    }
    .padding()
    .background(RegionPalette.fill(0))
}
