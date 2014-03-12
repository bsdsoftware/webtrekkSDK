#import "NSArray+Webtrekk.h"


@implementation NSArray (Webtrekk)

-(id) wtOptionalObjectAtIndex:(NSUInteger)index {
	if (index >= self.count) {
		return nil;
	}
	
	return [self objectAtIndex:index];
}

@end
