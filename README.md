# JMImageCache

A fast, simple, and lightweight image caching library for iOS, macOS, tvOS, and watchOS.

`JMImageCache` provides both in-memory (NSCache) and disk-based caching for images downloaded from the network. It supports modern Swift async/await patterns while maintaining full backward compatibility with the original Objective-C API.

## Features

- **In-memory caching** - Automatic memory management via NSCache
- **Disk caching** - Persistent storage with SHA1-hashed filenames
- **Async/await support** - Modern Swift concurrency patterns
- **SwiftUI support** - `CachedAsyncImage` view component
- **UIKit support** - `UIImageView` extension for easy image loading
- **Backward compatible** - Original Objective-C API still works
- **Cross-platform** - iOS, macOS, tvOS, and watchOS
- **Thread-safe** - All operations are properly synchronized
- **Lightweight** - No external dependencies

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 15.0+

For older iOS versions (5.0-14.x), use the legacy Objective-C implementation included in this repo.

## Installation

### Swift Package Manager (Recommended)

Add JMImageCache to your project via SPM:

```swift
dependencies: [
    .package(url: "https://github.com/jakemarsh/JMImageCache.git", from: "2.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

### CocoaPods (Legacy)

```ruby
pod 'JMImageCache'
```

## Quick Start

### Swift (Async/Await)

```swift
import JMImageCache

// Simple async/await
let image = try await JMImageCache.shared.image(for: url)

// With custom cache key
let image = try await JMImageCache.shared.image(for: url, key: "my-custom-key")
```

### Swift (Completion Handler)

```swift
JMImageCache.shared.image(for: url) { image in
    imageView.image = image
} failure: { error in
    print("Failed: \(error)")
}
```

### SwiftUI

```swift
import JMImageCache

struct ContentView: View {
    var body: some View {
        CachedAsyncImage(url: URL(string: "https://example.com/image.jpg")) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
    }
}
```

### UIKit

```swift
import JMImageCache

// Simple usage
imageView.setImage(with: url)

// With placeholder
imageView.setImage(with: url, placeholder: UIImage(named: "placeholder"))

// With callbacks
imageView.setImage(with: url, placeholder: placeholderImage) { image in
    print("Loaded!")
} failure: { error in
    print("Error: \(error)")
}

// Cancel loading
imageView.cancelImageLoad()
```

### Objective-C (Legacy)

```objc
#import "JMImageCache.h"

// UIImageView category
[imageView setImageWithURL:url placeholder:placeholderImage];

// Direct cache access
[[JMImageCache sharedCache] imageForURL:url completionBlock:^(UIImage *image) {
    self.imageView.image = image;
}];
```

## How It Works

Images can be in three states:

1. **Cached In Memory** - Returned immediately
2. **Cached On Disk** - Loaded from disk, moved to memory, returned
3. **Not Cached** - Downloaded, saved to disk, cached in memory, returned

This approach ensures the fastest possible image delivery while minimizing network requests.

## Cache Management

### Clear All

```swift
// Swift
JMImageCache.shared.removeAllImages()

// Objective-C
[[JMImageCache sharedCache] removeAllObjects];
```

### Remove Specific Image

```swift
// Swift
JMImageCache.shared.removeImage(for: url)
JMImageCache.shared.removeImage(forKey: "my-key")

// Objective-C
[[JMImageCache sharedCache] removeImageForURL:url];
```

### Pre-cache Images

```swift
// Swift
let image = try await JMImageCache.shared.image(for: url)
// Image is now cached for future use
```

### Check Cache

```swift
// Swift
if let cached = JMImageCache.shared.cachedImage(for: url) {
    // Image is in memory cache
}
```

## Custom Configuration

```swift
// Custom cache directory
let cache = JMImageCache(
    cacheDirectory: customURL,
    urlSession: .shared
)
```

## Migration from v1.x (Objective-C)

The Swift rewrite maintains API compatibility. Most Objective-C code will continue to work. For Swift projects:

| Old API (Obj-C) | New API (Swift) |
|-----------------|-----------------|
| `[imageView setImageWithURL:url placeholder:placeholder]` | `imageView.setImage(with: url, placeholder: placeholder)` |
| `[[JMImageCache sharedCache] imageForURL:url completionBlock:^...]` | `try await JMImageCache.shared.image(for: url)` |
| `[[JMImageCache sharedCache] cachedImageForURL:url]` | `JMImageCache.shared.cachedImage(for: url)` |
| `[[JMImageCache sharedCache] removeAllObjects]` | `JMImageCache.shared.removeAllImages()` |

## Error Handling

```swift
do {
    let image = try await JMImageCache.shared.image(for: url)
} catch JMImageCacheError.invalidResponse(let response) {
    // Server returned an error
} catch JMImageCacheError.invalidImageData {
    // Data couldn't be converted to an image
} catch {
    // Other error
}
```

## Thread Safety

All JMImageCache operations are thread-safe:

- Memory cache operations are synchronized via NSCache
- Disk operations run on a dedicated serial queue
- Completion handlers and async results are always delivered on the main thread

## Demo App

The repository includes a demo project showing typical usage in a `UITableViewController` with image loading.

## License

JMImageCache is available under the MIT license. See the LICENSE file for details.

## Author

Jake Marsh ([@jakemarsh](https://twitter.com/jakemarsh))

Originally created in 2011, rewritten in Swift with async/await in 2024.
