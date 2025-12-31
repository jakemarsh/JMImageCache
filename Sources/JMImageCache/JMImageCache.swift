//
//  JMImageCache.swift
//  JMImageCache
//
//  Created by Jake Marsh on 2/7/11.
//  Rewritten in Swift with async/await on 12/31/24.
//  Copyright 2011-2025 Jake Marsh. All rights reserved.
//

import Foundation
import CommonCrypto

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// A modern, async/await-based image caching library for iOS, macOS, tvOS, and watchOS.
///
/// JMImageCache provides both in-memory (NSCache) and disk-based caching for images
/// downloaded from the network. It supports both completion-handler and async/await patterns.
///
/// ## Basic Usage
///
/// ```swift
/// // Using async/await
/// let image = try await JMImageCache.shared.image(for: url)
///
/// // Using completion handler
/// JMImageCache.shared.image(for: url) { image in
///     // Use image
/// }
/// ```
public final class JMImageCache: @unchecked Sendable {

    // MARK: - Shared Instance

    /// The shared image cache instance.
    @MainActor
    public static let shared = JMImageCache()

    // MARK: - Properties

    private let memoryCache = NSCache<NSString, AnyObject>()
    private let diskQueue = DispatchQueue(label: "com.jakemarsh.JMImageCache.disk", qos: .utility)
    private let urlSession: URLSession

    /// The directory where cached images are stored on disk.
    public let cacheDirectory: URL

    // MARK: - Initialization

    /// Creates a new image cache with optional custom configuration.
    /// - Parameters:
    ///   - cacheDirectory: Custom directory for disk cache. Defaults to Library/Caches/JMCache.
    ///   - urlSession: Custom URLSession for network requests. Defaults to shared session.
    public init(
        cacheDirectory: URL? = nil,
        urlSession: URLSession = .shared
    ) {
        self.urlSession = urlSession

        // Set up cache directory
        if let customDir = cacheDirectory {
            self.cacheDirectory = customDir
        } else {
            let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.cacheDirectory = cachesDir.appendingPathComponent("JMCache", isDirectory: true)
        }

        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache
        memoryCache.name = "com.jakemarsh.JMImageCache"
        memoryCache.countLimit = 100
    }

    // MARK: - Async/Await API

    /// Fetches an image from the cache or downloads it from the network.
    /// - Parameters:
    ///   - url: The URL of the image to fetch.
    ///   - key: Optional custom cache key. If nil, the URL's absoluteString is used.
    /// - Returns: The cached or downloaded image.
    /// - Throws: `JMImageCacheError` if the image cannot be fetched.
    public func image(for url: URL, key: String? = nil) async throws -> PlatformImage {
        let cacheKey = key ?? url.absoluteString

        // Check memory cache first
        if let cached = cachedImage(forKey: cacheKey) {
            return cached
        }

        // Check disk cache
        if let diskImage = await imageFromDisk(forKey: cacheKey) {
            setImage(diskImage, forKey: cacheKey)
            return diskImage
        }

        // Download from network
        return try await downloadImage(from: url, key: cacheKey)
    }

    /// Downloads an image from the network and caches it.
    private func downloadImage(from url: URL, key: String) async throws -> PlatformImage {
        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JMImageCacheError.invalidResponse(response)
        }

        guard let image = PlatformImage(data: data) else {
            throw JMImageCacheError.invalidImageData
        }

        // Cache the image
        setImage(image, forKey: key)

        // Write to disk asynchronously
        Task.detached(priority: .utility) { [weak self] in
            await self?.writeToDisk(data: data, forKey: key)
        }

        return image
    }

    // MARK: - Completion Handler API (for backward compatibility)

    /// Fetches an image from the cache or downloads it from the network.
    /// - Parameters:
    ///   - url: The URL of the image to fetch.
    ///   - key: Optional custom cache key.
    ///   - completion: Called on the main thread with the image or nil on failure.
    ///   - failure: Optional failure handler called on the main thread.
    public func image(
        for url: URL,
        key: String? = nil,
        completion: @escaping @MainActor (PlatformImage?) -> Void,
        failure: (@MainActor (Error) -> Void)? = nil
    ) {
        Task { @MainActor in
            do {
                let image = try await self.image(for: url, key: key)
                completion(image)
            } catch {
                completion(nil)
                failure?(error)
            }
        }
    }

    // MARK: - Cache Operations

    /// Returns the cached image for the given key, or nil if not cached.
    public func cachedImage(forKey key: String) -> PlatformImage? {
        memoryCache.object(forKey: key as NSString) as? PlatformImage
    }

    /// Returns the cached image for the given URL, or nil if not cached.
    public func cachedImage(for url: URL) -> PlatformImage? {
        cachedImage(forKey: url.absoluteString)
    }

    /// Caches an image in memory with the given key.
    public func setImage(_ image: PlatformImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
    }

    /// Caches an image in memory with the URL as the key.
    public func setImage(_ image: PlatformImage, for url: URL) {
        setImage(image, forKey: url.absoluteString)
    }

    /// Removes a cached image from both memory and disk.
    public func removeImage(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let filePath = self.diskPath(forKey: key)
            try? FileManager.default.removeItem(at: filePath)
        }
    }

    /// Removes a cached image for the given URL.
    public func removeImage(for url: URL) {
        removeImage(forKey: url.absoluteString)
    }

    /// Clears all cached images from memory and disk.
    public func removeAllImages() {
        memoryCache.removeAllObjects()

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let fileManager = FileManager.default
            if let contents = try? fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil) {
                for file in contents {
                    try? fileManager.removeItem(at: file)
                }
            }
        }
    }

    // MARK: - Disk Operations

    /// Loads an image from disk cache.
    private func imageFromDisk(forKey key: String) async -> PlatformImage? {
        await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }

                let filePath = self.diskPath(forKey: key)

                guard let data = try? Data(contentsOf: filePath),
                      let image = PlatformImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    /// Writes image data to disk.
    private func writeToDisk(data: Data, forKey key: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            diskQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                let filePath = self.diskPath(forKey: key)
                try? data.write(to: filePath, options: .atomic)
                continuation.resume()
            }
        }
    }

    /// Returns the disk path for a cache key.
    private func diskPath(forKey key: String) -> URL {
        let hashedKey = sha1(key)
        return cacheDirectory.appendingPathComponent("JMImageCache-\(hashedKey)")
    }

    /// Computes SHA1 hash of a string.
    private func sha1(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA1(bytes.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Errors

/// Errors that can occur when fetching images.
public enum JMImageCacheError: Error, LocalizedError {
    case invalidResponse(URLResponse?)
    case invalidImageData
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let response):
            return "Invalid response: \(String(describing: response))"
        case .invalidImageData:
            return "Failed to create image from data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
