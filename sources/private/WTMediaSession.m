#import "WTMediaSession.h"

#import "Webtrekk-Private.h"
#import "NSMutableDictionary+Webtrekk.h"
#import "WTMediaCategories.h"


static NSSet* kReservedEventNames;



@implementation WTMediaSession {
	
	WTMediaEvent w_stateBeforeSeeking; // only WTMediaEventPause, WTMediaEventPlay or WTMediaEventStop
	
}

@synthesize bandwidth    = w_bandwidth;
@synthesize categories   = w_categories;
@synthesize currentState = w_currentState;
@synthesize duration     = w_duration;
@synthesize ended        = w_ended;
@synthesize mediaId      = w_mediaId;
@synthesize muted        = w_muted;
@synthesize volume       = w_volume;



-(void) dealloc {
	if (w_currentState != WTMediaEventStop) {
		WTWarn(@"Media session '%@' was deallocated but did not stop.", w_mediaId);
	}
}


+(void) load {
	kReservedEventNames = [NSSet setWithObjects:@"eof", @"init", @"pause", @"play", @"pos", @"seek", @"stop", nil];
}


-(id) initWithMediaId:(NSString*)mediaId duration:(NSTimeInterval)duration initialPosition:(NSTimeInterval)initialPosition categories:(WTMediaCategories*)categories {
	if (duration < 0) {
		WTWarn(@"Duration %g for '%@' is invalid. Clamping to zero.", duration, mediaId);
		duration = 0;
	}
	if (initialPosition < 0) {
		WTWarn(@"Initial position %g for '%@' is invalid. Clamping to zero.", initialPosition, mediaId);
		initialPosition = 0;
	}
	
	if ((self = [super init])) {
		w_currentState = WTMediaEventStop;
		w_categories   = categories;
		w_duration     = duration;
		w_mediaId      = [mediaId copy];
		
		[self trackInitWithPosition:initialPosition];
	}
	
	return self;
}


-(void) setBandwidth:(NSNumber*)bandwidth {
	if (bandwidth != nil) {
		double value = [bandwidth doubleValue];
		if (value < 0 || value > UINT32_MAX) {
			WTWarn(@"Bandwidth must be in range 0..%u.", UINT32_MAX);
			return;
		}
	}
	
	w_bandwidth = [bandwidth copy];
}


-(void) setVolume:(NSNumber*)volume {
	if (volume != nil) {
		double value = [volume doubleValue];
		if (value < 0 || value > 255) {
			WTWarn(@"Bandwidth must be in range 0..255 and should be in range 0..100.");
			return;
		}
	}
	
	w_volume = [volume copy];
}


+(WTMediaSession*) startWithMediaId:(NSString*)mediaId duration:(NSTimeInterval)duration initialPosition:(NSTimeInterval)initialPosition categories:(WTMediaCategories*)categories {
	return [[self alloc] initWithMediaId:mediaId duration:duration initialPosition:initialPosition categories:categories];
}


-(void) trackInitWithPosition:(NSTimeInterval)position {
	NSMutableDictionary* additionalParameters = [NSMutableDictionary dictionary];
	[additionalParameters setObject:[NSString stringWithFormat:@"%u", (NSUInteger)(w_duration + 0.5)] forKey:@"mt2"];
	[additionalParameters wtSetObject:w_categories.category1 forKey:@"mg1"];
	[additionalParameters wtSetObject:w_categories.category2 forKey:@"mg2"];
	[additionalParameters wtSetObject:w_categories.category3 forKey:@"mg3"];
	[additionalParameters wtSetObject:w_categories.category4 forKey:@"mg4"];
	[additionalParameters wtSetObject:w_categories.category5 forKey:@"mg5"];
	[additionalParameters wtSetObject:w_categories.category6 forKey:@"mg6"];
	[additionalParameters wtSetObject:w_categories.category7 forKey:@"mg7"];
	[additionalParameters wtSetObject:w_categories.category8 forKey:@"mg8"];
	[additionalParameters wtSetObject:w_categories.category9 forKey:@"mg9"];
	[additionalParameters wtSetObject:w_categories.category10 forKey:@"mg10"];
	
	[self trackEventWithName:@"init" atPosition:position additionalParameters:additionalParameters];
}


-(void) trackCustomEventWithName:(NSString*)eventName atPosition:(NSTimeInterval)position {
	if (eventName.length == 0) {
		WTWarn(@"Cannot track custom event without name for media session '%@'.", w_mediaId);
		return;
	}
	if ([kReservedEventNames containsObject:eventName]) {
		WTWarn(@"Cannot track custom event '%@' for media session '%@' because the name is reserved.", eventName, w_mediaId);
		return;
	}
	if (position < 0) {
		WTWarn(@"Position %g for '%@' is invalid.", position, w_mediaId);
		return;
	}
	
	if (w_ended) {
		WTWarn(@"Cannot track any more events. Media session '%@' already ended.", w_mediaId);
		return;
	}
	
	[self trackEventWithName:eventName atPosition:position additionalParameters:nil];
}


-(void) trackEvent:(WTMediaEvent)event atPosition:(NSTimeInterval)position {
	if (position < 0) {
		WTWarn(@"Position %g for '%@' is invalid.", position, w_mediaId);
		return;
	}
	
	if (w_ended) {
		WTWarn(@"Cannot track any more events. Media session '%@' already ended.", w_mediaId);
		return;
	}
	
	if (event == WTMediaEventSeekEnd) {
		if (w_currentState != WTMediaEventSeek) {
			WTWarn(@"Cannot track seek end event. Media session '%@' is not seeking.", w_mediaId);
			return;
		}
		
		// stop will become pause, otherwise we'd kill our session.
		if (w_stateBeforeSeeking == WTMediaEventPlay) {
			event = WTMediaEventPlay;
		}
		else {
			event = WTMediaEventPause;
		}
	}
	
	NSString* eventName = @"?";
	switch (event) {
		case WTMediaEventPause:
			if (w_currentState == WTMediaEventPause) {
				WTWarn(@"Cannot track pause event. Media session '%@' is already paused.", w_mediaId);
				return;
			}
			
			eventName = @"pause";
			break;
			
		case WTMediaEventPlay:
			if (w_currentState == WTMediaEventPlay) {
				WTWarn(@"Cannot track play event. Media session '%@' is already playing.", w_mediaId);
				return;
			}
			
			eventName = @"play";
			break;
			
		case WTMediaEventPosition:
			if (w_currentState != WTMediaEventPlay) {
				WTWarn(@"Cannot track position event. Media session '%@' is not playing.", w_mediaId);
				return;
			}
			
			eventName = @"pos";
			break;
			
		case WTMediaEventSeek:
		case WTMediaEventSeekEnd: // never happens - handled above
			if (w_currentState == WTMediaEventSeek) {
				WTWarn(@"Cannot track seek event. Media session '%@' is already seeking.", w_mediaId);
				return;
			}
			
			w_stateBeforeSeeking = w_currentState;
			
			eventName = @"seek";
			break;
			
		case WTMediaEventStop:
			if (w_currentState == WTMediaEventStop) {
				WTWarn(@"Cannot track stop event. Media session '%@' is already stopped.", w_mediaId);
				return;
			}
			
			w_ended = TRUE;
			
			NSUInteger integralPosition = (NSUInteger)(position + 0.5);
			NSUInteger integralDuration = (NSUInteger)(w_duration + 0.5);
			
			if (integralPosition == integralDuration) {
				// natural ending
				eventName = @"eof";
			}
			else {
				// early stop
				eventName = @"stop";
			}
			
			break;
	}
	
	if (event != WTMediaEventPosition) {
		w_currentState = event;
	}
	
	[self trackEventWithName:eventName atPosition:position additionalParameters:nil];
}


-(void) trackEventWithName:(NSString*)name atPosition:(NSTimeInterval)position additionalParameters:(NSDictionary*)additionalParameters {
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithDictionary:additionalParameters];
	[parameters wtSetObject:w_mediaId forKey:@"mi"];
	[parameters wtSetObject:name forKey:@"mk"];
	[parameters setObject:@"314,st" forKey:@"p"];
	[parameters setObject:[NSString stringWithFormat:@"%u", (NSUInteger)(position + 0.5)] forKey:@"mt1"];
	
	if (w_bandwidth != nil) {
		[parameters setObject:[NSString stringWithFormat:@"%u", (NSUInteger)([w_bandwidth doubleValue] + 0.5)] forKey:@"bw"];
	}
	if (w_muted != nil) {
		[parameters setObject:([w_muted boolValue] ? @"1" : @"0") forKey:@"mut"];
	}
	if (w_volume != nil) {
		[parameters setObject:[NSString stringWithFormat:@"%u", [w_volume unsignedIntegerValue]] forKey:@"vol"];
	}
	
	[Webtrekk trackEventWithParameters:parameters];
}

@end




NSString* NSStringFromWTMediaEvent(WTMediaEvent event) {
	switch (event) {
		case WTMediaEventPause:
			return @"WTMediaEventPause";
		case WTMediaEventPlay:
			return @"WTMediaEventPlay";
		case WTMediaEventPosition:
			return @"WTMediaEventPosition";
		case WTMediaEventSeek:
			return @"WTMediaEventSeek";
		case WTMediaEventSeekEnd:
			return @"WTMediaEventSeekEnd";
		case WTMediaEventStop:
			return @"WTMediaEventStop";
	}
	
	return [NSString stringWithFormat:@"%u", event];
}
