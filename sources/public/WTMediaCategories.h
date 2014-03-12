// Webtrekk Library: Categories for Media Tracking

#import <Foundation/Foundation.h>


@interface WTMediaCategories : NSObject

@property(nonatomic,readonly) NSString* category1;
@property(nonatomic,readonly) NSString* category2;
@property(nonatomic,readonly) NSString* category3;
@property(nonatomic,readonly) NSString* category4;
@property(nonatomic,readonly) NSString* category5;
@property(nonatomic,readonly) NSString* category6;
@property(nonatomic,readonly) NSString* category7;
@property(nonatomic,readonly) NSString* category8;
@property(nonatomic,readonly) NSString* category9;
@property(nonatomic,readonly) NSString* category10;

// just to make the library user's life easier :)
// you can pass nil for any category you don't use

+(id) newWithCategories:(NSArray*)categories; // <NSString>

+(id) newWithCategory1:(NSString*)category1;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3
			 category4:(NSString*)category4;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3
			 category4:(NSString*)category4
			 category5:(NSString*)category5;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3
			 category4:(NSString*)category4
			 category5:(NSString*)category5
			 category6:(NSString*)category6;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3
			 category4:(NSString*)category4
			 category5:(NSString*)category5
			 category6:(NSString*)category6
			 category7:(NSString*)category7;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3
			 category4:(NSString*)category4
			 category5:(NSString*)category5
			 category6:(NSString*)category6
			 category7:(NSString*)category7
			 category8:(NSString*)category8;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3
			 category4:(NSString*)category4
			 category5:(NSString*)category5
			 category6:(NSString*)category6
			 category7:(NSString*)category7
			 category8:(NSString*)category8
			 category9:(NSString*)category9;

+(id) newWithCategory1:(NSString*)category1
			 category2:(NSString*)category2
			 category3:(NSString*)category3
			 category4:(NSString*)category4
			 category5:(NSString*)category5
			 category6:(NSString*)category6
			 category7:(NSString*)category7
			 category8:(NSString*)category8
			 category9:(NSString*)category9
			category10:(NSString*)category10;

@end
