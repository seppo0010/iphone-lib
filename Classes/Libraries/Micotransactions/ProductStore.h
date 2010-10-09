#import <StoreKit/StoreKit.h>
#import "StoreObserver.h"
#import "ProductStoreDelegate.h"


#ifdef FULL_VERSION
	#define PS_APP_ID 1023
#else 
	#ifdef FREE_50MISSILES_VERSION
		#define PS_APP_ID 1024
	#else
		#define PS_APP_ID 1001
	#endif
#endif

#define PS_APP_VERSION @"3.0"
@protocol StoreTransactionNotify <NSObject>

@optional
-(void) packageHasArrived:(NSString *)location;
//-(void) packageHasArrived:(MProduct*)product Path:(NSString *)location;
-(void) unblockFeature:(id)feature;
-(void) failedTransaction:(NSString*) productIdentifier;

@end



@interface ProductStore : NSObject <SKProductsRequestDelegate>  {
	
	SKPaymentQueue* paymentQueue;

	NSMutableSet* productStoreDelegates;
	NSMutableSet* storeTransactionDelegates;
	
	StoreObserver* storeObserver;
	
	NSMutableDictionary *loadedTransactions;
	
	NSDictionary* productList;
	NSInteger appID;
	SKProductsRequest *request;
	BOOL talons;
}

//@property (nonatomic, assign) id<ProductStoreDelegate> productStoreDelegate;
//@property (nonatomic, assign) id<StoreTransactionNotify> storeTransactionDelegate;

+(ProductStore*) getInstanceForApp:(NSInteger)applicationID;
+(ProductStore*) sharedInstance;
+(NSURL*) urlWithString:(NSString*)_url;
+(NSURL*) imageUrlWithString:(NSString*)_url;
-(ProductStore*) initForApp:(NSInteger)applicationID;

-(void) addProductStoreObserver:(id<ProductStoreDelegate>)_delegate;
-(void) addStoreTransactionObserver:(id<StoreTransactionNotify>)_delegate;

-(void) removeProductStoreObserver:(id<ProductStoreDelegate>)_delegate;
-(void) removeStoreTransactionObserver:(id<StoreTransactionNotify>)_delegate;

-(void) checkProductList;

-(void) checkProductListForCategory:(int)category;
-(void) buyProduct:(NSString*)productId;
-(void) buyProductTalon:(NSString*)productId;
-(void) buyProductWithQuantity:(NSString*)productId quantity:(NSInteger)q;

-(void) provideContent:(SKPaymentTransaction *)transaction;
-(void) provideContentTalons:(NSString*) productId;


-(void) productsRequest:(SKProductsRequest*)request didReceiveResponse:(SKProductsResponse*)response;

- (void) failedTransaction:(SKPaymentTransaction*)transaction;

- (void) restoreCompletedTransactions;

-(void) verifyProducts:(NSSet*) products;

@end
