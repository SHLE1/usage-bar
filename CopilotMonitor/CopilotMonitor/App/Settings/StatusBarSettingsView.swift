import SwiftUI
import os.log
import UniformTypeIdentifiers

struct StatusBarSettingsView: View {
    private enum PayAsYouGoSettingsItem: Hashable, Identifiable {
        case provider(ProviderIdentifier)
        case copilotAddOn

        init?(storageKey: String) {
            if storageKey == AppPreferences.copilotAddOnStorageKey {
                self = .copilotAddOn
                return
            }

            guard let identifier = ProviderIdentifier(rawValue: storageKey) else {
                return nil
            }

            self = .provider(identifier)
        }

        var id: String { storageKey }

        var storageKey: String {
            switch self {
            case let .provider(identifier):
                return identifier.rawValue
            case .copilotAddOn:
                return AppPreferences.copilotAddOnStorageKey
            }
        }

        var displayName: String {
            switch self {
            case let .provider(identifier):
                return identifier.displayName
            case .copilotAddOn:
                return L("GitHub Copilot Add-on")
            }
        }

        var iconProvider: ProviderIdentifier {
            switch self {
            case let .provider(identifier):
                return identifier
            case .copilotAddOn:
                return .copilot
            }
        }
    }

    @ObservedObject private var prefs = AppPreferences.shared
    @State private var payAsYouGoItemsOrder: [PayAsYouGoSettingsItem]
    @State private var subscriptionOrder: [ProviderIdentifier]
    @State private var draggedPayAsYouGoItem: PayAsYouGoSettingsItem?
    @State private var draggedSubscriptionProvider: ProviderIdentifier?
    private let logger = Logger(subsystem: "com.opencodeproviders", category: "StatusBarSettingsView")

    private var visiblePayAsYouGoPreviewItems: [PayAsYouGoSettingsItem] {
        payAsYouGoItemsOrder.filter { item in
            switch item {
            case let .provider(identifier):
                return prefs.isProviderEnabled(identifier)
            case .copilotAddOn:
                return shouldShowCopilotAddOnPreview
            }
        }
    }

    private var enabledSubscription: [ProviderIdentifier] {
        subscriptionOrder.filter { prefs.isProviderEnabled($0) }
    }

    private var shouldShowCopilotAddOnPreview: Bool {
        prefs.copilotAddOnEnabled && prefs.isProviderEnabled(.copilot)
    }

    private var shouldShowPayAsYouGoPreview: Bool {
        !visiblePayAsYouGoPreviewItems.isEmpty
    }

    private var shouldShowQuotaPreview: Bool {
        !enabledSubscription.isEmpty
    }

    private var previewAnimationKey: String {
        let payAsYouGo = visiblePayAsYouGoPreviewItems.map(\.storageKey).joined(separator: ",")
        let subscription = enabledSubscription.map(\.rawValue).joined(separator: ",")
        return "\(payAsYouGo)|\(subscription)"
    }

    init() {
        let prefs = AppPreferences.shared
        _payAsYouGoItemsOrder = State(
            initialValue: prefs.payAsYouGoSettingsItemOrder(
                providers: AppPreferences.statusBarPayAsYouGoProviders
            ).compactMap {
                PayAsYouGoSettingsItem(storageKey: $0)
            }
        )
        _subscriptionOrder = State(
            initialValue: prefs.statusBarSettingsOrder(
                for: .subscription,
                providers: AppPreferences.statusBarSubscriptionProviders
            )
        )
    }

    var body: some View {
        SettingsPage {
            previewSection

            SettingsSectionCard(
                title: L("Pay-as-you-go Providers"),
                subtitle: L("These providers appear in the usage-based cost section."),
                contentInsets: .init()
            ) {
                payAsYouGoList
            }

            SettingsSectionCard(
                title: L("Subscription Providers"),
                subtitle: L("Quota-based providers shown in the quota section and the top status bar summary."),
                contentInsets: .init()
            ) {
                subscriptionList
            }

            SettingsSecondaryCard(
                title: L("How this appears"),
                contentInsets: .init()
            ) {
                Text(L("Top status bar shows quota-based providers only. Use Advanced Providers for overrides such as the Codex account and limit window."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            reloadStoredOrders()
            logger.debug("Status bar settings loaded with simplified menu preview and draggable provider lists")
        }
    }

    // MARK: - Live Preview Section

    @ViewBuilder
    private var previewSection: some View {
        SettingsSectionCard(
            title: L("Menu Preview"),
            contentInsets: .init()
        ) {
            VStack(alignment: .leading, spacing: 0) {
                if shouldShowPayAsYouGoPreview {
                    previewHeader(title: L("Pay-as-you-go"))
                        .transition(.opacity)
                    ForEach(visiblePayAsYouGoPreviewItems) { item in
                        previewRow(
                            provider: item.iconProvider,
                            text: item.displayName,
                            trailingText: "$—"
                        )
                        .transition(.opacity)
                    }
                }

                if shouldShowPayAsYouGoPreview && shouldShowQuotaPreview {
                    Divider()
                        .padding(.vertical, 4)
                        .transition(.opacity)
                }

                if shouldShowQuotaPreview {
                    previewHeader(title: L("Quota Status"))
                        .transition(.opacity)
                    ForEach(enabledSubscription, id: \.self) { provider in
                        previewRow(
                            provider: provider,
                            text: provider.displayName,
                            trailingText: L("—% left")
                        )
                        .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.18), value: previewAnimationKey)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var payAsYouGoList: some View {
        orderListContainer {
            ForEach(Array(payAsYouGoItemsOrder.enumerated()), id: \.element) { index, item in
                payAsYouGoRow(for: item)
                if index < payAsYouGoItemsOrder.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: payAsYouGoItemsOrder)
    }

    private var subscriptionList: some View {
        orderListContainer {
            ForEach(Array(subscriptionOrder.enumerated()), id: \.element) { index, provider in
                subscriptionRow(for: provider)
                if index < subscriptionOrder.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: subscriptionOrder)
    }

    private func orderListContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func previewHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            .padding(.vertical, 3)
    }

    @ViewBuilder
    private func previewRow(provider: ProviderIdentifier? = nil, text: String, trailingText: String? = nil, dimmed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if let provider {
                previewIcon(for: provider, dimmed: dimmed)
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(dimmed ? .tertiary : .primary)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func previewIcon(for provider: ProviderIdentifier, dimmed: Bool) -> some View {
        SettingsProviderIcon(provider: provider, dimmed: dimmed)
    }

    @ViewBuilder
    private func payAsYouGoRow(for item: PayAsYouGoSettingsItem) -> some View {
        let enabled = isEnabled(item)

        HStack(spacing: 12) {
            payAsYouGoDragLabel(for: item, enabled: enabled)

            Spacer(minLength: 12)

            Toggle("", isOn: payAsYouGoBinding(for: item))
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .opacity(enabled ? 1 : 0.72)
        .contentShape(Rectangle())
        .onDrop(
            of: [UTType.plainText],
            delegate: ReorderDropDelegate(
                targetItem: item,
                draggedItem: $draggedPayAsYouGoItem,
                canReorderTogether: { isEnabled($0) == isEnabled($1) },
                move: movePayAsYouGoItem
            )
        )
    }

    @ViewBuilder
    private func subscriptionRow(for provider: ProviderIdentifier) -> some View {
        let enabled = prefs.isProviderEnabled(provider)

        HStack(spacing: 12) {
            subscriptionDragLabel(for: provider, enabled: enabled)

            Spacer(minLength: 12)

            Toggle("", isOn: statusBarBinding(for: provider, section: .subscription))
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .opacity(enabled ? 1 : 0.72)
        .contentShape(Rectangle())
        .onDrop(
            of: [UTType.plainText],
            delegate: ReorderDropDelegate(
                targetItem: provider,
                draggedItem: $draggedSubscriptionProvider,
                canReorderTogether: { prefs.isProviderEnabled($0) == prefs.isProviderEnabled($1) },
                move: moveSubscriptionProvider
            )
        )
    }

    @ViewBuilder
    private func payAsYouGoDragLabel(for item: PayAsYouGoSettingsItem, enabled: Bool) -> some View {
        HStack(spacing: 12) {
            dragHandleIcon()
            previewIcon(for: item.iconProvider, dimmed: !enabled)

            Text(item.displayName)
                .font(.system(size: 13))
                .foregroundStyle(enabled ? .primary : .secondary)
        }
        .contentShape(Rectangle())
        .onDrag {
            draggedPayAsYouGoItem = item
            logger.debug("Started dragging pay-as-you-go item \(item.storageKey, privacy: .public) from combined row label")
            return NSItemProvider(object: item.storageKey as NSString)
        }
    }

    @ViewBuilder
    private func subscriptionDragLabel(for provider: ProviderIdentifier, enabled: Bool) -> some View {
        HStack(spacing: 12) {
            dragHandleIcon()
            previewIcon(for: provider, dimmed: !enabled)

            Text(provider.displayName)
                .font(.system(size: 13))
                .foregroundStyle(enabled ? .primary : .secondary)
        }
        .contentShape(Rectangle())
        .onDrag {
            draggedSubscriptionProvider = provider
            logger.debug("Started dragging subscription provider \(provider.rawValue, privacy: .public) from combined row label")
            return NSItemProvider(object: provider.rawValue as NSString)
        }
    }

    @ViewBuilder
    private func dragHandleIcon() -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 16, height: 16)
    }

    private func payAsYouGoBinding(for item: PayAsYouGoSettingsItem) -> Binding<Bool> {
        switch item {
        case let .provider(identifier):
            return statusBarBinding(for: identifier, section: .payAsYouGo)
        case .copilotAddOn:
            return copilotAddOnBinding
        }
    }

    private func movePayAsYouGoItem(_ source: PayAsYouGoSettingsItem, _ destination: PayAsYouGoSettingsItem) {
        guard isEnabled(source) == isEnabled(destination),
              let sourceIndex = payAsYouGoItemsOrder.firstIndex(of: source),
              let destinationIndex = payAsYouGoItemsOrder.firstIndex(of: destination),
              sourceIndex != destinationIndex else {
            return
        }

        var updated = payAsYouGoItemsOrder
        updated.move(
            fromOffsets: IndexSet(integer: sourceIndex),
            toOffset: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex
        )

        let normalizedKeys = prefs.normalizedPayAsYouGoSettingsItemOrder(
            updated.map(\.storageKey),
            providers: AppPreferences.statusBarPayAsYouGoProviders
        )
        let normalizedItems = normalizedKeys.compactMap(PayAsYouGoSettingsItem.init(storageKey:))

        withAnimation(.easeInOut(duration: 0.18)) {
            payAsYouGoItemsOrder = normalizedItems
        }

        prefs.setPayAsYouGoSettingsItemOrder(normalizedKeys)
        logger.debug("Persisted pay-as-you-go settings order: \(normalizedKeys.joined(separator: ","), privacy: .public)")
    }

    private func moveSubscriptionProvider(_ source: ProviderIdentifier, _ destination: ProviderIdentifier) {
        guard prefs.isProviderEnabled(source) == prefs.isProviderEnabled(destination),
              let sourceIndex = subscriptionOrder.firstIndex(of: source),
              let destinationIndex = subscriptionOrder.firstIndex(of: destination),
              sourceIndex != destinationIndex else {
            return
        }

        var updated = subscriptionOrder
        updated.move(
            fromOffsets: IndexSet(integer: sourceIndex),
            toOffset: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex
        )

        let normalized = prefs.normalizedStatusBarOrder(
            updated,
            allProviders: AppPreferences.statusBarSubscriptionProviders
        )

        withAnimation(.easeInOut(duration: 0.18)) {
            subscriptionOrder = normalized
        }

        prefs.setStatusBarSettingsOrder(normalized, for: .subscription)
        logger.debug("Persisted subscription settings order: \(normalized.map { $0.rawValue }.joined(separator: ","), privacy: .public)")
    }

    private func reloadStoredOrders() {
        payAsYouGoItemsOrder = prefs.payAsYouGoSettingsItemOrder(
            providers: AppPreferences.statusBarPayAsYouGoProviders
        ).compactMap {
            PayAsYouGoSettingsItem(storageKey: $0)
        }
        subscriptionOrder = prefs.statusBarSettingsOrder(
            for: .subscription,
            providers: AppPreferences.statusBarSubscriptionProviders
        )
        logger.debug(
            "Reloaded status bar settings order: payg=\(payAsYouGoItemsOrder.map(\.storageKey).joined(separator: ","), privacy: .public) subscription=\(subscriptionOrder.map { $0.rawValue }.joined(separator: ","), privacy: .public)"
        )
    }

    // MARK: - Unified toggle binding

    /// A single toggle that controls both the enabled state and multi-provider membership.
    private func statusBarBinding(
        for identifier: ProviderIdentifier,
        section: AppPreferences.StatusBarSettingsSection
    ) -> Binding<Bool> {
        Binding(
            get: { prefs.isProviderEnabled(identifier) },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    prefs.setProviderEnabled(identifier, enabled: newValue)
                }

                updateRememberedOrder(for: identifier, enabled: newValue, section: section)
                logger.debug(
                    "Status bar provider visibility changed: \(identifier.rawValue, privacy: .public)=\(newValue, privacy: .public)"
                )
            }
        )
    }

    private var copilotAddOnBinding: Binding<Bool> {
        Binding(
            get: { prefs.copilotAddOnEnabled },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    prefs.copilotAddOnEnabled = newValue
                }
                payAsYouGoItemsOrder = AppPreferences.rememberedItemOrder(
                    from: payAsYouGoItemsOrder,
                    toggled: .copilotAddOn,
                    enabled: newValue,
                    isEnabled: isEnabled
                )
                prefs.setPayAsYouGoSettingsItemOrder(payAsYouGoItemsOrder.map(\.storageKey))
                logger.debug(
                    "Status bar provider visibility changed: copilot_add_on=\(newValue, privacy: .public), order=\(payAsYouGoItemsOrder.map(\.storageKey).joined(separator: ","), privacy: .public)"
                )
            }
        )
    }

    private func isEnabled(_ item: PayAsYouGoSettingsItem) -> Bool {
        switch item {
        case let .provider(identifier):
            return prefs.isProviderEnabled(identifier)
        case .copilotAddOn:
            return prefs.copilotAddOnEnabled
        }
    }

    private func updateRememberedOrder(
        for identifier: ProviderIdentifier,
        enabled: Bool,
        section: AppPreferences.StatusBarSettingsSection
    ) {
        switch section {
        case .payAsYouGo:
            payAsYouGoItemsOrder = AppPreferences.rememberedItemOrder(
                from: payAsYouGoItemsOrder,
                toggled: .provider(identifier),
                enabled: enabled,
                isEnabled: isEnabled
            )
            prefs.setPayAsYouGoSettingsItemOrder(payAsYouGoItemsOrder.map(\.storageKey))
            logger.debug(
                "Normalized pay-as-you-go order after toggle: \(payAsYouGoItemsOrder.map(\.storageKey).joined(separator: ","), privacy: .public)"
            )
        case .subscription:
            subscriptionOrder = updatedRememberedOrder(
                from: subscriptionOrder,
                toggled: identifier,
                enabled: enabled,
                section: section,
                allProviders: AppPreferences.statusBarSubscriptionProviders
            )
            logger.debug(
                "Normalized subscription order after toggle: \(subscriptionOrder.map { $0.rawValue }.joined(separator: ","), privacy: .public)"
            )
        }
    }

    private func updatedRememberedOrder(
        from currentOrder: [ProviderIdentifier],
        toggled identifier: ProviderIdentifier,
        enabled: Bool,
        section: AppPreferences.StatusBarSettingsSection,
        allProviders: [ProviderIdentifier]
    ) -> [ProviderIdentifier] {
        let order = AppPreferences.rememberedStatusBarOrder(
            from: currentOrder,
            toggled: identifier,
            enabled: enabled,
            allProviders: allProviders,
            isEnabled: { prefs.isProviderEnabled($0) }
        )

        prefs.setStatusBarSettingsOrder(order, for: section)
        return prefs.statusBarSettingsOrder(for: section, providers: allProviders)
    }
}

private struct ReorderDropDelegate<Item: Hashable>: DropDelegate {
    let targetItem: Item
    @Binding var draggedItem: Item?
    let canReorderTogether: (Item, Item) -> Bool
    let move: (Item, Item) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem != targetItem,
              canReorderTogether(draggedItem, targetItem) else {
            return
        }

        move(draggedItem, targetItem)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
}
