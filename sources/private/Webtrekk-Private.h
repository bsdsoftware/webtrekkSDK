#import "Webtrekk.h"


@interface Webtrekk (WebtrekkPrivate)

+(dispatch_queue_t) dispatchQueue;
+(void)             trackEventWithParameters: (NSDictionary*)parameters;

@end
