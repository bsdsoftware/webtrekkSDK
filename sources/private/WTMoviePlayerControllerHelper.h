@class WTMediaCategories;


@interface WTMoviePlayerControllerHelper : NSObject

@property(nonatomic,readonly) WTMediaCategories* mediaCategories;
@property(nonatomic,readonly) NSString*          mediaId;

+(id)   newWithController:        (MPMoviePlayerController*)controller mediaId:(NSString*)mediaId mediaCategories:(WTMediaCategories*)mediaCategories;
-(void) trackCustomEventWithName: (NSString*)eventName;

@end
