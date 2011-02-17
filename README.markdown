JMImageCache
=============

Introduction
---

`JMImageCache` is my attempt at an `NSCache` based remote-image caching mechanism for iOS projects.


How It Works (Logically)
---

There are three states an image can be in:

*  Cached In Memory
*  Cached On Disk
*  Not Cached
	
If an image is requested from cache, and it has never been cached, it is downloaded, stored on disk, put into memory and returned via a delegate callback.

If an image is requested from cache, and it has been cached, but hasn't been requested this session, it is read from disk, brought into memory and returned immediately.

If an image is requested from cache, and it has been cached and it is already in memory, it is simply returned immediately.

The idea behind `JMImageCache` is to always return images the **fastest** way possible, thus the in-memory caching. Reading from disk can be expensive, and should only be done if it has to be.

How It Works (Code)
---

Initialize and hang on to a reference to a `JMImageCache` object:

	JMImageCache *_imageCache = [[JMImageCache alloc] init];
	
Set the `imageCacheDelegate` to something that makes sense:

	_imageCache.imageCacheDelegate = self;
	
Request an image like so

	UIImage *catsRule = [_imageCache imageForURL:@"http://lolcats.com/DogsDrool.png"];
	
`imageForURL:` will return either a `UIImage` object, or `nil`. If it returns `nil`, then that means the image needs to be downloaded.

If the image needs to be downloaded, you'll be notified via a callback to the `imageCacheDelegate` object you set previously:

	- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSString *)url {
		NSLog(@"Downloaded (And Cached) Image From URL: %@", url);
	}

Once you're done with it, make sure you cleanup things nicely - (most likely in `- (void) dealloc`):

	_imageCache.imageCacheDelegate = nil;
	[_imageCache release]; _imageCache = nil;
	
Clearing The Cache
---

The beauty of building on top of `NSCache` is that` JMImageCache` handles low memory situations gracefully. It will evict objects on its own when memory gets tight, you don't need to worry about it.

However, if you really need to, clearing the cache manually is this simple:
	
	[_imageCache removeAllObjects];
	
If you'd like to remove a specific image from the cache, you can do this:

	[_imageCache removeImageForURL:@"http://lolcats.com/DogsDrool.png"];

Demo App
---

This repo is actually a demo project itself. Just a simple `UITableViewController` that loads a few images from Flickr. Nothing too fancy, but it should give you a good idea of a standard usage of `JMImageCache`.

Using `JMImageCache` In Your App
---

All you need to do is copy `JMImageCache.h` and `JMImageCache.m` into your project, `#import` the header where you need it, and start using it.

Notes
---

`JMImageCache` purposefully uses `NSString` objects instead of `NSURL`'s to make things easier and cut down on `[NSURL URLWithString:@"..."]` bits everywhere. Just something to notice in case you see any strange `EXC_BAD_ACCESS` exceptions, make sure you're passing in `NSString`'s and not `NSURL`'s.