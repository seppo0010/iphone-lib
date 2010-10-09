#import "NSObjectClassName.h"

@implementation UITableViewCell (loadCellNib)
+ (UITableViewCell*) loadCellNibForTableView:(UITableView*)tableView {
	NSString* cellNibName = [self className];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellNibName]; 
	
	if ( !cell ) {
		NSArray* views = [[NSBundle mainBundle] loadNibNamed:cellNibName owner:nil options:nil];
		
		for ( int i = 0; i < [views count]; ++i ) {
			id object = [views objectAtIndex:i];
			
			if ( [object isKindOfClass:[UITableViewCell class]] ) {
				cell = object;
				
				if ( ![cell.reuseIdentifier isEqualToString:cellNibName] ) {
					NSLog(@"Cell (%@) identifier does not match its nib name", cellNibName);
				}
			}
		}
	}
	
	if ( !cell ) {
		NSLog(@"Unable to load cell from nib: %@", cellNibName);
	}
	
	return cell;
}
@end