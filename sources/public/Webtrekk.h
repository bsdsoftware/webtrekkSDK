// Webtrekk Library 2.0 beta (2012-10-11)

#import <Foundation/Foundation.h>


@interface Webtrekk : NSObject

@property(nonatomic) BOOL optedOut;

// starts the tracking. should only be called once in your delegate method application:didFinishLaunchingWithOptions:
+(void) startWithServerUrl: (NSURL*)serverUrl trackId:(NSString*)trackId;
+(void) startWithServerUrl: (NSURL*)serverUrl trackId:(NSString*)trackId samplingRate:(NSUInteger)samplingRate;
+(void) startWithServerUrl: (NSURL*)serverUrl trackId:(NSString*)trackId samplingRate:(NSUInteger)samplingRate sendDelay:(NSTimeInterval)sendDelay;

// stops the tracking. you usually don't need to and should not call this.
+(void) stop;

// tracking methods
+(void) trackClick:   (NSString*)clickId contentId:(NSString*)contentId;
+(void) trackClick:   (NSString*)clickId contentId:(NSString*)contentId additionalParameters:(NSDictionary*)additionalParameters;
+(void) trackContent: (NSString*)contentId;
+(void) trackContent: (NSString*)contentId additionalParameters:(NSDictionary*)additionalParameters;

// allows the user to opt out of tracking
+(BOOL) optedOut;
+(void) setOptedOut: (BOOL)optedOut;

// ever id for the current app installation (does not require a tracking session to be started)
+(NSString*) everId;

// library version
+(NSString*) version;

@end

// Library developed by Widgetlabs
