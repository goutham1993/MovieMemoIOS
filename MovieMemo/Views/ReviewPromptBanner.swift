import SwiftUI

/// Root-level non-blocking review prompt banner.
struct ReviewPromptBannerHost: View {
    @ObservedObject private var reviewManager = ReviewManager.shared

    var body: some View {
        ZStack {
            if reviewManager.isBannerVisible {
                banner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: reviewManager.isBannerVisible)
    }

    private var banner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Enjoying MovieMemo?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    Text("Rate us with a quick star tap.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                }

                Spacer(minLength: 0)

                Button("Not now") {
                    reviewManager.dismissBanner()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.tertiaryText)
                .buttonStyle(.plain)

                Button("Rate") {
                    reviewManager.userTappedRateFromBanner()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.screenH)
            .padding(.vertical, 12)
            .background(
                Theme.surface2
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.divider, lineWidth: 1)
                    )
            )
            .padding(.horizontal, Theme.Spacing.screenH)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Keep it out of the status bar / notch.
        .padding(.top, 6)
    }
}

