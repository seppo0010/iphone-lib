#import <UIKit/UIKit.h>

@interface UIViewControllerCommon : UIViewController {
	
}


+ (UIViewControllerCommon*)loadView;
+ (void)clearOldController;
+ (void)showView:(UIView*)_view;
+ (UIViewControllerCommon*) getLoadedController;

@end