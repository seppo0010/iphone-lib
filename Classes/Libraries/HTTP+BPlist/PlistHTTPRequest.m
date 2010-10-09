//
//  PlistHTTPRequest.m
//  Project
//
//  Created by Seppo on 28/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlistHTTPRequest.h"


@implementation PlistHTTPRequest

@synthesize response;

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSPropertyListFormat format;
	self.response = [NSPropertyListSerialization propertyListFromData:loadedData
													 mutabilityOption:NSPropertyListImmutable
															   format:&format
													 errorDescription:nil];
	
	[self callSuccess];
}

- (void) dealloc {
	self.response = nil;
	[super dealloc];
}

@end
