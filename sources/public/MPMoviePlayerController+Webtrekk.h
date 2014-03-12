// Webtrekk Library: Media Tracking

// Note: Media Tracking requires an active Webtrekk tracking session.

// Note: If you get an exception that MPMoviePlayerController does not respond to one of the selectors listed below,
//       then you forgot to add the linker flag -all_load to your project.

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "WTMediaCategories.h"


@interface MPMoviePlayerController (Webtrekk)

// Stops automatic media tracking for this media player.
// You can stop tracking only while `playbackState` is `MPMoviePlaybackStateStopped`.
// Note: You don't usually have to stop tracking.
-(void) wtStopTracking;

// Tracks a custom event at the current playback time.
// Automatic tracking must be started prior to calling this method.
-(void) wtTrackCustomEventWithName: (NSString*)eventName;

// Starts automatic media tracking for this media player controller.
// You can start tracking only while `playbackState` is `MPMoviePlaybackStateStopped`.
-(void) wtTrackWithMediaId: (NSString*)mediaId;
-(void) wtTrackWithMediaId: (NSString*)mediaId mediaCategories:(WTMediaCategories*)mediaCategorties;

@end

// Library developed by Widgetlabs
