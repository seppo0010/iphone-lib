#import "Database.h"

@implementation Database

@synthesize db;

static Database* instance;

+ (Database*)getInstance {
	@synchronized(self) {
		if (!instance)
			instance = [[Database alloc] init];
		return instance;
	}
	return nil;
}

- (Database*) init {
	
	[self initWithFilename:@"database.sql"];
	return self;
}

- (Database*) initWithFilename:(NSString*)dbName
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	//NSString* dbName = @"database_v2.sql";
	NSError *error;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:dbName];
	
	if (![fileManager fileExistsAtPath:writableDBPath]) {
		NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:dbName];
		if (![fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error]) {
			NSLog(@"Failed to create writable database file with message '%@'.", [error localizedDescription]);
		}
	}
	
    NSString *path = [documentsDirectory stringByAppendingPathComponent:dbName];
    if (!sqlite3_open([path UTF8String], &db) == SQLITE_OK) {
        sqlite3_close(db);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(db));
    }
	[self reset];
	return self;
}

- (void) reset {
	[fields removeAllObjects];
	[where removeAllObjects];
	[values removeAllObjects];
	tableName = nil;
	orderBy = nil;
	limit = 0;
	offset = 0;
}

- (void)selectFromString:(NSString*)_fields {
	NSString* trimmedFields = [_fields stringByReplacingOccurrencesOfString:@" " withString:@""];
	[self selectFromArray:[trimmedFields componentsSeparatedByString:@","]];
}

- (void)selectFromArray:(NSArray*)_fields {
	if (!fields)
		fields = [NSMutableArray new];
	[fields addObjectsFromArray:_fields];
}

- (void)from:(NSString*)_table {
	tableName = [_table lowercaseString];
}

- (void)where:(id)_where {
	if (!where)
		where = [NSMutableArray new];
	DatabaseQueryClause* clause = nil;
	if ([_where isKindOfClass:[DatabaseQueryClause class]]) clause = _where;
	else if ([_where isKindOfClass:[NSDictionary class]]) clause = [[[DatabaseQueryClause alloc] initWithDictionary:_where] autorelease];
	else return;
	[where addObject:clause];
}

- (void)orderBy:(NSString*)_field {
	orderBy = _field;
}

- (void)limit:(int)_limit {
	limit = _limit;
}

- (void)offset:(int) _offset
{
	offset = _offset;
}

- (DatabaseQuerySelect*) getFrom:(NSString*)from {
	return [self getFrom:from where:nil];
}

- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where {
	return [self getFrom:from where:_where orderBy:nil];
}

- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where orderBy:(NSString*)_orderBy {
	return [self getFrom:from where:_where orderBy:_orderBy limit:0];
}

- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where orderBy:(NSString*)_orderBy limit:(int)_limit {
	return [self getFrom:from where:_where orderBy:_orderBy limit:_limit offset:0];
}

- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where orderBy:(NSString*)_orderBy limit:(int)_limit offset:(int) _offset
{
	[self from:from];
	[self where:_where];
	[self orderBy:_orderBy];
	[self limit:_limit];
	[self offset:_offset];
	
	return [self run];
}

- (DatabaseQuerySelect*) run {
	//return nil;
	if (!tableName) return nil;
	//NSMutableString* sql = [[NSMutableString stringWithString:@"SELECT "] autorelease];
	NSMutableString* sql = [NSMutableString string];
	[sql appendString:@"SELECT "];
	if (fields) {
		[sql appendString:[fields componentsJoinedByString:@", "]];
	} else {
		[sql appendString:@"*"];
	}
	[sql appendFormat:@" FROM %@", tableName];
	
	[self parseClausesInto:sql];
	
	if (orderBy && [orderBy length] > 0)
	{
		[sql appendFormat:@" ORDER BY %@", orderBy];
	}
	
	if (limit > 0)
	{
		[sql appendFormat:@" LIMIT %d, %d", offset, limit];
	}
	
	if (DB_DEBUG) NSLog(@"SQL : %@", sql);
	
	sqlite3_stmt* statement;
	if (sqlite3_prepare_v2(db, (const char*)[sql UTF8String], -1, &statement, NULL) != SQLITE_OK) 
		NSLog(@"Error preparing statement: '%s'.", sqlite3_errmsg(db));
	
	[self bindValues:[self getClausesValues] intoStatement:statement];
	
	[self reset];
	DatabaseQuerySelect* query = [[[DatabaseQuerySelect alloc] initWithStatement:statement] autorelease];
	
	return query;
}

- (void)set:(NSDictionary*)_values {
	if (!values)
		values = [NSMutableDictionary new];
	[values addEntriesFromDictionary:_values];
}

- (DatabaseQueryUpdate*) update:(NSString*)_tableName set:(NSDictionary*)_values where:(NSDictionary*)_where {
	[self from:_tableName];
	[self set:_values];
	[self where:_where];
	
	return [self update];
}

- (DatabaseQueryUpdate*) update {
	//return nil;
	if (!tableName) return nil;
	if (!values) return nil;
	NSMutableString* sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", tableName];
	NSArray* keys = [values allKeys];
	for (int i = 0; i < [keys count]; i++)
	{
		[sql appendFormat:@"%@ = ?", [keys objectAtIndex:i]];
		if (i < [keys count] - 1)
			[sql appendString:@", "];
	}
	
	if (where)
		[self parseClausesInto:sql];
	
	if (DB_DEBUG) NSLog(@"UPDATE : %@", sql);
	sqlite3_stmt* statement;
	if (sqlite3_prepare_v2(db, (const char*)[sql UTF8String], -1, &statement, NULL) != SQLITE_OK) 
		NSLog(@"Error preparing statement: '%s'. Query is: '%@'", sqlite3_errmsg(db), sql);
	
	[self bindValues:[values allValues] intoStatement:statement];
	[self bindValues:[self getClausesValues] intoStatement:statement startingOn:[values count] + 1];
	
	[self reset];
	DatabaseQueryUpdate* query = [[[DatabaseQueryUpdate alloc] initWithStatement:statement] autorelease];
	return query;
}

- (DatabaseQueryDelete*) delete:(NSString*)_tableName where:(id)_where {
	[self from:_tableName];
	[self where:_where];
	return [self delete];
}

- (DatabaseQueryDelete*) delete {
	//return nil;
	if (!tableName) return nil;
	NSMutableString* sql = [NSMutableString stringWithFormat:@"DELETE FROM %@", tableName];
	
	if (where)
	{
		[self parseClausesInto:sql];
	}
	
	if (DB_DEBUG) NSLog(@"DELETE :%@", sql);
	sqlite3_stmt* statement;
	if (sqlite3_prepare_v2(db, (const char*)[sql UTF8String], -1, &statement, NULL) != SQLITE_OK) 
		NSLog(@"Error preparing statement: '%s'.", sqlite3_errmsg(db));
	
	[self bindValues:[self getClausesValues] intoStatement:statement startingOn:[values count] + 1];
	
	[self reset];
	DatabaseQueryDelete* query = [[[DatabaseQueryDelete alloc] initWithStatement:statement] autorelease];
	return query;
}

- (DatabaseQueryInsert*) insertInto:(NSString*)_tableName values:(NSDictionary*)_values {
	[self from:_tableName];
	[self set:_values];
	return [self insert];
}

- (DatabaseQueryInsert*) insert {
	//return nil;
	if (!tableName) return nil;
	if (!values) return nil;
	NSMutableString* sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ (", tableName];
	NSArray* keys = [values allKeys];
	NSMutableString* bindings = [NSMutableString string];
	for (int i = 0; i < [keys count]; i++)
	{
		[sql appendString:[keys objectAtIndex:i]];
		[bindings appendString:@"?"];
		if (i < [keys count] - 1)
		{
			[sql appendString:@", "];
			[bindings appendString:@", "];
		}
	}
	[sql appendFormat:@") VALUES (%@)", bindings];
	
	if (DB_DEBUG) NSLog(@"INSERT: %@", sql);
	sqlite3_stmt* statement;
	if (sqlite3_prepare_v2(db, (const char*)[sql UTF8String], -1, &statement, NULL) != SQLITE_OK) 
		NSLog(@"Error preparing statement: '%s'.", sqlite3_errmsg(db));
	
	NSArray* binds = [values allValues];
	[self bindValues:binds intoStatement:statement];
	
	[self reset];
	DatabaseQueryInsert* query = [[[DatabaseQueryInsert alloc] initWithStatement:statement] autorelease];
	return query;
}

- (NSArray*) getClausesValues {
	NSMutableArray* _values = [NSMutableArray arrayWithCapacity:0];
	for (int i = 0; i < [where count]; i++)
		[_values addObjectsFromArray:[[where objectAtIndex:i] values]];
	return _values;
}

- (void) bindValues:(NSArray*)binds intoStatement:(sqlite3_stmt*)statement {
	[self bindValues:binds intoStatement:statement startingOn:1];
}

- (void) bindValues:(NSArray*)binds intoStatement:(sqlite3_stmt*)statement startingOn: (int)start {
	for (int i = 0; i < [binds count]; i++)
	{
		id bind = [binds objectAtIndex:i];
		if ([bind isKindOfClass:[NSString class]])
		{
			sqlite3_bind_text(statement, i + start, (const char*)[(NSString*)bind UTF8String], -1, SQLITE_TRANSIENT);
		} else if ([bind isKindOfClass:[NSNumber class]])
		{
			if (strcmp([(NSNumber*)bind objCType], @encode(int)) == 0)
				sqlite3_bind_int(statement, i + start, [bind intValue]);
			else if ((strcmp([(NSNumber*)bind objCType], @encode(float)) == 0) || (strcmp([(NSNumber*)bind objCType], @encode(double)) == 0))
				sqlite3_bind_double(statement, i + start, [bind doubleValue]);
			else if (strcmp([(NSNumber*)bind objCType], @encode(long long)) == 0)
				sqlite3_bind_int64(statement, i + start, [bind longLongValue]);
			else if (strcmp([(NSNumber*)bind objCType], @encode(unsigned long long)) == 0)
				sqlite3_bind_int64(statement, i + start, [bind unsignedLongLongValue]);
			else if (strcmp([(NSNumber*)bind objCType], @encode(BOOL)) == 0)
				sqlite3_bind_int(statement, i + start, [bind boolValue]);
		}
	}
}

- (void) parseClausesInto:(NSMutableString*)sql {
	if (where && [where count])
	{
		if ([where count] == 1)
		{
			[sql appendFormat:@" WHERE %@ ", [[where objectAtIndex:0] toString]];
			return;
		}
		DatabaseQueryClause* clause = [[DatabaseQueryClause alloc] initWithClauses:where];
		[sql appendFormat:@" WHERE %@ ", [clause toString]];
		[clause release];
	}
}

- (void) dealloc {
	[fields release];
	[where release];
	[values release];
	[super dealloc];
}

@end

@implementation DatabaseQuery

- (DatabaseQuery*) initWithStatement:(sqlite3_stmt*)_statement
{
	statement = _statement;
	return self;
}

- (void) dealloc {
	sqlite3_reset(statement);
	if (sqlite3_finalize(statement) != SQLITE_OK)
		NSLog(@"Error finalizing statement: '%s'", sqlite3_errmsg([Database getInstance].db));
	[super dealloc];
}

@end

@implementation DatabaseQuerySelect

- (DatabaseQuerySelect*) initWithStatement:(sqlite3_stmt*)_statement
{
	[super initWithStatement:_statement];
	return self;
}

- (NSDictionary*) row {
	int success = sqlite3_step(statement);
	if (success == SQLITE_ROW)
	{
		NSMutableDictionary* row = [NSMutableDictionary dictionaryWithCapacity:0];
		int column = 0;
		while (TRUE)
		{
			const char* col_name = sqlite3_column_name(statement, column);
			if (col_name == NULL) break;
			
			int type = sqlite3_column_type(statement, column);
			if (type == SQLITE_INTEGER)
				[row setValue:[NSNumber numberWithInt:sqlite3_column_int(statement, column)] forKey:[NSString stringWithFormat:@"%s", col_name]];
			else if (type == SQLITE_TEXT) {
				const unsigned char * text = sqlite3_column_text(statement, column);
				[row setValue:[[[NSString alloc] initWithCString:(const char *)text encoding:NSUTF8StringEncoding] autorelease] forKey:[NSString stringWithFormat:@"%s", col_name]];
			}
			else if (type == SQLITE_FLOAT)
				[row setValue:[NSNumber numberWithFloat:sqlite3_column_double(statement, column)] forKey:[NSString stringWithFormat:@"%s", col_name]];
			else if (type == SQLITE_NULL)
				[row setValue:nil forKey:[NSString stringWithFormat:@"%s", col_name]];
			else
				break;
			column++;
		}
		[result addObject:row];
		return (NSDictionary*)row;
	} else if (success != SQLITE_DONE) {
		NSLog(@"Error fetching row: '%s'", sqlite3_errmsg([Database getInstance].db));
	}
	return nil;
}
- (NSArray*) result {
	if (result) return (NSArray*)result;
	result = [NSMutableArray arrayWithCapacity:0];
	while ([self row]) {}
	return (NSArray*)result;
}

- (int) numRows {
	return [[self result] count];
}

@end

@implementation DatabaseQueryInsert

- (DatabaseQueryInsert*) initWithStatement:(sqlite3_stmt*)_statement {
	[super initWithStatement:_statement];
	int success = sqlite3_step(statement);
	if (success == SQLITE_DONE)
		insertedId = sqlite3_last_insert_rowid([Database getInstance].db);
	return self;
}

- (int)insertId {
	return insertedId;
}

@end

@implementation DatabaseQueryUpdate

- (DatabaseQueryUpdate*) initWithStatement:(sqlite3_stmt*)_statement {
	[super initWithStatement:_statement];
	int success = sqlite3_step(statement);
	if (success != SQLITE_DONE)
		NSLog(@"Error updating: '%s'", [Database getInstance].db);
	return self;
}

@end

@implementation DatabaseQueryDelete

- (DatabaseQueryDelete*) initWithStatement:(sqlite3_stmt*)_statement {
	[super initWithStatement:_statement];
	int success = sqlite3_step(statement);
	if (success != SQLITE_DONE)
		NSLog(@"Error deleting: '%s'", [Database getInstance].db);
	return self;
}

@end

@implementation DatabaseQueryClause

@synthesize any, values;

+ (DatabaseQueryClause*)clauseWithDictionary:(NSDictionary*)dictionary {
	return [[[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (DatabaseQueryClause*)clauseWithClauses:(NSArray*)_clauses {
	return [self clauseWithClauses:_clauses withAny:FALSE];
}

+ (DatabaseQueryClause*)clauseWithClauses:(NSArray*)_clauses withAny:(BOOL)_any {
	DatabaseQueryClause* clause = [[[self alloc] initWithClauses:_clauses] autorelease];
	clause.any = _any;
	return clause;
}

- (DatabaseQueryClause*) init {
	[super init];
	clauses = [[NSMutableArray alloc] initWithCapacity:0];
	values = [[NSMutableArray alloc] initWithCapacity:0];
	return self;
}
- (DatabaseQueryClause*)initWithDictionary:(NSDictionary*)dictionary {
	[self init];
	[self addDictionary:dictionary];
	return self;
}

- (DatabaseQueryClause*)initWithClauses:(NSArray*)_clauses {
	[self init];
	[self addClauses:_clauses];
	return self;
}

- (void) addClause:(DatabaseQueryClause*)_clause {
	[clauses addObject:[_clause toString]];
	[values addObjectsFromArray:[_clause values]];
}

- (void) addClauses:(NSArray*)_clauses {
	for (int i = 0; i < [_clauses count]; i++)
		[self addClause:[_clauses objectAtIndex:i]];
}

- (void) addDictionary:(NSDictionary*)dictionary {
	for (int i = 0; i < [dictionary count]; i++)
	{
		NSString* key = [[dictionary allKeys] objectAtIndex:i];
		[self addValue:[dictionary valueForKey:key] forKey:key];
	}
}

- (void) addValue:(id)value forKey:(NSString*)clause {
	if ([value isKindOfClass:[NSArray class]]) 
	{
		NSMutableArray* binds = [NSMutableArray arrayWithCapacity:[value count]];
		for (int i = 0; i < [value count]; i++) [binds addObject:@"?"];
		[clauses addObject:[NSString stringWithFormat:@"%@ IN (%@)", clause, [binds componentsJoinedByString:@","]]];
		[values addObjectsFromArray:(NSArray*)value];
	} else {
		if ([clause rangeOfString:@"!="].location == NSNotFound && [clause rangeOfString:@">"].location == NSNotFound && [clause rangeOfString:@"<"].location == NSNotFound)
			[clauses addObject:[NSString stringWithFormat:@"%@ = ?", clause]];
		else
			[clauses addObject:[NSString stringWithFormat:@"%@ ?", clause]];
		[values addObject:value];
	}
}

- (NSString*)toString {
	if ([clauses count] == 0) return nil;
	NSMutableString* result = [NSMutableString stringWithString:@"("];
	for (int i = 0; i < [clauses count]; i++)
	{
		if (i > 0) [result appendFormat:@" %@ ", (any ? @"OR" : @"AND")];
		[result appendString:(NSString*)[clauses objectAtIndex:i]];
	}
	[result appendString:@")"];
	return result;
}


- (void) dealloc {
	[clauses release];
	[values release];
	[super dealloc];
}

@end
