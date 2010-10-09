//
//  Config.m
//  iMom
//
//  Created by Usuario on 19/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Config.h"


@implementation Config

static Config* instance;

+ (Config*)getInstance {
	@synchronized(self) {
		if (!instance)
			instance = [[Config alloc] init];
		return instance;
	}
	return nil;
}

- (NSURL*) URLWithString:(NSString*)_string {
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", CONFIG_BASE_URL, _string]];
}

@end
