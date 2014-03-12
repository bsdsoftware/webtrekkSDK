@interface NSMutableDictionary (Webtrekk)

+(NSMutableDictionary*) wtDictionaryWithDictionary: (NSDictionary*)dictionary andObject:(id)object forKey:(id<NSCopying>)key;
-(void)                 wtSetObject:                (id)object forKey:(id<NSCopying>)key;

@end
