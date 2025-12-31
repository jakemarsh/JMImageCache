//
//  CachedAsyncImage.swift
//  JMImageCache
//
//  Created by Jake Marsh on 12/31/24.
//  Copyright 2024-2025 Jake Marsh. All rights reserved.
//

import SwiftUI

/// A SwiftUI view that asynchronously loads and displays an image with caching support.
///
/// `CachedAsyncImage` provides similar functionality to SwiftUI's `AsyncImage`,
/// but with disk and memory caching powered by `JMImageCache`.
///
/// ## Basic Usage
///
/// ```swift
/// CachedAsyncImage(url: URL(string: "https://example.com/image.jpg"))
/// ```
///
/// ## With Placeholder and Error View
///
/// ```swift
/// CachedAsyncImage(url: imageURL) { phase in
///     switch phase {
///     case .empty:
///         ProgressView()
///     case .success(let image):
///         image
///             .resizable()
///             .aspectRatio(contentMode: .fit)
///     case .failure:
///         Image(systemName: "photo")
///             .foregroundColor(.gray)
///     }
/// }
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CachedAsyncImage<Content: View>: View {

    // MARK: - Properties

    private let url: URL?
    private let cacheKey: String?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    // MARK: - Initialization

    /// Creates an async image with custom content based on the loading phase.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - cacheKey: Optional custom cache key. Defaults to URL's absoluteString.
    ///   - scale: The scale factor for the image. Defaults to 1.
    ///   - transaction: The transaction to use when the phase changes.
    ///   - content: A closure that returns the view for each loading phase.
    public init(
        url: URL?,
        cacheKey: String? = nil,
        scale: CGFloat = 1,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.cacheKey = cacheKey
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        content(phase)
            .task(id: url) {
                await loadImage()
            }
    }

    // MARK: - Loading

    @MainActor
    private func loadImage() async {
        guard let url else {
            phase = .empty
            return
        }

        // Check cache first for instant display
        let key = cacheKey ?? url.absoluteString
        if let cached = JMImageCache.shared.cachedImage(forKey: key) {
            withTransaction(transaction) {
                phase = .success(Image(platformImage: cached))
            }
            return
        }

        // Show loading state
        phase = .empty

        do {
            let image = try await JMImageCache.shared.image(for: url, key: cacheKey)
            withTransaction(transaction) {
                phase = .success(Image(platformImage: image))
            }
        } catch {
            withTransaction(transaction) {
                phase = .failure(error)
            }
        }
    }
}

// MARK: - Convenience Initializers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension CachedAsyncImage where Content == _CachedAsyncImageContent {

    /// Creates an async image that displays the loaded image.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - cacheKey: Optional custom cache key.
    ///   - scale: The scale factor for the image.
    init(url: URL?, cacheKey: String? = nil, scale: CGFloat = 1) {
        self.init(url: url, cacheKey: cacheKey, scale: scale) { phase in
            _CachedAsyncImageContent(phase: phase)
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension CachedAsyncImage {

    /// Creates an async image with a placeholder view.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - cacheKey: Optional custom cache key.
    ///   - scale: The scale factor for the image.
    ///   - placeholder: A view to display while loading.
    init<P: View>(
        url: URL?,
        cacheKey: String? = nil,
        scale: CGFloat = 1,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _CachedAsyncImageContentWithPlaceholder<P> {
        self.init(url: url, cacheKey: cacheKey, scale: scale) { phase in
            _CachedAsyncImageContentWithPlaceholder(phase: phase, placeholder: placeholder)
        }
    }
}

// MARK: - Content Views

/// Default content view for CachedAsyncImage.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct _CachedAsyncImageContent: View {
    let phase: AsyncImagePhase

    public var body: some View {
        switch phase {
        case .empty:
            Color.clear
        case .success(let image):
            image
        case .failure:
            Color.clear
        @unknown default:
            Color.clear
        }
    }
}

/// Content view with placeholder for CachedAsyncImage.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct _CachedAsyncImageContentWithPlaceholder<Placeholder: View>: View {
    let phase: AsyncImagePhase
    let placeholder: () -> Placeholder

    public var body: some View {
        switch phase {
        case .empty:
            placeholder()
        case .success(let image):
            image
        case .failure:
            placeholder()
        @unknown default:
            placeholder()
        }
    }
}

// MARK: - Platform Image Extension

private extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
