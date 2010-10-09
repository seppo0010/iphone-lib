//
//  PlistHTTPRequest.h
//  Project
//
//  Created by Seppo on 28/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPRequestAsyncronic.h"

@interface PlistHTTPRequest : HTTPRequestAsyncronic {
	id response;
}
/**
 * The parsed response. It might be a NSDictionary, NSArray, NSString, NSNumber or NSNull.
 */
@property (retain) id response;


@end
