//
//  Config.h
//  iMom
//
//  Created by Usuario on 19/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CONFIG_BASE_URL @"http://209.216.55.236/web/ws/api.php"
//#define CONFIG_BASE_URL @"http://hq.delapalo.net/~sebastianw/response/"
#define FB_KEY @""
#define FB_SECRET_KEY @""

@interface Config : NSObject {
	
}

+ (Config*)getInstance;
- (NSURL*) URLWithString:(NSString*)_string;
	
@end
