#import "HTTPRequestSyncronic.h"

@implementation HTTPRequestSyncronic

- (void) requestUrl:(NSURL*)URL {
	if (HTTP_DEBUG) NSLog(@"%@", [URL absoluteString]);
	url = [[URL absoluteString] retain];
	if (HTTP_DEBUG && ![NSThread isMainThread]) {
		NSLog(@"WARNING! Making a syncronic URL request from a thread different to the main thread! Probably leaking....");
	}
	NSHTTPURLResponse* response;
	
	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInterval > 0 ? timeoutInterval : [self getDefaultTimeout]] autorelease];
	NSData* _postData = [self getPostData];
	int postBodyLength = [_postData length];
	if (postBodyLength > 0)
	{
		if ([postFiles count] > 0) [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:_postData];
		[request setHTTPMethod:@"POST"];
	}
	
	NSError* connError = nil;
	loadedData = [[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connError] retain];
	self.httpResponse = response;
	if (connError || response.statusCode != 200) 
	{
		if (HTTP_DEBUG) NSLog(@"Fail sync connection to %@ code: %d", [connError description], [connError code]);
//		if ([connError code] == -1001) //time out
		[self callFailure];
	} else {
		[self callSuccess];
	}
}

@end
