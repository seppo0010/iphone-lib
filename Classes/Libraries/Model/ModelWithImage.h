//
//  ModelWithImage.h
//  Project
//
//  Created by GoNXaS on 11/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"
#import "HTTPRequestAsyncronic.h"

@interface ModelWithImage : Model {
	UIImage* pic;
	NSString* picurl;
	HTTPRequestAsyncronic* request;
}

@property (retain) UIImage* pic;
@property (retain) NSString* picurl;


- (NSDictionary*) imagesProperties;
- (void) requestImage:(NSString*) url;
- (void) loadImages;

@end
