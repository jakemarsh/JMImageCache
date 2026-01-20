//
//  JMImageCacheOperation.m
//  JMCache
//
//  Created by Rodrigo Garcia on 7/10/13.
//
//

#import "JMImageCacheOperation.h"

static inline NSString *JMImageCacheDirectory() {
	static NSString *_JMImageCacheDirectory;
	static dispatch_once_t onceToken;
    
	dispatch_once(&onceToken, ^{
		_JMImageCacheDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/JMCache"] copy];
	});
    
	return _JMImageCacheDirectory;
}
inline static NSString *keyForURL(NSURL *url) {
	return [url absoluteString];
}
static inline NSString *cachePathForKey(NSString *key) {
    NSString *fileName = [NSString stringWithFormat:@"JMImageCache-%u", [key hash]];
	return [JMImageCacheDirectory() stringByAppendingPathComponent:fileName];
}


@interface JMImageCacheOperation ()

@property(copy,nonatomic) NSURL *url;
@property(strong,nonatomic) UIImage *imageOperation;
@property(strong,nonatomic) NSData *dataRepresentation;

@end

@implementation JMImageCacheOperation

-(id)initWithURL:(NSURL *)aURL aSuccessBlock:(JMImageCacheSuccessBlock)aSuccessBlock andFailedBlock:(JMImageCacheFailedBlock)aFailedBlock
{
    if(self=[super init])
    {
        self.url = aURL;
        self.successBlock = aSuccessBlock;
        self.failedBlock = aFailedBlock;
    }
    
    return self;
}

-(void)main
{
    [self downloadImage];
    NSString *cachePath = cachePathForKey(self.url.absoluteString);
    [self writeData:self.dataRepresentation toPath:cachePath];
    
    if (!self.isCancelled && self.imageOperation)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.successBlock) self.successBlock(self.imageOperation);
        });
    }
}


- (void)downloadImage
{
        NSURLRequest* request = [NSURLRequest requestWithURL:self.url];
        NSURLResponse* response = nil;
        NSError* error = nil;
        self.dataRepresentation = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(self.failedBlock)  self.failedBlock(request, response, error);
            });
            return;
        }
        
        self.imageOperation = [[UIImage alloc] initWithData:self.dataRepresentation];
    
        if (!self.imageOperation)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:[NSString stringWithFormat:@"Failed to init image with data from for URL: %@", self.url] forKey:NSLocalizedDescriptionKey];
            NSError* error = [NSError errorWithDomain:@"JMImageCacheErrorDomain" code:1 userInfo:errorDetail];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(self.failedBlock) self.failedBlock(request, response, error);
            });
        }
}


- (void)writeData:(NSData*)data toPath:(NSString *)path {
	[data writeToFile:path atomically:YES];
    NSString *cacheName = @"memory-cache";
    
    NSDictionary *properties = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    NSNumber *actualCacheSize = [[NSUserDefaults standardUserDefaults] objectForKey:cacheName];
    NSNumber *fileSize = [NSNumber numberWithUnsignedLong:([properties fileSize] + actualCacheSize.longValue)];
    
    [[NSUserDefaults standardUserDefaults] setObject:fileSize  forKey:cacheName];
    
}

-(BOOL)isConcurrent
{
    return YES;
}

@end
