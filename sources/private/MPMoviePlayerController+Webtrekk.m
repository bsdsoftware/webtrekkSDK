#import "MPMoviePlayerController+Webtrekk.h"

#import "WTMoviePlayerControllerHelper.h"

static int kProperty_helper;


@interface MPMoviePlayerController (WebtrekkPrivate)

@property(nonatomic,strong) WTMoviePlayerControllerHelper* wtHelper;

@end



@implementation MPMoviePlayerController (Webtrekk)

-(void) setWtHelper:(WTMoviePlayerControllerHelper*)helper {
	objc_setAssociatedObject(self, &kProperty_helper, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


-(WTMoviePlayerControllerHelper*) wtHelper {
	return objc_getAssociatedObject(self, &kProperty_helper);
}


-(void) wtStopTracking {
	if (self.playbackState != MPMoviePlaybackStateStopped) {
		WTWarn(@"Cannot stop media tracking unless the controller's `playbackState` is `MPMoviePlaybackStateStopped`. (%@)", self);
		return;
	}
	
	self.wtHelper = nil;
}


-(void) wtTrackCustomEventWithName:(NSString*)eventName {
	if (eventName.length == 0) {
		WTWarn(@"Cannot track custom event without name. (%@)", self);
		return;
	}
	
	WTMoviePlayerControllerHelper* helper = self.wtHelper;
	if (helper == nil) {
		WTWarn(@"Cannot track custom event because tracking was not started. (%@)", self);
		return;
	}
	
	[helper trackCustomEventWithName:eventName];
}


-(void) wtTrackWithMediaId:(NSString*)mediaId {
	[self wtTrackWithMediaId:mediaId mediaCategories:nil];
}


-(void) wtTrackWithMediaId:(NSString*)mediaId mediaCategories:(WTMediaCategories*)mediaCategorties {
	if (self.playbackState != MPMoviePlaybackStateStopped) {
		WTWarn(@"Cannot set up media tracking unless the controller's `playbackState` is `MPMoviePlaybackStateStopped`. (%@)", self);
		return;
	}
	
	if (mediaId != nil && mediaId.length == 0) {
		WTWarn(@"Cannot set empty mediaId. Will disable tracking. (%@)", self);
		[self wtStopTracking];
		return;
	}
	
	WTMoviePlayerControllerHelper* helper = self.wtHelper;
	if (mediaId == helper.mediaId || [mediaId isEqualToString:helper.mediaId]) {
		return;
	}
	
	self.wtHelper = [WTMoviePlayerControllerHelper newWithController:self mediaId:mediaId mediaCategories:mediaCategorties];
}

@end
