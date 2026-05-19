import XCTest
@testable import CopyWithCreationDate

final class CopyEngineTests: XCTestCase {
    func testCopyPreservesCreationAndModificationDates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceDirectory = root.appendingPathComponent("source", isDirectory: true)
        let destinationDirectory = root.appendingPathComponent("destination", isDirectory: true)

        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = sourceDirectory.appendingPathComponent("image.jpg")
        try Data("sample".utf8).write(to: source)

        let creationDate = Date(timeIntervalSince1970: 1_600_000_000)
        let modificationDate = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes(
            [.creationDate: creationDate, .modificationDate: modificationDate],
            ofItemAtPath: source.path
        )

        let copied = try CopyEngine.copyPreservingDates(from: source, toDirectory: destinationDirectory)
        let copiedAttributes = try FileManager.default.attributesOfItem(atPath: copied.path)
        let copiedCreationDate = try XCTUnwrap(copiedAttributes[.creationDate] as? Date)
        let copiedModificationDate = try XCTUnwrap(copiedAttributes[.modificationDate] as? Date)

        XCTAssertEqual(copiedCreationDate.timeIntervalSince1970, creationDate.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(copiedModificationDate.timeIntervalSince1970, modificationDate.timeIntervalSince1970, accuracy: 1)
    }

    func testCopyAvoidsOverwritingExistingFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceDirectory = root.appendingPathComponent("source", isDirectory: true)
        let destinationDirectory = root.appendingPathComponent("destination", isDirectory: true)

        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = sourceDirectory.appendingPathComponent("image.jpg")
        let existing = destinationDirectory.appendingPathComponent("image.jpg")
        try Data("new".utf8).write(to: source)
        try Data("existing".utf8).write(to: existing)

        let copied = try CopyEngine.copyPreservingDates(from: source, toDirectory: destinationDirectory)

        XCTAssertEqual(copied.lastPathComponent, "image 2.jpg")
        XCTAssertEqual(try String(contentsOf: existing), "existing")
    }
}
