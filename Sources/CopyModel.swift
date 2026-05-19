import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class CopyModel: ObservableObject {
    @Published var items: [ImageItem] = []
    @Published var destination: URL?
    @Published var isCopying = false
    @Published var copiedCount = 0
    @Published var showsError = false
    @Published var errorMessage = ""

    private let imageTypes: [UTType] = [.image, .heic, .heif, .jpeg, .png, .tiff, .gif, .rawImage]

    var canCopy: Bool {
        !items.isEmpty && destination != nil && !isCopying
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(copiedCount) / Double(items.count)
    }

    var status: String {
        if isCopying {
            return "Copying \(copiedCount) of \(items.count)..."
        }

        if copiedCount > 0 {
            return "Copied \(copiedCount) image\(copiedCount == 1 ? "" : "s") with original creation dates."
        }

        return "Ready"
    }

    func chooseImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = imageTypes

        if panel.runModal() == .OK {
            addURLs(panel.urls)
        }
    }

    func chooseDestination() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"

        if panel.runModal() == .OK {
            destination = panel.url
        }
    }

    func clear() {
        items.removeAll()
        copiedCount = 0
    }

    func addDroppedItems(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
                guard
                    let data = item as? Data,
                    let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }

                Task { @MainActor in
                    self?.addURLs([url])
                }
            }
        }

        return true
    }

    func copyImages() {
        guard let destination else { return }

        isCopying = true
        copiedCount = 0

        Task {
            do {
                for item in items {
                    _ = try CopyEngine.copyPreservingDates(from: item.url, toDirectory: destination)
                    copiedCount += 1
                }
                isCopying = false
            } catch {
                isCopying = false
                errorMessage = error.localizedDescription
                showsError = true
            }
        }
    }

    private func addURLs(_ urls: [URL]) {
        let newItems = urls
            .filter { Self.isImage($0) }
            .map(ImageItem.init(url:))

        let existing = Set(items.map(\.url))
        items.append(contentsOf: newItems.filter { !existing.contains($0.url) })
        copiedCount = 0
    }

    private static func isImage(_ url: URL) -> Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }

        return type.conforms(to: .image)
    }

}

struct ImageItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL

    var createdDescription: String {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let creationDate = attributes?[.creationDate] as? Date
        return creationDate.map { "Created: \($0.formatted(date: .abbreviated, time: .standard))" } ?? "Created: unavailable"
    }
}
