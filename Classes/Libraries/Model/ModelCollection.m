//
//  ModelCollection.m
//  circle_of_moms
//
//  Created by Sebastian Waisbrot on 9/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ModelCollection.h"
#import "NSMutableSetNonRetain.h"
#import "JSONHTTPRequest.h"

@implementation ModelCollection

@synthesize models, modelSubclass;

- (void) addObserver:(id<ModelCollectionObserver>)_observer {
	if (!observers) observers = [[NSMutableSet setNonRetaining] retain];
	[observers addObject:_observer];
	[_observer performSelector:@selector(modelCollectionHasChanged:) withObject:self];
}

- (void) removeObserver:(id<ModelCollectionObserver>)_observer {
	[observers removeObject:_observer];
}

- (void) removeAllObservers {
	[observers release];
	observers = nil;
}

- (void) setModels:(NSArray*)_models {
	[models release];
	models = [_models retain];
	[observers makeObjectsPerformSelector:@selector(modelCollectionHasChanged:) withObject:self];
}

- (void)setCollectionFromRequest:(JSONHTTPRequest*)request {
	[self removeRequest:request];
	id response = request.response;
	//id response = [request.response valueForKey:@"Kid"];
	if ([response isKindOfClass:[NSDictionary class]]) {
		self.models = [NSArray arrayWithObject:[[[modelSubclass alloc] initWithDictionary:response] autorelease]];
	} else if ([response isKindOfClass:[NSArray class]]) {
		NSMutableArray* array = [NSMutableArray arrayWithCapacity:[response count]];
		for (int i = 0; i < [response count]; i++) {
			[array addObject:[[[modelSubclass alloc] initWithDictionary:[response objectAtIndex:i]] autorelease]];
		}
		self.models = [NSArray arrayWithArray:array];
	} else if ([response isKindOfClass:[NSArray class]]) {
		
	}	
}

- (void) addRequest:(HTTPRequest*)_request {
	if (!requests) requests = [[NSMutableSet setNonRetaining] retain];;
	[requests addObject:_request];
}

- (void) removeRequest:(HTTPRequest*)_request {
	[requests removeObject:_request];
}

- (void) dealloc {
	[requests makeObjectsPerformSelector:@selector(cancel)];
	[requests release];
	[super dealloc];
}

- (NSString*) description {
	return [models description];
}

@end