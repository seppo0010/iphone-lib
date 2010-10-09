#import "XMLTree.h"

@interface XMLNode (Private)

-(XMLNode*) parent;

@end

@implementation XMLTree

@synthesize root;

- (id) init {
	root = nil;
	currentNode = nil;
	currentData = [[NSMutableString alloc] init];
	return self;
}

- (void) dealloc {
	[root release];
	[currentData release];
	[super dealloc];
}

- (void) reset {
	[root release];
	root = nil;
	currentNode = nil;
	[currentData setString:@""];
}

- (NSString*) toString{
	NSMutableString* treeString = [[[NSMutableString alloc] initWithCapacity:0] autorelease];
	[treeString appendFormat:@"<?xml version=\"1.0\" encoding=UTF8> %@", [root toString]];
	return (NSString*) treeString;
}

+ (XMLTree*) treeWithData:(NSData*)data {
	XMLTree *tree = [[XMLTree alloc] init];
	[tree parseXMLFileWithData:data];
	return [tree autorelease];
}

- (BOOL)parseXMLFileWithData:(NSData *)data {
	BOOL success = TRUE;
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
	
    [parser parse];
	
    NSError *parseError = [parser parserError];
    if (parseError) {
		NSLog(@"Error parsing XML. Error: '%@'. XML: %s", [parseError description], [data bytes]);
		success = FALSE;
    }
	
    [parser release];
	return success;
}

- (void)parser:(NSXMLParser *)parser foundExternalEntityDeclarationWithName:(NSString *)entityName publicID:(NSString *)publicID systemID:(NSString *)systemID {

}

- (void)parser:(NSXMLParser *)parser foundInternalEntityDeclarationWithName:(NSString *)name value:(NSString *)value {

}

- (void)parser:(NSXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID notationName:(NSString *)notationName {

}

+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex		{
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (elementName == nil) return;
    if (qName) elementName = qName;

	XMLNode* node = [[[XMLNode alloc] initWithName:elementName andAttributes:attributeDict] autorelease];

	if (!root) {
		root = [node retain];
	}
	
	if (currentNode) [currentNode addChild:node];
	currentNode = node;

	[currentData setString:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
	if (elementName == nil) return;
    
	if ( [currentData length] ) [currentNode setLeafData:currentData];
	[currentData setString:@""];
	
	currentNode = [currentNode parent];
}
 
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
//	NSLog([parseError description]);
	//NSLog(@"Line: %d Column: %d", [parser lineNumber], [parser columnNumber]);
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError{
	NSLog(@"%@", [validError description]);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (string != nil)
		[currentData appendString:string];
}


- (BOOL)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error {
	NSError* connError = 0;
	NSURLResponse* response;
	NSURLRequest* request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
	NSData* data = [ NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connError ];
	
	if ( connError ) {
		if ( error ) *error = connError;
		NSLog(@"%@", [connError description]);
		return FALSE;
	}
	
	return [self parseXMLFileWithData:data parseError:error];
}

- (BOOL)parseXMLFileWithData:(NSData *)data parseError:(NSError **)error {
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    
    [parser parse];
    
    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
		NSLog(@"%@", [parseError description]);
		return FALSE;
    }
	
    [parser release];
	
	return TRUE;
}

@end

@implementation XMLNode

@synthesize name;
@synthesize data;
@synthesize attributes;

-(XMLNode*) initWithName:(NSString*)n andAttributes:(NSDictionary*)attrib {
	name = [n copy];
	attributes = [attrib retain];
	children = nil;
	data = nil;
	parent = nil;
	return self;
}

- (void) dealloc {
	[name release];
	[data release];
	[attributes release];
	[children release];
	
	[super dealloc];
}


- (NSString*) toString{
	NSMutableString* nodeString = [[NSMutableString alloc] initWithCapacity:0];
	[nodeString appendFormat:@"<%@ ", name];
	
	//adding atributes
	NSArray* keys = [attributes allKeys];	
	if (keys){
		for(int i = 0; i < [keys count]; i++){
			NSString* keyString = [keys objectAtIndex:i];
			NSString* valueString = [attributes objectForKey:keyString];
			[nodeString appendFormat:@"%@=\"%@\" ", keyString, valueString];
		}
	}	
	[nodeString appendFormat:@">"];
	
	//adding children in a recursive fashion
	if (children){
		for(int i = 0; i < [children count]; i++){
			XMLNode* node = [children objectAtIndex:i];
			[nodeString appendFormat:@"%@", [node toString]];
		}
	}	
	[nodeString appendFormat:@"%@</%@>", data, name];
	NSString* finalString = [NSString stringWithString:nodeString];
	[nodeString release];
	return finalString;
}

-(void) setParent:(XMLNode*)p {
	parent = p;
}

-(XMLNode*) parent {
	return parent;
}

-(void) setLeafData:(NSString*)d {
	if (data) [data release];
	data = [d copy];
}

-(void) addChild:(XMLNode*)child {
	if ( !children ) children = [[NSMutableArray alloc] init];
	[children addObject: child];
	[child setParent:self];
}

- (XMLNode*) childWithName:(NSString*) n {
	if ( !children ) return nil;
	XMLNode* node;
	for ( node in children ) {
		if ( [node.name isEqualToString:n] ) return node; 
	}
	
	return nil;
}

- (XMLNode*) getChild:(int)index {
	if ( !children ) return nil;
	return [children objectAtIndex:index];
}

- (int) childCount {
	if ( !children ) return 0;
	return [children count];
}

- (NSDictionary*)toDictionary {
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	for (int i = 0; i < [self childCount]; i++)
	{
		XMLNode* node = [self getChild:i];
		if ([node childCount] > 0)
			[dictionary setValue:[node toDictionary] forKey:node.name];
		else
			[dictionary setValue:node.data forKey:node.name];
	}
	return (NSDictionary*)dictionary;
}

- (void) debugPrint:(int)i {
	NSMutableString* indentation = [NSMutableString string];
	
	int j;
	for ( j = 0 ; j < i ; ++j ) {
		[indentation appendString:@"  "];
	}
	
	if ( data ) {
		NSLog(@"%@%@: %@", indentation, name, data);
	}else {
		NSLog( @"%@%@", indentation, name );
	}
	
	
	if ( children ) {
		XMLNode* node;
		for ( node in children ) {
			[node debugPrint:i+1];
		}
	}
}

-(NSString*) data {
	//NSLog(@"data %@, %@", data, [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
	if (data == nil) 
		return @"";
	else if ([data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]) 
		return [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	else 
		return data;
}

@end