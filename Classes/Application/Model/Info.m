//
//  Info.m
//  Project
//
//  Created by Usuario on 28/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Info.h"

@implementation Info

@synthesize info_id, name, big_number, value, other_value, some_number, flag;

+ (Database*) getDelegate {
	return [Database getInstance];
}

@end
