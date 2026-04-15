import SwiftUI

struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 2)

                content
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(24)
        }
        .scrollIndicators(.automatic)
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.15), lineWidth: 0.5)
        )
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
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            accessory
        }
    }
}

/// A visually lighter card for supplementary/secondary settings sections.
struct SettingsSecondaryCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct CompactSettingsMenuLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)

            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 0.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
