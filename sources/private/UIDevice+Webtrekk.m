#import "UIDevice+Webtrekk.h"


@implementation UIDevice (Webtrekk)

-(BOOL) wtIsSimulator {
	static BOOL isSimulator;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		isSimulator = ([self.model rangeOfString:@"simulator" options:NSCaseInsensitiveSearch].location != NSNotFound);
	});
	
	return isSimulator;
}

@end
