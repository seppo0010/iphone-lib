#import "HTTPRequest.h"
#import "HTTPRequestSyncronic.h"
#import "HTTPRequestAsyncronic.h"
#import "NSObjectClassName.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

@implementation HTTPRequest

@synthesize callbackObject, successSelector, failureSelector, timeoutInterval, httpResponse,filename, boundary, url;

+ (HTTPRequest*) requestURL:(NSURL*)url andCallSelector:(SEL)selector inObject:(id)obj {
	HTTPRequest* request = [[[self alloc] init] autorelease];
	request.callbackObject = obj;
	request.failureSelector = selector;
	request.successSelector = selector;
	request.filename = [[[url absoluteString] componentsSeparatedByString:@"/"] lastObject];
	[request requestUrl:url];
	return request;
}

+ (HTTPRequest*) requestURL:(NSURL*)url withParams:(NSDictionary*)_params andCallSelector:(SEL)selector inObject:(id)obj {
	HTTPRequest* request = [[[self alloc] init] autorelease];
	request.callbackObject = obj;
	request.failureSelector = selector;
	request.successSelector = selector;
	request.filename = [[[url absoluteString] componentsSeparatedByString:@"/"] lastObject];
	[request addParameters:_params];
	[request requestUrl:url];
	return request;
}

+ (HTTPRequest*) requestURL:(NSURL*)url useSyncronic:(BOOL)_sync andCallSelector:(SEL)selector inObject:(id)obj {
	HTTPRequest* request;
	if (_sync)
		request = [[[HTTPRequestSyncronic alloc] init] autorelease];
	else
		request = [[[HTTPRequestAsyncronic alloc] init] autorelease];
	request.callbackObject = obj;
	request.failureSelector = selector;
	request.successSelector = selector;
	request.filename = [[[url absoluteString] componentsSeparatedByString:@"/"] lastObject];
	[request requestUrl:url];
	return request;
}


+ (HTTPRequest*) requestURL:(NSURL*)url useSyncronic:(BOOL)_sync andCallSucessSelector:(SEL)_successSelector andCallFailureSelector:(SEL)_failureSelector inObject:(id)obj {
	HTTPRequest* request;
	if (_sync)
		request = [[[HTTPRequestSyncronic alloc] init] autorelease];
	else
		request = [[[HTTPRequestAsyncronic alloc] init] autorelease];
	request.callbackObject = obj;
	request.failureSelector = _failureSelector;
	request.successSelector = _successSelector;
	request.filename = [[[url absoluteString] componentsSeparatedByString:@"/"] lastObject];
	[request requestUrl:url];
	return request;
}

- (void) requestUrl:(NSURL*)URL {
	if (HTTP_DEBUG) NSLog(@"Child of HTTPRequest must implement requestUrl: method");
}

- (void)setPostData:(NSString*)_postData {
	if (HTTP_DEBUG && postParameters)
		NSLog(@"Using of post data having a dictionary on a http request will be useless");
	
	[_postData retain];
	[postData release];
	postData = _postData;
}

- (void) addParameter:(NSString*)key withValue:(id)value {
	if (HTTP_DEBUG && postData)
		NSLog(@"Using of dictionary on a http request will override post data");
	
	if (!postParameters)
		postParameters = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	if ([value isKindOfClass:[NSString class]])
	{
		[postParameters setValue:value forKey:key];
	} else if (HTTP_DEBUG) {
		NSLog(@"Unsoported post parameter type: '%@'", [value className]);
	}
}

- (void) addParameters:(NSDictionary*)parameters {
	if (!postParameters)
		postParameters = [[NSMutableDictionary alloc] initWithCapacity:0];
	[postParameters addEntriesFromDictionary:parameters];
}

- (NSData*) getPostData {
	NSData* files = [self getAttachedFiles];
	if (files) {
		return files;
	} else if (postParameters)
	{
		NSMutableString* _postData = [NSMutableString string];
		
		NSArray* keys = [postParameters allKeys];
		for (int i = 0; i < [keys count]; i++) {
			NSString* key = [keys objectAtIndex:i];
			[_postData appendFormat:@"%@=%@", key, [[[[postParameters valueForKey:key] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding] stringByReplacingOccurrencesOfString:@"&" withString:@"%26"] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]];
			if (i < [keys count] - 1)
				[_postData appendString:@"&"];
		}
		
		return [_postData dataUsingEncoding:NSUTF8StringEncoding];
	} else if (postData) {
		return [[[postData stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding] stringByReplacingOccurrencesOfString:@"&" withString:@"%26"] dataUsingEncoding:NSUTF8StringEncoding];
	} else {
		return nil;
	}
}

- (NSData*) getAttachedFiles{
	if(postFiles){
		NSMutableData* data = [[NSMutableData alloc] init];
		if(!boundary)
			boundary = @"---------------------------14737809831466499882746641449";
		NSArray* keys = [postFiles allKeys];
		for (int i = 0; i < [keys count]; i++) {
			NSString* key = [keys objectAtIndex:i];
			NSDictionary* file = [postFiles objectForKey:key];
			[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			[data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",[file objectForKey:@"parameterName"],[file objectForKey:@"fileName"]] dataUsingEncoding:NSUTF8StringEncoding]];
			[data appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n",[file objectForKey:@"contentType"]] dataUsingEncoding:NSUTF8StringEncoding]];
			[data appendData:[file objectForKey:@"fileData"]];
			[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		}
			keys = [postParameters allKeys];
			for (int i = 0; i < [keys count]; i++) {
				NSString* key = [keys objectAtIndex:i];
				[data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", key, [postParameters valueForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
				[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			}
		
		[data appendData:[@"--" dataUsingEncoding:NSUTF8StringEncoding]];
		NSData* returnData = [[[NSData alloc] initWithData:data] autorelease];;
		[data release];
		return returnData;
	} else {
		return nil;
	}
}

- (void) addFileWithParameterName:(NSString*)_parameterName fileName:(NSString*)_fileName fileData:(NSData*)_data andContentType:(NSString*)_contentType{
	if(!postFiles)
		postFiles = [[NSMutableDictionary alloc]init];
		
	NSDictionary* file = [NSDictionary dictionaryWithObjectsAndKeys:_parameterName,@"parameterName",_fileName,@"fileName",
																	_data,@"fileData",_contentType,@"contentType",nil];
	[postFiles setObject:file forKey:_fileName];
}

- (int) getDefaultTimeout
{
	struct sockaddr_in zeroAddr;
	bzero(&zeroAddr, sizeof(zeroAddr));
	zeroAddr.sin_len = sizeof(zeroAddr);
	zeroAddr.sin_family = AF_INET;
	
	int _timeout = DEFAULT_TIMEOUT;
	// Part 2- Create target in format need by SCNetwork
	SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddr);
	
	// Part 3 - Get the flags
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(target, &flags);
	
	if (flags & kSCNetworkReachabilityFlagsIsWWAN)
		_timeout = EDGE_3G_TIMEOUT;
	CFRelease(target);

	return _timeout;
}

- (void) dealloc {
	self.callbackObject = nil;
	[postData release];
	[postParameters release];
	[url release];
	[filename release];
	[httpResponse release];
	[loadedData release];;
	[super dealloc];
}

- (void) setHttpResponse:(NSHTTPURLResponse*)_response {
	[httpResponse release];
	[_response retain];
	httpResponse = _response;

	int status = [httpResponse statusCode];
	if (status < 200 || status >= 300) {
		if (HTTP_DEBUG) NSLog(@"Failed receiving status %d", status);
		[self callFailure];
	}
}

- (NSData*) data {
	return (NSData*)loadedData;
}

- (void) callSuccess {
	if (successSelector && callbackObject) {
		[callbackObject performSelector:successSelector withObject:self];
		callbackObject = nil;
		successSelector = nil;
	}
}

- (void) callFailure  {
	if (failureSelector) {
		[callbackObject performSelector:failureSelector withObject:self];
		callbackObject = nil;
		failureSelector = nil;
	}
}



@end
