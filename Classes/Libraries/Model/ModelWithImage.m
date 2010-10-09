//
//  ModelWithImage.m
//  circle_of_moms
//
//  Created by GoNXaS on 11/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ModelWithImage.h"
#import "HTTPRequestSyncronic.h"
#import "Config.h"


@implementation ModelWithImage

@synthesize pic, picurl;

- (void) loadImages {
	NSArray* imagesURLS = [[self imagesProperties] allKeys];
	for (NSString* url in imagesURLS) {
		SEL selector = sel_getUid((const char*)[url UTF8String]);
		[self requestImage:[self performSelector:selector]];
	}
}

- (void) requestImage:(NSString*) url {
	if(url){
		Config* conf = [[[Config alloc] init]autorelease];
		request = [[HTTPRequestAsyncronic requestURL:[conf URLWithString:url] andCallSelector:@selector(setImageFromRequest:) inObject:self] retain];
	}
}

- (void) setImageFromRequest:(HTTPRequestAsyncronic*)_request {
	NSString* key = nil;
	Config* conf = [[[Config alloc] init]autorelease];
	NSArray* imagesURLS = [[self imagesProperties] allKeys];
	for (NSString* url in imagesURLS) {
		SEL selector = sel_getUid((const char*)[url UTF8String]);
		if ([[[conf URLWithString:[self performSelector:selector]]absoluteString] isEqualToString:request.url]) {
			key = [[self imagesProperties]objectForKey:url];
			break;
		}
	}
	if (key == nil) return;
	NSLog([NSString stringWithFormat:@"set%@%@:", [[key substringToIndex:1] capitalizedString], [key substringFromIndex:1]]);
	const char* selectorName = (const char *)[[NSString stringWithFormat:@"set%@%@:", [[key substringToIndex:1] capitalizedString], [key substringFromIndex:1]] UTF8String];
	NSLog([[NSString alloc] initWithCString:selectorName]);
	SEL selector = sel_getUid(selectorName);
	[self performSelector:selector withObject:[UIImage imageWithData:request.data]];
	[observers makeObjectsPerformSelector:@selector(modelHasChanged:) withObject:self];
	[request release];
	request = nil;
}

- (NSDictionary*) imagesProperties {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"pic", @"picurl", nil];
	NSLog(@"Child of ModelWithImage must override imagesProperties method");
}

- (void) dealloc {
	[request cancel];
	[request release];
	[super dealloc];
}

@end
