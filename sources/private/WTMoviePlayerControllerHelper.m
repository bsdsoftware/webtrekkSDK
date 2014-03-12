#import "WTMoviePlayerControllerHelper.h"

#import "UIDevice+Webtrekk.h"
#import "WTMediaSession.h"

static const NSTimeInterval kPositionUpdateInterval = 30;


@implementation WTMoviePlayerControllerHelper {
	
	__unsafe_unretained MPMoviePlayerController* w_controller;
	WTMediaSession*                              w_mediaSession;
	NSTimer*                                     w_positionTimer;
	
}

@synthesize mediaCategories = w_mediaCategories;
@synthesize mediaId         = w_mediaId;



-(void) dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self name:nil object:w_controller];
	
	[w_positionTimer invalidate];
}


-(void) handleNotification:(NSNotification*)notification {
	if ([notification.name isEqualToString:MPMoviePlayerPlaybackStateDidChangeNotification]) {
		switch (w_controller.playbackState) {
			case MPMoviePlaybackStateInterrupted:
				break;
				
			case MPMoviePlaybackStatePaused:
				// we have to delay the pause event because it occurrs right before seeking and stopping
				[self performSelector:@selector(handleDelayedPause) withObject:nil afterDelay:0.3];
				break;
				
			case MPMoviePlaybackStatePlaying:
				[self trackEvent:WTMediaEventPlay];
				[self startPositionTimer];
				break;
				
			case MPMoviePlaybackStateSeekingBackward:
			case MPMoviePlaybackStateSeekingForward:
				[self stopPositionTimer];
				[self trackEvent:WTMediaEventSeek];
				break;
				
			case MPMoviePlaybackStateStopped:
				[self stopPositionTimer];
				[self trackEvent:WTMediaEventStop];
				
				break;
		}
	}
	else if ([notification.name isEqualToString:MPMovieDurationAvailableNotification]) {
		[self startMediaSessionIfNecessary];
		
		if (w_controller.playbackState == MPMoviePlaybackStatePlaying) {
			[self trackEvent:WTMediaEventPlay];
		}
	}
	else if ([notification.name isEqualToString:MPMoviePlayerPlaybackDidFinishNotification]) {
		[self trackEvent:WTMediaEventStop];
	}
}


-(void) handleDelayedPause {
	[self stopPositionTimer];
	[self trackEvent:WTMediaEventPause];
}


-(id) initWithController:(MPMoviePlayerController*)controller mediaId:(NSString*)mediaId mediaCategories:(WTMediaCategories*)mediaCategories {
	if ((self = [super init])) {
		w_controller      = controller;
		w_mediaCategories = mediaCategories;
		w_mediaId         = [mediaId copy];
		
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleNotification:) name:nil object:controller];
	}
	
	return self;
}


+(id) newWithController:(MPMoviePlayerController*)controller mediaId:(NSString*)mediaId mediaCategories:(WTMediaCategories*)mediaCategories {
	return [[self alloc] initWithController:controller mediaId:mediaId mediaCategories:mediaCategories];
}


-(void) startMediaSessionIfNecessary {
	if (w_mediaSession != nil) {
		return;
	}
	if (w_controller.duration <= 0) {
		return;
	}
	
	w_mediaSession = [WTMediaSession startWithMediaId:w_mediaId duration:w_controller.duration initialPosition:w_controller.currentPlaybackTime categories:w_mediaCategories];
}


-(void) startPositionTimer {
	if (w_positionTimer != nil) {
		return;
	}
	
	w_positionTimer = [NSTimer scheduledTimerWithTimeInterval:kPositionUpdateInterval target:self selector:@selector(updatePosition) userInfo:nil repeats:TRUE];
}


-(void) stopPositionTimer {
	[w_positionTimer invalidate];
	w_positionTimer = nil;
}


-(void) trackCustomEventWithName:(NSString*)eventName {
	if (w_mediaSession == nil) {
		if (w_controller.duration > 0) {
			// user may have stopped the video and thus the media session. we'll start a new one.
			[self startMediaSessionIfNecessary];
		}
		else {
			WTWarn(@"Cannot track custom event because the video's duration is not available yet.");
			return;
		}
	}
	
	[w_mediaSession trackCustomEventWithName:eventName atPosition:w_controller.currentPlaybackTime];
}


-(void) trackEvent:(WTMediaEvent)event {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleDelayedPause) object:nil];
	
	if (event != WTMediaEventStop) {
		[self startMediaSessionIfNecessary];
	}
	
	if (w_mediaSession == nil || w_mediaSession.currentState == event) {
		return;
	}
	
	MPMovieAccessLogEvent* latestEvent = w_controller.accessLog.events.lastObject;
	if (latestEvent != nil) {
		if (latestEvent.indicatedBitrate >= 1) {
			w_mediaSession.bandwidth = [NSNumber numberWithDouble:latestEvent.indicatedBitrate];
		}
	}
	
	if (!UIDevice.currentDevice.wtIsSimulator) {
		w_mediaSession.volume = [NSNumber numberWithDouble:(MPMusicPlayerController.applicationMusicPlayer.volume * 100)];
	}
	
	[w_mediaSession trackEvent:event atPosition:w_controller.currentPlaybackTime];
	
	if (event == WTMediaEventStop) {
		w_mediaSession = nil;
	}
}


-(void) updatePosition {
	switch (w_controller.playbackState) {
		case MPMoviePlaybackStateInterrupted:
		case MPMoviePlaybackStatePlaying:
			break;
			
		default:
			[self stopPositionTimer];
	}
	
	if (w_mediaSession.currentState == WTMediaEventPlay) {
		[self trackEvent:WTMediaEventPosition];
	}
}

@end
