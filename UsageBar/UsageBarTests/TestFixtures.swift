import Foundation
import XCTest

private final class TestBundleLocator {}

enum TestFixtures {
    static func data(named name: String) throws -> Data {
        let bundle = Bundle(for: TestBundleLocator.self)
        let fixtureName = (name as NSString).deletingPathExtension
        let fixtureExtension = (name as NSString).pathExtension.isEmpty ? "json" : (name as NSString).pathExtension

        guard let url = bundle.url(forResource: fixtureName, withExtension: fixtureExtension) else {
            throw NSError(
                domain: "FixtureError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Fixture file not found: \(name)"]
            )
        }

        return try Data(contentsOf: url)
    }

    static func jsonObject(named name: String) throws -> Any {
        let data = try data(named: name)
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}