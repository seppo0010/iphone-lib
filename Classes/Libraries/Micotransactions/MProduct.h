#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface MProduct : NSObject 
{
	SKProduct* skProduct;
	NSDictionary* extra_data;
	int position;
	int priceTalons;
}

@property (retain) NSDictionary* extra_data;
@property (retain) SKProduct* skProduct;
@property int position;
@property int priceTalons;

-(MProduct*) initWithSKProduct:(SKProduct*)_skproduct;

@end
