#import <UIKit/UIKit.h>
#import "HTTPRequest.h"

@interface HTTPRequestAsyncronic : HTTPRequest {
	NSURLConnection* connection;
}

/**
 * The number of asyncronic requests in curse.
 * @return int
 */
+ (int)getPendingRequests;
/**
 * Cancels the request. The failure callback is not called.
 */
- (void)cancel;

@end
