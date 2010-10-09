#import <UIKit/UIKit.h>

#define DEFAULT_TIMEOUT 20
#define EDGE_3G_TIMEOUT 60
#define HTTP_DEBUG 1

/**
 * @abstract
 */
@interface HTTPRequest : NSObject {
	id callbackObject;
	SEL successSelector;
	SEL failureSelector;
	int timeoutInterval;

	NSMutableDictionary* postFiles;
	NSMutableDictionary* postParameters;
	NSString* postData;
	NSString* url;
	NSString* filename;
	NSString* boundary;

	NSHTTPURLResponse *httpResponse;
	NSMutableData* loadedData;
}

/**
 * Create a new request and instantly starts the HTTP.
 * The selector received will be called in case of success or failure.
 * @param url         the URL to be called
 * @param selector    the method to be called when the request finishes
 * @param obj         the object to call when the request finishes
 * @return            the request performed
 */
+ (HTTPRequest*) requestURL:(NSURL*)url andCallSelector:(SEL)selector inObject:(id)obj;

/**
 * Create a new request and instantly starts the HTTP.
 * The selector received will be called in case of success or failure.
 * The params will be sent as HTTP post body
 * @param url         the URL to be called
 * @param selector    the method to be called when the request finishes
 * @param obj         the object to call when the request finishes
 * @return            the request performed
 */
+ (HTTPRequest*) requestURL:(NSURL*)url withParams:(NSDictionary*)_params andCallSelector:(SEL)selector inObject:(id)obj;

/**
 * Performs the request to the given url.
 * All the request info should be set before.
 * @param url         the URL to be called
 */
- (void) requestUrl:(NSURL*)URL;

/**
 * Sets the post body. Calling this method will make any key-value parameter get ignored.
 * @param _postData   the post body
 */
- (void) setPostData:(NSString*)_postData;

/**
 * Adds a new key to the post body.
 * Calling two times this method with the same key, will override the first value.
 * @param key         the key to add
 * @param value       the value for the given key.
 */
- (void) addParameter:(NSString*)key withValue:(id)value;

/**
 * Adds several key-value to the post body.
 * Calling two times this method with the same key, will override the first value.
 * @param parameters  the parameters to add
 */
- (void) addParameters:(NSDictionary*)parameters;

/**
 * Process the post body parameters set and return the data to send to the server.
 * @protected
 * @return the binary to send to the server
 */
- (NSData*) getPostData;
/**
 * Request timeout in seconds.
 * @protected
 */
- (int) getDefaultTimeout;
/**
 * Performs the success callback. Also clean-ups the callbacks to avoid double messaging.
 * @protected
 */
- (void) callSuccess;
/**
 * Performs the failure callback. Also clean-ups the callbacks to avoid double messaging.
 * @protected
 */
- (void) callFailure;
/**
 * Create the HTTP multipart/form-data binary of the files added to the request.
 * @protected
 */
- (NSData*) getAttachedFiles;
/**
 * Adds a new file to the request.
 * @param parameterName  the key of the file request
 * @param fileName       the file name to send to the server
 * @param data           the binary content of the file
 * @param contentType    the mime type (e.g.: image/jpeg)
 */
- (void) addFileWithParameterName:(NSString*)_parameterName fileName:(NSString*)_fileName fileData:(NSData*)_data andContentType:(NSString*)_contentType;

/**
 * The object to call when the request finishes.
 */
@property (assign) id callbackObject;
/**
 * Method to call when the request finishes if success.
 */
@property SEL successSelector;
/**
 * Method to call when the request finishes if failes (includes timeout, 4xx and 5xx status, no internet connection).
 */
@property SEL failureSelector;
/**
 * Timeout to use for the request. This can be used to override the default timeout.
 */
@property int timeoutInterval;
/**
 * The server response body.
 */
@property (readonly) NSData* data;
/**
 * The server response (includes status, headers, etc).
 */
@property (retain) NSHTTPURLResponse *httpResponse;
/**
 * The name of the requested file in the server.
 */
@property (retain) NSString *filename;
/**
 * Boundary to separate the fields on multipart/form-data requests.
 * @protected
 */
@property (retain) NSString* boundary;
/**
 * The requested url.
 */
@property (readonly) NSString* url;

@end
