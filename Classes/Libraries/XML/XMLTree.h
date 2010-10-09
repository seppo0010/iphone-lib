
@interface XMLNode : NSObject {
	NSString* name;
	NSMutableArray* children;
	NSString* data;
	NSDictionary* attributes;
	XMLNode* parent;
}

/**
 * The content inside the tags. Must be not null.
 */
@property (readonly) NSString* data;
/**
 * The tag name. Must be not null.
 */
@property (retain) NSString* name;
/**
 * The tag attributes. It might be null.
 */
@property (retain) NSDictionary* attributes;

/**
 * Creates a new node with the tag name and tag attributes.
 */
- (XMLNode*) initWithName:(NSString*)n andAttributes:(NSDictionary*)attrib;
/**
 * Returns the first child with the given tag name.
 * @param NSString*   the child tag name to search. Must be not null.
 * @return XMLNode*   the matched XMLNode. It might be null.
 */
- (XMLNode*) childWithName:(NSString*) n;
/**
 * Returns the index-ed position XMLNode* child, starting on 0 and the top is the number of childs less one.
 * Calling this method might throw an out of bounds exception if the index is lower than 0 or greater or equal of the number of subnodes.
 * @param int          the number of child to search
 * @return XMLNode*    the matched child. Might be null.
 */
- (XMLNode*) getChild:(int)index;
/**
 * The number of node childs the node has.
 */
- (int) childCount;
/**
 * A string representation of the node.
 */
- (NSString*) toString;
/**
 * Adds a sub node to the node.
 * @protected
 */
- (void) addChild:(XMLNode*)child;
/**
 * Creates a dictionary representation of the node. It ignores the tag attributes.
 * This call is recursive. All the node contents are treated as strings.
 */
- (NSDictionary*)toDictionary;
/**
 * Prints a legible description of the node. Useful for debug only.
 */
- (void) debugPrint: (int) i;
/**
 * @protected
 */
- (void) setParent:(XMLNode*)p;
/**
 * Sets the node content.
 */
- (void) setLeafData:(NSString*)data;

@end

@interface XMLTree : NSObject {
	XMLNode* root;
	
	XMLNode* currentNode;
	NSMutableString* currentData;
}

/**
 * The first XML Node.
 */
@property (retain) XMLNode* root;
/**
 * Clean ups all the sub nodes.
 */
- (void) reset;
/**
 * A string representation of the string.
 */
- (NSString*) toString;

/**
 * Parses the XML content.
 * @param data       the xml to parse
 * @return success or failure
 */
- (BOOL)parseXMLFileWithData:(NSData *)data;

/**
 * Parses the XML content.
 * @param data       the xml to parse
 * @param error      the error is it failed to parse
 * @return           success or failure
 */
- (BOOL)parseXMLFileWithData:(NSData *)data parseError:(NSError **)error;

/**
 * Download and parses an XML in a remote URL. This method creates a syncronic request.
 * @param data       the url to download the xml to parse
 * @param error      the error is it failed to parse
 * @return           success or failure
 */
- (BOOL)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

/**
 * Creates a new xml tree and parses the given information.
 * @param data       the xml to parse
 */
+ (XMLTree*) treeWithData:(NSData*)data;

@end