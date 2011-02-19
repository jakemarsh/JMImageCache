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
		self.title = @"The Office";

		_imagesToLoad = [[NSMutableArray alloc] init];

		[_imagesToLoad addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hCR/Untitled-7.png", @"ImageURL", @"Michael Scott", @"Title", nil]];
		[_imagesToLoad addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4iIc/Untitled-7.png", @"ImageURL", @"Jim Halpert", @"Title", nil]];
		[_imagesToLoad addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hVv/Untitled-7.png", @"ImageURL", @"Pam Beasley-Halpert", @"Title", nil]];
		[_imagesToLoad addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hF3/Untitled-7.png", @"ImageURL", @"Dwight Schrute", @"Title", nil]];
		[_imagesToLoad addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hxj/Untitled-7.png", @"ImageURL", @"Andy Bernard", @"Title", nil]];
		[_imagesToLoad addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4iNI/Untitled-7.png", @"ImageURL", @"Kevin Malone", @"Title", nil]];
		[_imagesToLoad addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4iAX/Untitled-7.png", @"ImageURL", @"Stanley Hudson", @"Title", nil]];
	}

	return self;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_imagesToLoad count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	JMImageTableViewCell *cell = (JMImageTableViewCell* )[tableView dequeueReusableCellWithIdentifier:@"JMImageTableViewCell"];
	if(cell == nil) cell = [[[JMImageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"JMImageTableViewCell"] autorelease];

	NSString *imageURL = [[_imagesToLoad objectAtIndex:indexPath.row] objectForKey:@"ImageURL"];
	cell.imageView.image = [[JMImageCache sharedCache] imageForURL:imageURL delegate:cell];

	cell.textLabel.text = [[_imagesToLoad objectAtIndex:indexPath.row] objectForKey:@"Title"];

	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 90.0;
}
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Autorotation Methods

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark -
#pragma mark Cleanup Methods

- (void) didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}
- (void) dealloc {
	[_imagesToLoad release]; _imagesToLoad = nil;

	[super dealloc];
}

@end