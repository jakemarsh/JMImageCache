//
//  UIImageView+JMImageCache.swift
//  JMImageCache
//
//  Created by Jake Marsh on 7/23/12.
//  Rewritten in Swift on 12/31/24.
//  Copyright 2012-2025 Jake Marsh. All rights reserved.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit
import ObjectiveC

// MARK: - Associated Object Keys

private var imageURLKey: UInt8 = 0
private var loadingTaskKey: UInt8 = 1

// MARK: - UIImageView Extension

public extension UIImageView {

    /// The URL of the image currently being loaded.
    private(set) var jm_imageURL: URL? {
        get { objc_getAssociatedObject(self, &imageURLKey) as? URL }
        set { objc_setAssociatedObject(self, &imageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// The current loading task.
    private var jm_loadingTask: Task<Void, Never>? {
        get { objc_getAssociatedObject(self, &loadingTaskKey) as? Task<Void, Never> }
        set { objc_setAssociatedObject(self, &loadingTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // MARK: - Public Methods

    /// Sets the image from a URL with optional placeholder and callbacks.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - placeholder: An optional placeholder image to show while loading.
    ///   - completion: Optional callback when the image loads successfully.
    ///   - failure: Optional callback when loading fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// imageView.setImage(
    ///     with: url,
    ///     placeholder: UIImage(named: "placeholder")
    /// ) { image in
    ///     print("Image loaded!")
    /// }
    /// ```
    @MainActor
    func setImage(
        with url: URL?,
        key: String? = nil,
        placeholder: UIImage? = nil,
        completion: ((UIImage?) -> Void)? = nil,
        failure: ((Error) -> Void)? = nil
    ) {
        // Cancel any existing load
        jm_loadingTask?.cancel()
        jm_loadingTask = nil

        guard let url else {
            self.image = placeholder
            jm_imageURL = nil
            completion?(nil)
            return
        }

        // Store the URL to track which image we're loading
        jm_imageURL = url

        // Set placeholder immediately
        self.image = placeholder

        // Check cache first (synchronously for immediate display)
        let cacheKey = key ?? url.absoluteString
        if let cached = JMImageCache.shared.cachedImage(forKey: cacheKey) {
            self.image = cached
            jm_imageURL = nil
            completion?(cached)
            return
        }

        // Load asynchronously
        let task = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }

            do {
                let image = try await JMImageCache.shared.image(for: url, key: key)

                // Only update if this is still the image we want
                guard !Task.isCancelled, self.jm_imageURL == url else { return }

                self.image = image
                self.jm_imageURL = nil
                completion?(image)

            } catch {
                guard !Task.isCancelled, self.jm_imageURL == url else { return }

                // Keep placeholder on failure
                self.jm_imageURL = nil
                failure?(error)
            }
        }

        jm_loadingTask = task
    }

    /// Cancels any in-progress image loading.
    func cancelImageLoad() {
        jm_loadingTask?.cancel()
        jm_loadingTask = nil
        jm_imageURL = nil
    }

    // MARK: - Legacy API Compatibility

    /// Sets the image from a URL. Legacy method for Objective-C compatibility.
    @objc
    @MainActor
    func setImageWithURL(_ url: URL) {
        setImage(with: url)
    }

    /// Sets the image from a URL with a placeholder. Legacy method.
    @objc
    @MainActor
    func setImageWithURL(_ url: URL, placeholder: UIImage?) {
        setImage(with: url, placeholder: placeholder)
    }

    /// Sets the image from a URL with placeholder and completion. Legacy method.
    @MainActor
    func setImageWithURL(
        _ url: URL,
        placeholder: UIImage?,
        completionBlock: ((UIImage?) -> Void)?
    ) {
        setImage(with: url, placeholder: placeholder, completion: completionBlock)
    }

    /// Sets the image from a URL with all callbacks. Legacy method.
    @MainActor
    func setImageWithURL(
        _ url: URL,
        key: String?,
        placeholder: UIImage?,
        completionBlock: ((UIImage?) -> Void)?,
        failureBlock: ((Error) -> Void)?
    ) {
        setImage(with: url, key: key, placeholder: placeholder, completion: completionBlock, failure: failureBlock)
    }
}
#endif
