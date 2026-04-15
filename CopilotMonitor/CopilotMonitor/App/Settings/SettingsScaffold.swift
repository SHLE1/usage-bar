import AppKit
import SwiftUI

private let defaultSettingsCardContentInsets = EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

struct SettingsPage<Content: View>: View {
    let title: String?
    let subtitle: String?
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                content
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.automatic)
    }
}

/// Section card with title placed above GroupBox, matching macOS System Settings.
struct SettingsSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let contentInsets: EdgeInsets
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        contentInsets: EdgeInsets = defaultSettingsCardContentInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.contentInsets = contentInsets
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GroupBox {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(contentInsets)
            }
        }
    }
}

struct SettingsRow<Accessory: View>: View {
    let title: String
    let description: String?
    let accessory: Accessory

    init(
        title: String,
        description: String? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.description = description
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            accessory
        }
    }
}

enum SettingsSummaryRowTitleTone {
    case primary
    case secondary
}

/// A row variant for summary/metric values that need more breathing room.
/// The title acts as a label; the value is the focal point.
struct SettingsSummaryRow<Value: View>: View {
    let title: String
    let titleTone: SettingsSummaryRowTitleTone
    let value: Value

    init(
        title: String,
        titleTone: SettingsSummaryRowTitleTone = .secondary,
        @ViewBuilder value: () -> Value
    ) {
        self.title = title
        self.titleTone = titleTone
        self.value = value()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundStyle(titleTone == .primary ? .primary : .secondary)

            Spacer()

            value
        }
        .padding(.vertical, 4)
    }
}

struct SettingsProviderIcon: View {
    let provider: ProviderIdentifier?
    var dimmed: Bool = false
    var size: CGFloat = 14
    var showsFallback: Bool = false
    var fallbackSystemName: String = "questionmark.circle"

    var body: some View {
        Group {
            if let provider {
                providerIcon(for: provider)
            } else if showsFallback {
                Image(systemName: fallbackSystemName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: size, height: size)
        .foregroundStyle(dimmed ? .quaternary : .secondary)
    }

    @ViewBuilder
    private func providerIcon(for provider: ProviderIdentifier) -> some View {
        if let assetName = provider.menuIconAssetName,
           let nsImage = NSImage(named: assetName) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: provider.menuIconSymbolName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

/// Visually lighter section card for supplementary content.
struct SettingsSecondaryCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let contentInsets: EdgeInsets
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        contentInsets: EdgeInsets = defaultSettingsCardContentInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.contentInsets = contentInsets
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GroupBox {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(contentInsets)
            }
        }
    }
}
