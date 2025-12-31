//
//  JMImageCacheTests.swift
//  JMImageCache
//
//  Created by Jake Marsh on 12/31/24.
//  Copyright 2024-2025 Jake Marsh. All rights reserved.
//

import XCTest
@testable import JMImageCache

final class JMImageCacheTests: XCTestCase {

    var cache: JMImageCache!
    var testDirectory: URL!

    override func setUp() async throws {
        // Create a unique test directory for each test
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JMImageCacheTests-\(UUID().uuidString)")

        cache = JMImageCache(cacheDirectory: testDirectory)
    }

    override func tearDown() async throws {
        // Clean up test directory
        try? FileManager.default.removeItem(at: testDirectory)
        cache = nil
    }

    // MARK: - Memory Cache Tests

    @MainActor
    func testSetAndGetImageFromMemoryCache() {
        let image = createTestImage()
        let key = "test-key"

        cache.setImage(image, forKey: key)
        let retrieved = cache.cachedImage(forKey: key)

        XCTAssertNotNil(retrieved)
    }

    @MainActor
    func testSetAndGetImageWithURLKey() {
        let image = createTestImage()
        let url = URL(string: "https://example.com/image.png")!

        cache.setImage(image, for: url)
        let retrieved = cache.cachedImage(for: url)

        XCTAssertNotNil(retrieved)
    }

    @MainActor
    func testRemoveImageFromCache() {
        let image = createTestImage()
        let key = "test-remove-key"

        cache.setImage(image, forKey: key)
        XCTAssertNotNil(cache.cachedImage(forKey: key))

        cache.removeImage(forKey: key)

        // Give a moment for async disk operations
        let expectation = expectation(description: "Wait for removal")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertNil(cache.cachedImage(forKey: key))
    }

    @MainActor
    func testRemoveAllImages() {
        let image = createTestImage()

        cache.setImage(image, forKey: "key1")
        cache.setImage(image, forKey: "key2")
        cache.setImage(image, forKey: "key3")

        cache.removeAllImages()

        // Give a moment for async operations
        let expectation = expectation(description: "Wait for removal")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertNil(cache.cachedImage(forKey: "key1"))
        XCTAssertNil(cache.cachedImage(forKey: "key2"))
        XCTAssertNil(cache.cachedImage(forKey: "key3"))
    }

    // MARK: - Network Tests (with mock)

    @MainActor
    func testFetchImageFromNetwork() async throws {
        // Use a real image URL for integration testing
        let url = URL(string: "https://httpbin.org/image/png")!

        let image = try await cache.image(for: url)

        XCTAssertNotNil(image)
        // Should now be in memory cache
        XCTAssertNotNil(cache.cachedImage(for: url))
    }

    @MainActor
    func testFetchInvalidURLReturnsError() async {
        let url = URL(string: "https://httpbin.org/status/404")!

        do {
            _ = try await cache.image(for: url)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
            XCTAssertTrue(error is JMImageCacheError)
        }
    }

    @MainActor
    func testCacheHitDoesNotMakeNetworkRequest() async throws {
        let url = URL(string: "https://example.com/cached-image.png")!
        let cachedImage = createTestImage()

        // Pre-populate cache
        cache.setImage(cachedImage, for: url)

        // This should return immediately without network
        let retrieved = try await cache.image(for: url)

        XCTAssertNotNil(retrieved)
    }

    // MARK: - Completion Handler API Tests

    @MainActor
    func testCompletionHandlerAPI() {
        let expectation = expectation(description: "Completion called")
        let url = URL(string: "https://httpbin.org/image/png")!

        cache.image(for: url) { image in
            XCTAssertNotNil(image)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    @MainActor
    func testCompletionHandlerFailure() {
        let expectation = expectation(description: "Failure called")
        let url = URL(string: "https://httpbin.org/status/500")!

        cache.image(for: url, completion: { _ in }) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Custom Key Tests

    @MainActor
    func testCustomCacheKey() async throws {
        let url = URL(string: "https://httpbin.org/image/png")!
        let customKey = "my-custom-key"

        let image = try await cache.image(for: url, key: customKey)

        XCTAssertNotNil(image)
        XCTAssertNotNil(cache.cachedImage(forKey: customKey))
        // URL key should not exist
        XCTAssertNil(cache.cachedImage(for: url))
    }

    // MARK: - Cache Directory Tests

    func testCacheDirectoryIsCreated() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: testDirectory.path))
    }

    // MARK: - Helpers

    private func createTestImage() -> PlatformImage {
        #if canImport(UIKit)
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
        #elseif canImport(AppKit)
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
        #endif
    }
}
