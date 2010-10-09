#import <UIKit/UIKit.h>
#import "ModelObserver.h"
#import "ModelDelegate.h"

@class ModelCollection, HTTPRequest;
/**
 * @abstract
 */
@interface Model : NSObject <NSCoding> {
	NSMutableSet* observers;
	NSMutableSet* requests;
}

/**
 * Creates a new model and assigns all the dictionary keys to the corresponding properties.
 * @params dictionary     the dictionary to assign to the model properties.
 * @return Model*         the new instance with the assigned properties.
 */
- (Model*) initWithDictionary:(NSDictionary*)dictionary;
/**
 * Sets the properties from the dictionary keys.
 * @params dictionary     the dictionary to assign to the model properties.
 * @return Model*         the instance with the assigned properties.
 */
- (Model*) setDictionary:(NSDictionary*)dictionary;
/**
 * Fetches an array with all the stored objects of this class.
 * @return NSArray*        the matched model list.
 */
+ (NSArray*) fetchList;
/**
 * Fetches an array with all the stored objects of this class that matches the given filters.
 * @params filters         a key value set of filters. The key is associated with the property and the filter value must match the object value.
 * @return NSArray*        the matched model list.
 */
+ (NSArray*) find:(NSDictionary*)_filters;
/**
 * Fetches an array with all the stored objects of this class that matches the given filters sorted by a filter.
 * @params filters         a key value set of filters. The key is associated with the property and the filter value must match the object value.
 * @params order_by        the key to use for sorting.
 * @return NSArray*        the matched model list.
 */
+ (NSArray*) find:(NSDictionary*)_filters orderBy:(NSString*)orderBy;
/**
 * Fetches an array with all the stored objects of this class that matches the given filters sorted by a filter.
 * @params filters         a key value set of filters. The key is associated with the property and the filter value must match the object value.
 * @params order_by        the key to use for sorting.
 * @params limit           maximum number of results
 * @return NSArray*        the matched model list.
 */
+ (NSArray*) find:(NSDictionary*)_filters orderBy:(NSString*)orderBy limit:(int)_limit;
/**
 * Fetches an array with all the stored objects of this class that matches the given filters sorted by a filter.
 * @params filters         a key value set of filters. The key is associated with the property and the filter value must match the object value.
 * @params order_by        the key to use for sorting.
 * @params limit           maximum number of results
 * @params limit           offset to start the list
 * @return NSArray*        the matched model list.
 */
+ (NSArray*) find:(NSDictionary*)_filters orderBy:(NSString*)orderBy limit:(int)_limit offset:(int) _offset;
/**
 * Fetches an objects of this class that matches the given filters.
 * @params filters         a key value set of filters. The key is associated with the property and the filter value must match the object value.
 * @return Model*          the matched model.
 */
+ (Model*) findOne:(NSDictionary*)_filters;
/**
 * Fetches an objects of this class with the given id
 * @params filters         the id of the object to look for.
 * @return Model*          the matched model.
 */
+ (Model*) findOneById:(int)_id;
/**
 * Deletes all objects that matches a given criteria.
 * @params where           the parameters to match the objects to delete.
 */
+ (void) deleteWhere: (NSDictionary*)dictionary;
/**
 * Deletes all objects of a class.
 */
+ (void) deleteAll;
/**
 * Creates a new record with the object data.
 */
- (void) insert;
/**
 * Updates the record with the current object data.
 */
- (void) update;
/**
 * Fetches the name of the property to use as id. By default, it is the lowercase class name concatenated the "_id" string.
 * @protected
 */
- (NSString*) getIdName;
/**
 * Sets the instance id property.
 */
- (void) setId:(int)_id;
/**
 * Gets the instance id property.
 */
- (int) getId;
/**
 * Creates a key-value representation of all the objects properties.
 */
- (NSDictionary*) toDictionary;
/**
 * Updates or inserts the record, depending if the id is set or not.
 * If the record is inserted, the id gets set after the insert.
 */
- (void) save;
/**
 * Deletes the record.
 */
- (void) delete;
/**
 * Creates a key-value representation to map the properties names and the methods to call.
 * @protected
 */
- (NSDictionary*) serialization;

/**
 * Adds a new observer to notify when the model changes.
 * This observer is NOT retained by this class. If it gets dealloc'ed it should remove itself from this list.
 */
- (void) addObserver:(id<ModelObserver>)_observer;
/**
 * Removes an observer from the list.
 */
- (void) removeObserver:(id<ModelObserver>)_observer;
/**
 * Removes all observers.
 */
- (void) removeAllObservers;
/**
 * Loads a model information from a url. It must return a JSON object with the keys matching the class properties.
 * @params url             the url to call.
 */
+ (Model*)fetchFromURL:(NSString*)urlStr;
/**
 * Loads a model information from a url. It must return a JSON object with the keys matching the class properties.
 * @params url             the url to call.
 * @params params          the post body key-value to submit on the request.
 */
+ (Model*)fetchFromURL:(NSString*)urlStr withParams:(NSDictionary*)_params;
/**
 * Loads a model list information from a url. It must return a JSON array and in each position a JSON Object with the keys matching the class properties.
 * @params url             the url to call.
 */
+ (ModelCollection*)fetchCollectionFromURL:(NSString*)urlStr;
/**
 * Loads a model list information from a url. It must return a JSON array and in each position a JSON Object with the keys matching the class properties.
 * @params url             the url to call.
 * @params params          the post body key-value to submit on the request.
 */
+ (ModelCollection*)fetchCollectionFromURL:(NSString*)urlStr andParams:(NSDictionary*)_params;
/**
 * Stores a request reference. Useful to cancel when dealloc'ing.
 * @protected
 */
- (void) addRequest:(HTTPRequest*)_request;
/**
 * Remove a request reference.
 * @protected
 */
- (void) removeRequest:(HTTPRequest*)_request;

/**
 * @abstract
 */
+ (id <ModelDelegate>) getDelegate;

@end