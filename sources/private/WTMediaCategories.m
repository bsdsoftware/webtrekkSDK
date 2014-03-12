#import "WTMediaCategories.h"

#import "NSArray+Webtrekk.h"
#import "NSString+Webtrekk.h"


@implementation WTMediaCategories

@synthesize category1  = w_category1;
@synthesize category2  = w_category2;
@synthesize category3  = w_category3;
@synthesize category4  = w_category4;
@synthesize category5  = w_category5;
@synthesize category6  = w_category6;
@synthesize category7  = w_category7;
@synthesize category8  = w_category8;
@synthesize category9  = w_category9;
@synthesize category10 = w_category10;



-(id) initWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 category5:(NSString*)category5 category6:(NSString*)category6 category7:(NSString*)category7 category8:(NSString*)category8 category9:(NSString*)category9 category10:(NSString*)category10 {
	if ((self = [super init])) {
		w_category1  = [category1 copy];
		w_category2  = [category2 copy];
		w_category3  = [category3 copy];
		w_category4  = [category4 copy];
		w_category5  = [category5 copy];
		w_category6  = [category6 copy];
		w_category7  = [category7 copy];
		w_category8  = [category8 copy];
		w_category9  = [category9 copy];
		w_category10 = [category10 copy];
	}
	
	return self;
}


+(id) newWithCategories:(NSArray*)categories {
	return [self newWithCategory1:[categories wtOptionalObjectAtIndex:0]
						category2:[categories wtOptionalObjectAtIndex:1]
						category3:[categories wtOptionalObjectAtIndex:2]
						category4:[categories wtOptionalObjectAtIndex:3]
						category5:[categories wtOptionalObjectAtIndex:4]
						category6:[categories wtOptionalObjectAtIndex:5]
						category7:[categories wtOptionalObjectAtIndex:6]
						category8:[categories wtOptionalObjectAtIndex:7]
						category9:[categories wtOptionalObjectAtIndex:8]
					   category10:[categories wtOptionalObjectAtIndex:9]];
}


+(id) newWithCategory1:(NSString*)category1 {
	return [self newWithCategory1:category1 category2:nil category3:nil category4:nil category5:nil category6:nil category7:nil category8:nil category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 {
	return [self newWithCategory1:category1 category2:category2 category3:nil category4:nil category5:nil category6:nil category7:nil category8:nil category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 {
	return [self newWithCategory1:category1 category2:category2 category3:category3 category4:nil category5:nil category6:nil category7:nil category8:nil category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 {
	return [self newWithCategory1:category1 category2:category2 category3:category3 category4:category4 category5:nil category6:nil category7:nil category8:nil category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 category5:(NSString*)category5 {
	return [self newWithCategory1:category1 category2:category2 category3:category3 category4:category4 category5:category5 category6:nil category7:nil category8:nil category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 category5:(NSString*)category5 category6:(NSString*)category6 {
	return [self newWithCategory1:category1 category2:category2 category3:category3 category4:category4 category5:category5 category6:category6 category7:nil category8:nil category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 category5:(NSString*)category5 category6:(NSString*)category6 category7:(NSString*)category7 {
	return [self newWithCategory1:category1 category2:category2 category3:category3 category4:category4 category5:category5 category6:category6 category7:category7 category8:nil category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 category5:(NSString*)category5 category6:(NSString*)category6 category7:(NSString*)category7 category8:(NSString*)category8 {
	return [self newWithCategory1:category1 category2:category2 category3:category3 category4:category4 category5:category5 category6:category6 category7:category7 category8:category8 category9:nil category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 category5:(NSString*)category5 category6:(NSString*)category6 category7:(NSString*)category7 category8:(NSString*)category8 category9:(NSString*)category9 {
	return [self newWithCategory1:category1 category2:category2 category3:category3 category4:category4 category5:category5 category6:category6 category7:category7 category8:category8 category9:category9 category10:nil];
}


+(id) newWithCategory1:(NSString*)category1 category2:(NSString*)category2 category3:(NSString*)category3 category4:(NSString*)category4 category5:(NSString*)category5 category6:(NSString*)category6 category7:(NSString*)category7 category8:(NSString*)category8 category9:(NSString*)category9 category10:(NSString*)category10 {
	category1 = [category1 wtNonEmpty];
	category2 = [category2 wtNonEmpty];
	category3 = [category3 wtNonEmpty];
	category4 = [category4 wtNonEmpty];
	category5 = [category5 wtNonEmpty];
	category6 = [category6 wtNonEmpty];
	category7 = [category7 wtNonEmpty];
	category8 = [category8 wtNonEmpty];
	category9 = [category9 wtNonEmpty];
	category10 = [category10 wtNonEmpty];
	
	if (category1 == nil &&
		category2 == nil &&
		category3 == nil &&
		category4 == nil &&
		category5 == nil &&
		category6 == nil &&
		category7 == nil &&
		category8 == nil &&
		category9 == nil &&
		category10 == nil) {
		return nil;
	}
	
	return [[self alloc] initWithCategory1:category1
								 category2:category2
								 category3:category3
								 category4:category4
								 category5:category5
								 category6:category6
								 category7:category7
								 category8:category8
								 category9:category9
								category10:category10];
}

@end
