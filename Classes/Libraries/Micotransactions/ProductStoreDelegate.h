//
//  ProductStoreDelegate.h
//  MicrotransactionClient
//
//  Created by Pablo Truchi on 6/22/09.
//  Copyright 2009 engenus. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ProductStoreDelegate <NSObject>

- (void)didFinishLoadingProducts: (NSArray*) products;
- (void)didFailLoadingProducts;

@end