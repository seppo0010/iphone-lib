#import "HTTPRequestAsyncronic.h"
//#import "Main.h"
//#import "Config.h"

@implementation HTTPRequestAsyncronic

static NSMutableArray* pendingRequests;

+ (int)getPendingRequests {
	return [pendingRequests count];
}

- (void) requestUrl:(NSURL*)URL {
	url = [[URL absoluteString] retain];
	if (HTTP_DEBUG) {
		NSLog(@"%@", [URL absoluteString]);
		if (![NSThread isMainThread]) NSLog(@"Calling %@ in a secondary thread!", url);
	}
	
	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInterval > 0 ? timeoutInterval : [self getDefaultTimeout]] autorelease];

	if (!filename) self.filename = [[URL absoluteString] lastPathComponent];

	NSData* _postData = [self getPostData];
	int postBodyLength = [_postData length];
	if (postBodyLength > 0)
	{
		if ([postFiles count] > 0) 
			[request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:_postData];
		[request setHTTPMethod:@"POST"];
	}
	
	if (!pendingRequests) 
		pendingRequests = [[NSMutableArray alloc] initWithCapacity:0];
	
	
	[pendingRequests addObject:self];
	connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	loadedData = [[NSMutableData alloc] initWithCapacity:0];
		
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.httpResponse = (NSHTTPURLResponse*)response;
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	[loadedData appendData:data];
}

- (void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error {
	if (HTTP_DEBUG) {
		NSLog(@"Fail connection to %@", [_connection description] );
		NSLog(@"%@", [error description]);
	}
	[self callFailure];
//	if ([error code] == -1001 || [error code] == -1009) { }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self callSuccess];
}

- (void) callSuccess {
	[super callSuccess];
	[pendingRequests removeObject:self];
}

- (void) dealloc {
	[connection cancel];
	[connection release];
	[super dealloc];
}

- (void) cancel {
	[connection cancel];
	[connection release];
	connection = nil;

	[loadedData release];
	loadedData = nil;
}

- (void) callFailure 
{
	[super callFailure];
	[pendingRequests removeObject:self];
}

@end
