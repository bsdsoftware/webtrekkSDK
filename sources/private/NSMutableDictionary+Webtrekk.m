#import "NSMutableDictionary+Webtrekk.h"


@implementation NSMutableDictionary (Webtrekk)

+(NSMutableDictionary*) wtDictionaryWithDictionary:(NSDictionary*)dictionary andObject:(id)object forKey:(id<NSCopying>)key {
	if (dictionary == nil) {
		if (object == nil) {
			return [NSMutableDictionary dictionary];
		}
		
		return [NSMutableDictionary dictionaryWithObject:object forKey:key];
	}
	
	NSMutableDictionary* newDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
	if (object != nil) {
		[newDictionary setObject:object forKey:key];
	}
	else {
		[newDictionary removeObjectForKey:key];
	}
	
	return newDictionary;
}



-(void) wtSetObject:(id)object forKey:(id<NSCopying>)key {
	if (object != nil) {
		[self setObject:object forKey:key];
	}
	else {
		[self removeObjectForKey:key];
	}
}

@end
