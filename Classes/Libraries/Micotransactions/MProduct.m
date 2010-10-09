#import "MProduct.h"


@implementation MProduct
@synthesize extra_data, skProduct, position, priceTalons;

-(MProduct*) initWithSKProduct:(SKProduct*)_skproduct
{
	self.skProduct = _skproduct;
	return self;
}
@end
