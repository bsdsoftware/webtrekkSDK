@class WTMediaCategories;

typedef enum {
	WTMediaEventPause,
	WTMediaEventPlay,
	WTMediaEventPosition,
	WTMediaEventSeek,
	WTMediaEventSeekEnd,  // pseudo event. returns the media to the last state before the seeking started (either play or pause)
	WTMediaEventStop,
} WTMediaEvent;

NSString* NSStringFromWTMediaEvent(WTMediaEvent event);


@interface WTMediaSession : NSObject

@property(nonatomic,copy)     NSNumber*          bandwidth;    // nil, 0..
@property(nonatomic,readonly) WTMediaCategories* categories;
@property(nonatomic,readonly) WTMediaEvent       currentState; // only WTMediaEventPause, WTMediaEventPlay, WTMediaEventSeek or WTMediaEventStop
@property(nonatomic,readonly) NSTimeInterval     duration;
@property(nonatomic,readonly) BOOL               ended;
@property(nonatomic,readonly) NSString*          mediaId;
@property(nonatomic,copy)     NSNumber*          muted;        // nil, 0..1
@property(nonatomic,copy)     NSNumber*          volume;       // nil, 0..255 (should be 0..100)

+(WTMediaSession*) startWithMediaId:         (NSString*)mediaId duration:(NSTimeInterval)duration initialPosition:(NSTimeInterval)initialPosition categories:(WTMediaCategories*)categories;
-(void)            trackCustomEventWithName: (NSString*)eventName atPosition:(NSTimeInterval)position;
-(void)            trackEvent:               (WTMediaEvent)event atPosition:(NSTimeInterval)position;

@end
