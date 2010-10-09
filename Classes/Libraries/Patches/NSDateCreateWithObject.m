@implementation NSDate (createWithObject)
+ (NSDate*) createWithObject:(id)_date {
	if ([_date isKindOfClass:[NSDate class]]) {
		return _date;
	} else if ([_date isKindOfClass:[NSNumber class]] || ([_date isKindOfClass:[NSString class]])) {
		return [NSDate dateWithTimeIntervalSinceNow:[_date intValue]];
	} else if (_date != nil && ![_date isKindOfClass:[NSNull class]]) {
		[NSException raise:@"Invalid date" format:@"Attempt to create a date with invalid parameter of class \"%@\"", [_date class]];
	}
	return nil;
}

@end