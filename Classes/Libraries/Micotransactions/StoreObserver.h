
#import <StoreKit/StoreKit.h>

@class ProductStore;

@interface StoreObserver : NSObject <SKPaymentTransactionObserver> {
	ProductStore* store;
}

@property (nonatomic, assign) ProductStore* store;

- (StoreObserver*)initWithStore:(ProductStore*)_store;

//- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;


@end
