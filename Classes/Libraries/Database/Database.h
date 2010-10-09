#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "ModelDelegate.h"

#define DB_DEBUG 1

@class DatabaseQuery;
@class DatabaseQuerySelect;
@class DatabaseQueryInsert;
@class DatabaseQueryUpdate;
@class DatabaseQueryDelete;

@interface Database : NSObject <ModelDelegate> {
	sqlite3* db;
	
	NSMutableArray* fields;
	NSString* tableName;
	NSMutableArray* where;
	NSString* orderBy;
	NSMutableDictionary* values;
	int limit;
	int offset;
}

+ (Database*)getInstance;
- (Database*) initWithFilename:(NSString*)dbName;
- (void)reset;
- (void)selectFromString:(NSString*)_fields;
- (void)selectFromArray:(NSArray*)_fields;
- (void)from:(NSString*)_table;
- (void)orderBy:(NSString*)_field;
- (void)limit:(int)_limit;
- (void)set:(NSDictionary*)_values;

- (DatabaseQuerySelect*) getFrom:(NSString*)from;
- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where;
- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where orderBy:(NSString*)_orderBy;
- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where orderBy:(NSString*)_orderBy limit:(int)_limit;
- (DatabaseQuerySelect*) getFrom:(NSString*)from where:(id)_where orderBy:(NSString*)_orderBy limit:(int)_limit offset:(int) _offset;
- (DatabaseQuerySelect*) run;
- (DatabaseQueryInsert*) insertInto:(NSString*)_tableName values:(NSDictionary*)_values;
- (DatabaseQueryInsert*) insert;
- (DatabaseQueryUpdate*) update:(NSString*)_tableName set:(NSDictionary*)_values where:(id)_where;
- (DatabaseQueryUpdate*) update;
- (DatabaseQueryDelete*) delete:(NSString*)_tableName where:(id)_where;
- (DatabaseQueryDelete*) delete;

- (NSArray*) getClausesValues;
- (void) parseClausesInto:(NSMutableString*)sql;
- (void) bindValues:(NSArray*)binds intoStatement:(sqlite3_stmt*)statement;
- (void) bindValues:(NSArray*)binds intoStatement:(sqlite3_stmt*)statement startingOn: (int)start;

@property (readonly) sqlite3* db;


@end

@interface DatabaseQuery : NSObject
{
	sqlite3_stmt* statement;
}

- (DatabaseQuery*) initWithStatement:(sqlite3_stmt*)_statement;
@end

@interface DatabaseQuerySelect : DatabaseQuery <ModelResultSelect>
{
	NSMutableArray* result;
	int numRows;
}

- (DatabaseQuerySelect*) initWithStatement:(sqlite3_stmt*)_statement;
- (NSDictionary*) row;
- (NSArray*) result;
- (int) numRows;

@end

@interface DatabaseQueryInsert : DatabaseQuery <ModelResultInsert>
{
	int insertedId;
}

- (DatabaseQueryInsert*) initWithStatement:(sqlite3_stmt*)_statement;
- (int)insertId;

@end

@interface DatabaseQueryUpdate : DatabaseQuery <ModelResultUpdate>
{
}

- (DatabaseQueryUpdate*) initWithStatement:(sqlite3_stmt*)_statement;
@end

@interface DatabaseQueryDelete : DatabaseQuery <ModelResultDelete>
{
}

- (DatabaseQueryDelete*) initWithStatement:(sqlite3_stmt*)_statement;
@end

@interface DatabaseQueryClause : NSObject <ModelClause>
{
	BOOL any;
	NSMutableArray* clauses;
	NSMutableArray* values;
}

@property BOOL any;
@property (readonly) NSArray* values;

+ (DatabaseQueryClause*)clauseWithDictionary:(NSDictionary*)dictionary;
+ (DatabaseQueryClause*)clauseWithClauses:(NSArray*)dictionary;
+ (DatabaseQueryClause*)clauseWithClauses:(NSArray*)_clauses withAny:(BOOL)_any;
- (DatabaseQueryClause*)initWithDictionary:(NSDictionary*)dictionary;
- (DatabaseQueryClause*)initWithClauses:(NSArray*)_clauses;
- (void) addClause:(DatabaseQueryClause*)_clause;
- (void) addClauses:(NSArray*)_clauses;
- (void) addDictionary:(NSDictionary*)dictionary;
- (void) addValue:(id)value forKey:(NSString*)key;
- (NSString*)toString;

@end