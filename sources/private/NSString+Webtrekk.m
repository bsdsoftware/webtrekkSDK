#import "NSString+Webtrekk.h"


@implementation NSString (Webtrekk)

-(NSString*) wtNonEmpty {
	if (self.length == 0) {
		return nil;
	}
	
	return self;
}


-(NSString*) wtStringByEscapingUrlParameter {
	return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
}

@end
