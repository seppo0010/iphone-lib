//
//  Info.h
//  Project
//
//  Created by Usuario on 28/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"
#import "Database.h"

@interface Info : Model {
	int info_id;
	NSString* name;
	long long unsigned big_number;
	double value;
	float other_value;
	int some_number;
	BOOL flag;
}

@property int info_id;
@property (retain) NSString* name;
@property long long unsigned big_number;
@property double value;
@property float other_value;
@property int some_number;
@property BOOL flag;

@end
