
#import "ProductStore.h"
#import <StoreKit/StoreKit.h>

#import "HTTPRequest.h"
#import "HTTPRequestAsyncronic.h"
#import "NSDictionary+BSJSONAdditions.h"
#import "unzip.h"
#import "MProduct.h"
#import "StoreTransactionDelegate.h"
#import "NewHangarController.h"

const void* MRetainNoOp(CFAllocatorRef allocator, const void *value) { return value; }
void MReleaseNoOp(CFAllocatorRef allocator, const void *value) { }

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

NSMutableSet* CreateNonRetainingSet() {
	CFSetCallBacks callbacks = kCFTypeSetCallBacks;
	callbacks.retain = MRetainNoOp;
	callbacks.release = MReleaseNoOp;
	return (NSMutableSet*)CFSetCreateMutable(nil, 0, &callbacks);
}


@interface ProductStore(private)
-(void) unzipFile:(NSString*)srcFilename withPassword:(NSString*)password onDirectory:(NSString*)directory toFile:(NSString*)dstFilename;
-(void) parseProductList:(NSData*)data;
-(void) listProductsFailure;
-(void) verifyProductsOnStoreKit;
-(NSString *)getDocumentsDirectory;
@end

@implementation ProductStore(private)

-(NSString *)getDocumentsDirectory {  
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
	return [paths objectAtIndex:0];  
}  

-(void) unzipFile:(NSString*)srcFilename withPassword:(NSString*)password onDirectory:(NSString*)directory toFile:(NSString*)dstFilename {
	//NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//[fileManager createDirectoryAtPath:mapsDirectory attributes:nil];
	
	//NSString* identifierDir = [mapsDirectory stringByAppendingPathComponent:identifier];
	
	//[fileManager createDirectoryAtPath:identifierDir attributes:nil];
	
	unzFile zipFile = unzOpen([[directory stringByAppendingPathComponent:srcFilename] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	if (!zipFile) {
		NSLog(@"Failed opening zip file: %@", srcFilename);
	}
	else {
		NSLog(@"Succeeded opening zip file");
		
		unzGoToFirstFile(zipFile);
		
		do {
			char filename[64];
			char buffer[256];
			unzGetCurrentFileInfo(zipFile, NULL, filename, sizeof(filename), NULL, 0, NULL, 0);
			NSLog([NSString stringWithFormat:@"zip contains: %s", filename]);
			
			if([password length] == 0)
				unzOpenCurrentFile(zipFile);
			else
				unzOpenCurrentFilePassword(zipFile, [password cStringUsingEncoding:[NSString defaultCStringEncoding]]);
			
			NSMutableData* filedata = [NSMutableData data];
			
			while(true) {
				int readData = unzReadCurrentFile(zipFile, buffer, sizeof(buffer));
				
				if (readData > 0)
					[filedata appendBytes:buffer length:readData];
				else {
					if (readData == 0)
					{
						if([filedata writeToFile:[dstFilename stringByAppendingPathComponent:[NSString stringWithCString:filename]] atomically:NO])
							NSLog(@"Wrote it to disk");
						else
							NSLog(@"Failed to write file");
					}
					break;
				}
			}
			
			[filedata setLength:0];
			unzCloseCurrentFile(zipFile);
			
		} while(unzGoToNextFile(zipFile) == UNZ_OK);
		
		unzClose(zipFile);
	}
}

-(void) parseProductList: (NSData*)data {
	NSLog(@"RECEIVED FROM OUR SERVER");
	NSString* response = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSDictionary* jsonDictionary = [NSDictionary dictionaryWithJSONString:response];
	
	if ([[jsonDictionary objectForKey:@"state"] objectForKey:@"success"]) 
	{
		[productList release];
		productList = [[jsonDictionary objectForKey:@"data"] retain];
	} else {
		if (productList)
			[productList release];
		productList = nil;
		//NSLog([NSString stringWithFormat:@"error %@: %@", [[jsonDictionary objectForKey:@"state"] objectForKey:@"errorID"], [[jsonDictionary objectForKey:@"state"] objectForKey:@"errorMsg"]]);
	}
	
	[self verifyProductsOnStoreKit];
}

-(void) verifyProductsOnStoreKit 
{
	NSMutableSet* products = [NSMutableSet set];
	
	if (![productList isKindOfClass:[NSNull class]])
	{
		NSArray* categories = [productList allKeys];
		
		for (NSString* categoryName in categories) 
		{
			[products addObjectsFromArray:[productList objectForKey:categoryName]];
		}
	}	
	//NSLog([products description]);
	[self verifyProducts:products];
	NSLog(@"REQUEST APPLE");
}

-(void) verifyProducts:(NSSet*) products
{
	[request release];
	
	request= [[SKProductsRequest alloc] initWithProductIdentifiers:products];
	request.delegate = self;
	[request start];
}

-(void) listProductsFailure {
	if (productList)
		[productList release];
	productList = nil;
	
	for (id<ProductStoreDelegate> delegate in productStoreDelegates) {
		if ([delegate respondsToSelector:@selector(didFailLoadingProducts)]) {
			[delegate didFailLoadingProducts];
		}
    }
	
/*    if(productStoreDelegate && [productStoreDelegate respondsToSelector:@selector(didFailLoadingProducts)]) {
        [productStoreDelegate didFailLoadingProducts];
    } else {
		NSLog(@"Not Delegating.");
	}*/
}

@end // private


@implementation ProductStore
//@synthesize storeTransactionDelegate, productStoreDelegate;

static NSString* SERVER_URL = @"http://ijet.iphone.sgn.com/microtransactions/";
//static NSString* SERVER_URL = @"http://www.engenus.net:10000/iphone/microtransactions/Server2/";

//static NSString* SERVER_URL = @"http://192.168.1.101/Microtransactions/";

static ProductStore* instance = nil;

+(ProductStore*) sharedInstance
{
	@synchronized(self) {
		if (instance == nil) {
			instance = (ProductStore*)[[ProductStore alloc] initForApp:PS_APP_ID];
		}
	}
	return instance;
}

+(ProductStore*) getInstanceForApp:(NSInteger)applicationID {
	@synchronized(self) {
		if (instance == nil) {
			instance = (ProductStore*)[[ProductStore alloc] initForApp:applicationID];
		}
	}
	return instance;
}

+(NSURL*) urlWithString:(NSString*)_url
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",SERVER_URL, _url]];
}

+(NSURL*) imageUrlWithString:(NSString*)_url
{
	return [self urlWithString:[NSString stringWithFormat:@"images/%d/%@",PS_APP_ID, _url]]; 
}

-(void) addProductStoreObserver:(id<ProductStoreDelegate>)_delegate
{
	[productStoreDelegates addObject:_delegate];
}

-(void) addStoreTransactionObserver:(id<StoreTransactionNotify>)_delegate
{
	[storeTransactionDelegates addObject:_delegate];
}

-(void) removeProductStoreObserver:(id<ProductStoreDelegate>)_delegate
{
	[productStoreDelegates removeObject:_delegate];
}

-(void) removeStoreTransactionObserver:(id<StoreTransactionNotify>)_delegate
{
	[storeTransactionDelegates removeObject:_delegate];
}

-(ProductStore*) initForApp:(NSInteger)applicationID {
	storeObserver = [[StoreObserver alloc] initWithStore:self];
	//Add on init, to resume aborted transactions.
	[[SKPaymentQueue defaultQueue] addTransactionObserver:storeObserver];
	appID = applicationID;
	loadedTransactions = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	productStoreDelegates = CreateNonRetainingSet();    
	storeTransactionDelegates = CreateNonRetainingSet();
	return self;
}


-(void) checkProductList {
	[self checkProductListForCategory: 0];
}

-(void) checkProductListForCategory:(int)category{

	HTTPRequest* _request = [[HTTPRequestAsyncronic alloc] init];
	
	_request.callbackObject = self;
	_request.successSelector = @selector(parseProductList: );
	_request.failureSelector = @selector(listProductsFailure);
	
	NSString* iPhoneID = [UIDevice currentDevice].uniqueIdentifier;
	
	[_request requestUrl:[NSURL URLWithString: [NSString stringWithFormat:@"%@list_products.php?iphone_id=%@&app_id=%d&category=%d&app_version=%@", SERVER_URL, iPhoneID, appID, category, PS_APP_VERSION]]];
	[_request release];
	NSLog(@"REQUEST FROM OUR SERVER");
}

- (void) restoreCompletedTransactions
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(void) productsRequest:(SKProductsRequest*)request didReceiveResponse:(SKProductsResponse*)response 
{

/*	NSMutableSet* products = [NSMutableSet set];
	for (NSArray* categoryProductList in productList) {
		[products addObjectsFromArray:categoryProductList];
	}
*/
	NSLog(@"RECEIVEd APPLE");
	if ([response.invalidProductIdentifiers count] > 0) {
		NSLog(@"error: %@ invalid product identifiers", response.invalidProductIdentifiers);
	}
	
	NSArray* products = response.products;
	
	//NSArray* storeKitProducts = [NSArray array];
	NSMutableArray* storeKitProducts = [NSMutableArray array];
	
	for (SKProduct* skP in products) 
	{
		MProduct* product = [[MProduct alloc] initWithSKProduct:skP];
		NSArray* categories = [productList allKeys];
		
		for (NSString* categoryName in categories) 
		{
			NSString* jsonString = [[[productList objectForKey:categoryName] objectForKey:skP.productIdentifier] objectForKey:@"extra_data"];
			NSDictionary* extra_data = [NSDictionary dictionaryWithJSONString:jsonString];
			if (extra_data)
			{
				product.extra_data = extra_data;
				if ([extra_data valueForKey:@"position"])
					product.position = [[extra_data valueForKey:@"position"] intValue];
				if ([extra_data valueForKey:@"talons"])
					product.priceTalons = [[extra_data valueForKey:@"talons"] intValue];
				
			}
			
		}
		[storeKitProducts addObject:product];
		[product release];
	}
	
	[storeKitProducts sortUsingDescriptors:[NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"position" ascending:TRUE] autorelease], nil]];
	
	for (id<ProductStoreDelegate> delegate in productStoreDelegates) {
		if ([delegate respondsToSelector:@selector(didFinishLoadingProducts:)]) {
			NSLog(@"didFinishLoadingProducts");
			[delegate didFinishLoadingProducts:storeKitProducts];
		}
    }
	
    /*if(productStoreDelegate && [productStoreDelegate respondsToSelector:@selector(didFinishLoadingProducts:)]) 
	{
        [productStoreDelegate didFinishLoadingProducts:storeKitProducts];
    } else {
        NSLog(@"Not Delegating.");
    }*/
}


-(void) buyProduct:(NSString*)productId {
	
		SKPayment *payment = [SKPayment paymentWithProductIdentifier:productId];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
		[[SKPaymentQueue defaultQueue] addTransactionObserver:storeObserver];
		[SKPaymentQueue canMakePayments];
}

-(void) buyProductTalon:(NSString*)productId{
	[self provideContentTalons:productId];
}

-(void) buyProductWithQuantity:(NSString*)productId quantity:(NSInteger)q {
	SKMutablePayment *payment = [SKMutablePayment paymentWithProductIdentifier:productId];
	
	payment.quantity = q;
	
	[[SKPaymentQueue defaultQueue] addPayment:payment];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:storeObserver];
	[SKPaymentQueue canMakePayments];
}
-(void) provideContentTalons:(NSString*) productId {
	
	HTTPRequest* _request = [[HTTPRequestAsyncronic alloc] init];
	talons = YES;
	_request.callbackObject = self;
	_request.successSelector = @selector(downloadContent:withHeaders:);
	_request.failureSelector = @selector(didFailRecordTransaction);
	
	NSString* iPhoneID = [UIDevice currentDevice].uniqueIdentifier;
	
	[_request requestUrl:[NSURL URLWithString: [NSString stringWithFormat:@"%@record_transaction.php?iphone_id=%@&app_id=%d&app_store_id=%@&store_transaction_id=%@&quantity=%d&app_version=%@&debug=1", SERVER_URL, iPhoneID, PS_APP_ID , productId, 0, 0, PS_APP_VERSION]]];
	[_request release];
}

-(void) provideContent:(SKPaymentTransaction *)transaction {
	HTTPRequest* _request = [[HTTPRequestAsyncronic alloc] init];
	talons = NO;
	_request.callbackObject = self;
	_request.successSelector = @selector(downloadContent:withHeaders:);
	_request.failureSelector = @selector(didFailRecordTransaction);
	
	NSString* iPhoneID = [UIDevice currentDevice].uniqueIdentifier;
	NSString *receiptStr = [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
	
	//NSLog(@"%s", [transaction.transactionReceipt bytes]);
	
	[_request addParameter:@"transaction_data" withValue:receiptStr];
	
	[_request requestUrl:[NSURL URLWithString: [NSString stringWithFormat:@"%@record_transaction.php?iphone_id=%@&app_id=%d&app_store_id=%@&store_transaction_id=%@&quantity=%d&app_version=%@", SERVER_URL, iPhoneID, appID, transaction.payment.productIdentifier, transaction.transactionIdentifier, transaction.payment.quantity, PS_APP_VERSION]]];
	[_request release];
	[loadedTransactions setObject:transaction forKey:transaction.transactionIdentifier];
	[receiptStr release];
}


-(void) notifyFinished:(NSData*) data{
	;
}


-(void) notifyServer:(NSString *)fileURL {
	HTTPRequest* _request = [[HTTPRequestAsyncronic alloc] init];
	
	_request.callbackObject = self;
	_request.successSelector = @selector(notifyFinished:);
	_request.failureSelector = @selector(didFailRecordTransaction);
	
	NSString* iPhoneID = [UIDevice currentDevice].uniqueIdentifier;
	
	[_request requestUrl:[NSURL URLWithString: [NSString stringWithFormat:@"%@confirm_download.php?iphone_id=%@&app_id=%d&file_url=%@", SERVER_URL, iPhoneID, appID, fileURL]]];
	[_request release];
}


-(void) downloadContent: (NSData*)data withHeaders: (NSDictionary*)headers{
	if([[headers objectForKey:@"Content-Type"] rangeOfString:@"text/plain"].location != NSNotFound){
		
		NSString *stringData = [[NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding];
		
		if([stringData isEqualToString:@"failed"]){
			UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:@"Transaction Error:" message:@"Transaction was not validated by AppStore, cannot proceed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[failAlert show];
			[failAlert release];
			
			if(!talons){
			
			
			}
		}
		else{
			NSDictionary *jsonDict = [NSDictionary dictionaryWithJSONString:stringData];
			
			
			for (id<StoreTransactionNotify> delegate in storeTransactionDelegates) {
				if([delegate isKindOfClass:[StoreTransactionDelegate class]])
				{
					[delegate unblockFeature:jsonDict];
					break;
				}
			}
			
			for (id<StoreTransactionNotify> delegate in storeTransactionDelegates) {
				if (![delegate isKindOfClass:[StoreTransactionDelegate class]] && [delegate respondsToSelector:@selector(unblockFeature:)]) 
				{
					//[delegate unblockFeature:jsonDict];
					[delegate performSelector:@selector(unblockFeature:) withObject:jsonDict];
				}
			}
			
			/*if([storeTransactionDelegate conformsToProtocol:@protocol(StoreTransactionNotify)] && 
			   [storeTransactionDelegate respondsToSelector:@selector(unblockFeature:)]){
				[storeTransactionDelegate unblockFeature:jsonDict];
			}*/
			
			[self notifyServer:[jsonDict objectForKey:@"feature_update"]];
			[[SKPaymentQueue defaultQueue] finishTransaction: [loadedTransactions objectForKey:[jsonDict objectForKey:@"transaction_id"]]];
			//[[loadedTransactions objectForKey:[jsonDict objectForKey:@"transaction_id"]] release];
			[loadedTransactions removeObjectForKey:[jsonDict objectForKey:@"transaction_id"]];
			
		}
		[stringData release];
	}
	
	else{
		NSString *rcvFilename = [[[headers objectForKey:@"Content-Disposition"] stringByReplacingOccurrencesOfString:@"attachment; filename=\"" withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
		
		NSArray *parts = [rcvFilename componentsSeparatedByString:@"^"];
		
		NSString *origFilename = [NSString stringWithString:[parts objectAtIndex:1]];
		
		NSString *pkgFilename = [origFilename stringByReplacingOccurrencesOfString:@".zip" withString:@""];
		NSString *tempPath = NSTemporaryDirectory();
		NSString *tempFile = [tempPath stringByAppendingPathComponent:origFilename];
		
		[data writeToFile:tempFile atomically:YES];
		
		
		NSString *documentsDirectory = [[[self getDocumentsDirectory] stringByAppendingPathComponent:@"packages"] stringByAppendingPathComponent:pkgFilename ];
		
		NSError *dirCreationErr = nil;
		//NSError is alloc'ed inside the framework, so we need a double pointer to it.
		if([[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&dirCreationErr]){
			/*
			UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Package Saved!" message:[NSString stringWithFormat:@"Package decompressed and saved in: %@.", documentsDirectory] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[successAlert show];
			[successAlert release];
			 */
		}
		else{
			NSLog(@"Failed to create Document directory: %@", [dirCreationErr localizedDescription]);
			UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:@"In-App-Purchase Error:" message:@"Could not create Document Package directory. Download aborted." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[failAlert show];
			[failAlert release];
		}
		
		[self unzipFile:origFilename withPassword:@"" onDirectory:tempPath toFile:documentsDirectory];
		
		for (id<StoreTransactionNotify> delegate in storeTransactionDelegates) {
			if([delegate isKindOfClass:[StoreTransactionDelegate class]])
			{
				[delegate packageHasArrived:documentsDirectory];
				break;
			}
		}
		
		for (id<StoreTransactionNotify> delegate in storeTransactionDelegates) {
			if (![delegate isKindOfClass:[StoreTransactionDelegate class]] && [delegate respondsToSelector:@selector(packageHasArrived:)]) {
				[delegate packageHasArrived:documentsDirectory];
			}
		}
				
/*		if([storeTransactionDelegate conformsToProtocol:@protocol(StoreTransactionNotify)] &&
		   [storeTransactionDelegate respondsToSelector:@selector(unblockFeature:)])
			[storeTransactionDelegate packageHasArrived:documentsDirectory];*/
		
		[[SKPaymentQueue defaultQueue] finishTransaction: [loadedTransactions objectForKey:[parts objectAtIndex:0]]];
		[loadedTransactions removeObjectForKey:[parts objectAtIndex:0]];
		
		//[[loadedTransactions objectForKey:[parts objectAtIndex:0]] release];
		[self notifyServer:origFilename];
		//NSArray *directoryContent = [[NSFileManager defaultManager] directoryContentsAtPath: documentsDirectory];
		//NSLog(@"Contents of directory: %@", directoryContent);
	}
}

- (void) failedTransaction:(SKPaymentTransaction*)transaction
{
	for (id<StoreTransactionNotify> delegate in storeTransactionDelegates) {
		if ([delegate respondsToSelector:@selector(failedTransaction:)]) {
			[delegate failedTransaction:transaction.payment.productIdentifier];
		}
	}
}

-(void) didFailRecordTransaction {
	NSLog(@"Fail record transaction");
}


-(void) dealloc {
	if (productList)
		[productList release];
	if (paymentQueue)
		[paymentQueue release];
	if(loadedTransactions)
		[loadedTransactions release];
	[super dealloc];
}	

@end
