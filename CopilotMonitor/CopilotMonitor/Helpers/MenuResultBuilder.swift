import AppKit

@resultBuilder
struct MenuItemBuilder {

    static func buildBlock(_ components: NSMenuItem...) -> [NSMenuItem] {
        Array(components)
    }

    static func buildBlock(_ components: [NSMenuItem]...) -> [NSMenuItem] {
        components.flatMap { $0 }
    }

    static func buildOptional(_ component: [NSMenuItem]?) -> [NSMenuItem] {
        component ?? []
    }

    static func buildEither(first component: [NSMenuItem]) -> [NSMenuItem] {
        component
    }

    static func buildEither(second component: [NSMenuItem]) -> [NSMenuItem] {
        component
    }

    static func buildArray(_ components: [[NSMenuItem]]) -> [NSMenuItem] {
        components.flatMap { $0 }
    }

    static func buildExpression(_ expression: NSMenuItem) -> [NSMenuItem] {
        [expression]
    }
}

extension NSMenu {

    convenience init(title: String = "", @MenuItemBuilder _ items: () -> [NSMenuItem]) {
        self.init(title: title)
        items().forEach { addItem($0) }
    }

    func replaceItems(@MenuItemBuilder with items: () -> [NSMenuItem]) {
        removeAllItems()
        items().forEach { addItem($0) }
    }
}

func SeparatorItem() -> NSMenuItem {
    NSMenuItem.separator()
}

func MenuItem(
    _ title: String,
    action: Selector? = nil,
    keyEquivalent: String = ""
) -> NSMenuItem {
    NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
}
