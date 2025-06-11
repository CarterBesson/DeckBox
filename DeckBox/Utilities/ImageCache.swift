import SwiftUI

/// An actor that manages cached images in memory
actor ImageCache {
    static let shared = ImageCache()
    
    private var cache: [URL: Image] = [:]
    private var loadingTasks: [URL: Task<Image?, Error>] = [:]
    private var failedURLs: Set<URL> = []
    
    private init() {}
    
    func image(for url: URL) async throws -> Image? {
        // Return cached image if available
        if let cached = cache[url] {
            return cached
        }
        
        // If we've failed this URL before, don't try again
        if failedURLs.contains(url) {
            return nil
        }
        
        // If there's already a loading task, wait for it
        if let existingTask = loadingTasks[url] {
            return try await existingTask.value
        }
        
        // Create a new loading task
        let task = Task<Image?, Error> {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    let image = Image(uiImage: uiImage)
                    cache[url] = image
                    return image
                }
                failedURLs.insert(url)
                return nil
            } catch {
                failedURLs.insert(url)
                return nil
            }
        }
        
        loadingTasks[url] = task
        
        do {
            let result = try await task.value
            loadingTasks[url] = nil
            return result
        } catch {
            loadingTasks[url] = nil
            failedURLs.insert(url)
            return nil
        }
    }
    
    func clearCache() {
        cache.removeAll()
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
        failedURLs.removeAll()
    }
}

/// A view that loads and caches images asynchronously
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL
    private let scale: CGFloat
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    init(
        url: URL,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        AsyncImage(
            url: url,
            scale: scale,
            transaction: Transaction(animation: .none)
        ) { phase in
            switch phase {
            case .empty, .failure:
                placeholder()
            case .success(let image):
                content(image)
                    .task(priority: .background) {
                        _ = try? await ImageCache.shared.image(for: url)
                    }
            @unknown default:
                placeholder()
            }
        }
    }
} 