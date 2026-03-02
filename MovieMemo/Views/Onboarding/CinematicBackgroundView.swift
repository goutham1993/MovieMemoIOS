//
//  CinematicBackgroundView.swift
//  MovieMemo
//

import SwiftUI

/// Full-bleed cinematic background used across all onboarding pages.
/// Dark vertical gradient (black → deep navy) with optional static grain overlay.
struct CinematicBackgroundView: View {
    var showGrain: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(hex: "06060F"),
                    Color(hex: "080818")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if showGrain {
                GrainOverlay()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Grain Overlay

private struct GrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            var rng = SystemRandomNumberGenerator()
            for _ in 0..<2500 {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let alpha = Double.random(in: 0.012...0.04, using: &rng)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
    }
}
