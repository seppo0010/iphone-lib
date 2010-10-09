#import "UIViewControllerCommon.h"
#import "NSObjectClassName.h"
#import "AppDelegate.h"
//#import "TourViewController.h"

@implementation UIViewControllerCommon

static UIViewControllerCommon* loadedController = nil;

+ (UIViewControllerCommon*)loadView {
	UIViewControllerCommon* object = [[self alloc] initWithNibName:[self className] bundle:nil];
	[self showView:object.view];
	[self clearOldController];


	return loadedController = object;
}

+ (void)clearOldController {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if (loadedController) {
		if ([loadedController respondsToSelector:@selector(cleanUp)])
			[loadedController performSelector:@selector(cleanUp)];
		[loadedController.view removeFromSuperview];
		[loadedController release];
		loadedController = nil;
	}
	[pool release];
}

+ (void)showView:(UIView*)_view {
	AppDelegate* app_delegate = [UIApplication sharedApplication].delegate;
	[app_delegate.window addSubview:_view];
}

+ (UIViewControllerCommon*) getLoadedController {
	return loadedController;
}


@end