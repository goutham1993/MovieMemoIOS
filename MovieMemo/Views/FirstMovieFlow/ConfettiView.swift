//
//  ConfettiView.swift
//  MovieMemo
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animate = false

    private let colors: [Color] = [
        Theme.accent,
        Color(hex: "FFD700"),
        Color(hex: "FF6B6B"),
        Color(hex: "4ECDC4"),
        Color(hex: "45B7D1"),
        Color(hex: "96CEB4"),
        Color(hex: "FFEAA7"),
        Color.white
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let elapsed = now - particle.startTime
                    guard elapsed > 0, elapsed < particle.lifetime else { continue }

                    let progress = elapsed / particle.lifetime
                    let gravity = 600.0 * elapsed * elapsed * 0.5
                    let x = particle.startX + particle.velocityX * elapsed
                    let y = particle.startY + particle.velocityY * elapsed + gravity
                    let rotation = Angle.degrees(particle.rotationSpeed * elapsed)
                    let opacity = 1.0 - pow(progress, 2)
                    let scale = particle.scale * (1.0 - progress * 0.3)

                    guard y < size.height + 50 else { continue }

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)
                    context.scaleBy(x: scale, y: scale)

                    let rect = CGRect(x: -particle.width / 2, y: -particle.height / 2,
                                      width: particle.width, height: particle.height)

                    if particle.isCircle {
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    } else {
                        let path = Path(roundedRect: rect, cornerRadius: 1.5)
                        context.fill(path, with: .color(particle.color))
                    }

                    context.transform = .identity
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear { spawnParticles() }
    }

    private func spawnParticles() {
        let now = Date.timeIntervalSinceReferenceDate
        let screenWidth = UIScreen.main.bounds.width

        particles = (0..<70).map { _ in
            let isCircle = Bool.random()
            return ConfettiParticle(
                startX: CGFloat.random(in: -20...screenWidth + 20),
                startY: CGFloat.random(in: -80 ... -20),
                velocityX: CGFloat.random(in: -120...120),
                velocityY: CGFloat.random(in: -350 ... -50),
                rotationSpeed: Double.random(in: -360...360),
                scale: CGFloat.random(in: 0.6...1.4),
                width: isCircle ? CGFloat.random(in: 6...10) : CGFloat.random(in: 4...8),
                height: isCircle ? CGFloat.random(in: 6...10) : CGFloat.random(in: 10...18),
                color: colors.randomElement()!,
                isCircle: isCircle,
                lifetime: Double.random(in: 2.5...4.0),
                startTime: now + Double.random(in: 0...0.5)
            )
        }
    }
}

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotationSpeed: Double
    let scale: CGFloat
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let isCircle: Bool
    let lifetime: Double
    let startTime: TimeInterval
}
