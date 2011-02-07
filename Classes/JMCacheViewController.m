//
//  JMCacheViewController.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import "JMCacheViewController.h"
#import "JMImageTableViewCell.h"

@implementation JMCacheViewController

- (id) init {
	if(self = [super init]) {
		_imageCache = [[JMImageCache alloc] init];
		_imageCache.imageCacheDelegate = self;
		_flickrImageDictionaries = [[NSMutableArray alloc] init];

		[_flickrImageDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4QX0/Screen_shot_2011-02-07_at_3.06.45_PM.png", @"ImageURL", @"Cat 1", @"Title", nil]];
		[_flickrImageDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4R4R/Screen_shot_2011-02-07_at_3.09.52_PM.png", @"ImageURL", @"Cat 2", @"Title", nil]];
		[_flickrImageDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4QoY/Screen_shot_2011-02-07_at_3.20.41_PM.png", @"ImageURL", @"Cat 3", @"Title", nil]];
	}

	return self;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_flickrImageDictionaries count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	JMImageTableViewCell *cell = (JMImageTableViewCell* )[tableView dequeueReusableCellWithIdentifier:@"JMImageTableViewCell"];
	if(cell == nil) {
		cell = [[[JMImageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"JMImageTableViewCell"] autorelease];
	}

	cell.imageURL = [[_flickrImageDictionaries objectAtIndex:indexPath.row] objectForKey:@"ImageURL"];
	cell.imageView.image = [_imageCache imageForURL:cell.imageURL];
	cell.textLabel.text = [[_flickrImageDictionaries objectAtIndex:indexPath.row] objectForKey:@"Title"];

	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 90.0;
}

#pragma mark -
#pragma mark JMImageCacheDelegate Methods

- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSString *)url {
	NSLog(@"didDownloadImage for URL = %@", url);

	for (UIView *view in self.tableView.subviews) {
		if([[view class] isSubclassOfClass:[UITableViewCell class]]) {
			if([[(JMImageTableViewCell *)view imageURL] isEqualToString:url]) {
				((JMImageTableViewCell *)view).imageView.image = i;

				[((JMImageTableViewCell *)view) setNeedsDisplay];
			}
		}
	}	
}

#pragma mark -
#pragma mark Cleanup Methods

- (void) didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}
- (void) viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}
- (void) dealloc {
	_imageCache.imageCacheDelegate = nil;
	[_imageCache release]; _imageCache = nil;

	[_flickrImageDictionaries release]; _flickrImageDictionaries = nil;

	[super dealloc];
}

@end