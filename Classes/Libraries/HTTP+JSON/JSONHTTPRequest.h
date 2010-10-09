//
//  JSONHTTPRequest.h
//  iMom
//
//  Created by Sebastian Waisbrot on 8/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPRequestAsyncronic.h"

@interface JSONHTTPRequest : HTTPRequestAsyncronic {
	id response;
}
/**
 * The json parsed response. It might be a NSDictionary, NSArray, NSString, NSNumber or NSNull.
 */
@property (retain) id response;

@end
