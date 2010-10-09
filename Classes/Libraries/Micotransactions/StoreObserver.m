#import "StoreObserver.h"
#import "ProductStore.h"
#import "Stadistics.h"

@interface StoreObserver(private)
	
	- (void) completeTransaction: (SKPaymentTransaction *)transaction;
	- (void) failedTransaction: (SKPaymentTransaction *)transaction;
	- (void) restoreTransaction: (SKPaymentTransaction *)transaction;

@end

@implementation StoreObserver

@synthesize store;

- (StoreObserver*)initWithStore:(ProductStore*) _store {
	self.store = _store;
	return [self init];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		//NSLog(@"Paymentqueue updatedTransactions %d", transaction.transactionState);
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				[self failedTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				[self completeTransaction:transaction];
				break;
			default:
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	[store failedTransaction:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions) {
		//NSLog(@"paymentQueue removedTransactions %d", transaction.transactionState);
	}
}
@end


@implementation StoreObserver(private)

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
	///NSLog(@"completeTransaction");
	[[Stadistics sharedInstance] trackEvent:@"PURCHASED_ITEM" WithValue:transaction.payment.productIdentifier];
	
	[store provideContent: transaction];
	//[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
	//NSLog(@"restoreTransaction");
	
	[[Stadistics sharedInstance] trackEvent:@"RESTORE_ITEM" WithValue:transaction.payment.productIdentifier];
	
	[store provideContent: transaction];
	//[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
	if (transaction.transactionState != SKErrorPaymentCancelled) {
		UIAlertView *successesAlert = [[UIAlertView alloc] initWithTitle:@"In-App-Purchase Error:" message:@"There was an error purchasing this item please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[successesAlert show];
		[successesAlert release];
	}
	[store failedTransaction:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

@end
