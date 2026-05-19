import Foundation

enum CopyEngine {
    static func copyPreservingDates(from source: URL, toDirectory destination: URL) throws -> URL {
        let fileManager = FileManager.default
        let attributes = try fileManager.attributesOfItem(atPath: source.path)
        let target = uniqueDestinationURL(for: source, in: destination)

        try fileManager.copyItem(at: source, to: target)

        var timestampAttributes: [FileAttributeKey: Any] = [:]
        if let creationDate = attributes[.creationDate] {
            timestampAttributes[.creationDate] = creationDate
        }
        if let modificationDate = attributes[.modificationDate] {
            timestampAttributes[.modificationDate] = modificationDate
        }

        if !timestampAttributes.isEmpty {
            try fileManager.setAttributes(timestampAttributes, ofItemAtPath: target.path)
        }

        return target
    }

    static func uniqueDestinationURL(for source: URL, in destination: URL) -> URL {
        let fileManager = FileManager.default
        let baseName = source.deletingPathExtension().lastPathComponent
        let pathExtension = source.pathExtension
        var candidate = destination.appendingPathComponent(source.lastPathComponent)
        var index = 2

        while fileManager.fileExists(atPath: candidate.path) {
            let filename = pathExtension.isEmpty ? "\(baseName) \(index)" : "\(baseName) \(index).\(pathExtension)"
            candidate = destination.appendingPathComponent(filename)
            index += 1
        }

        return candidate
    }
}
