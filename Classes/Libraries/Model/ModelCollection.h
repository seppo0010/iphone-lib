//
//  ModelCollection.h
//  circle_of_moms
//
//  Created by Sebastian Waisbrot on 9/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModelCollectionObserver.h"

@class HTTPRequest, JSONHTTPRequest;
@interface ModelCollection : NSObject {
	NSArray* models;
	NSMutableSet* observers;
	Class modelSubclass;
	NSMutableSet* requests;
}

/**
 * The collection of models
 */
@property (retain) NSArray* models;
/**
 * The subclass of model to use when receiving new information.
 */
@property Class modelSubclass;

/**
 * Adds a new observer to notify when the collection changes.
 * This observer is NOT retained by this class. If it gets dealloc'ed it should remove itself from this list.
 */
- (void) addObserver:(id<ModelCollectionObserver>)_observer;
/**
 * Removes an observer from the list.
 */
- (void) removeObserver:(id<ModelCollectionObserver>)_observer;
/**
 * Removes all observers.
 */
- (void) removeAllObservers;
/**
 * Stores a request reference. Useful to cancel when dealloc'ing.
 * @protected
 */
- (void) addRequest:(HTTPRequest*)_request;
/**
 * Remove a request reference.
 * @protected
 */
- (void) removeRequest:(HTTPRequest*)_request;
/**
 * Utility method to set the information from a JSON request. It should return a JSON array of JSON objects matching the properties the class have.
 * @protected
 */
- (void)setCollectionFromRequest:(JSONHTTPRequest*)request;

@end