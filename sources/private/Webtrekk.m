#import "Webtrekk-Private.h"

#import "NSMutableDictionary+Webtrekk.h"
#import "NSString+Webtrekk.h"
#import "WTQueue.h"

static NSString* const kVersion = @"2.0";

static const NSTimeInterval kDefaultSendDelay              = 5 * 60; // five minutes
static const NSTimeInterval kInitialSendDelay              = 5;      // five seconds
static const NSTimeInterval kMaximumSessionHibernationTime = 60;     // one minute. minimum time the app must be in the background to cause a new session when moving to foreground again

static NSString* const kOptedOutProperty = @"Webtrekk.optedOut";

static NSString* const kParameterClickId      = @"ct";
static NSString* const kParameterPixel        = @"p";    // format: <version>,<contentId>,<javascript available>,<screen resolution>,<screen color depth>,<cookies available>,<timestamp>,<referer>,<browser size>,<java available>
static NSString* const kParameterEverId       = @"eid";
static NSString* const kParameterSamplingRate = @"ps";
static NSString* const kParameterSessionId    = @"sid";
static NSString* const kParameterUserAgent    = @"X-WT-UA";



@implementation Webtrekk {
	
	NSURL*     m_baseUrl;
	NSString*  m_everId;
	NSDate*    m_hibernationDate;
	id         m_hibernationObserver;
	BOOL       m_isFirstSession;
	BOOL       m_isSampling;
	WTQueue*   m_queue;
	BOOL       m_optedOut;
	NSUInteger m_samplingRate;
	NSString*  m_sessionId;
	BOOL       m_started;
	NSString*  m_userAgent;
	id         m_wakeupObserver;
	
}



-(void) applicationDidEnterBackground {
	WTDebug(@"Application did enter background.");
	
	if (m_started) {
		m_hibernationDate = [NSDate date];
	}
}


-(void) applicationWillEnterForeground {
	WTDebug(@"Application will enter foreground.");
	
	if (m_started && m_hibernationDate != nil) {
		if (-[m_hibernationDate timeIntervalSinceNow] > kMaximumSessionHibernationTime) {
			WTDebug(@"Setting up new session...");
			
			m_isFirstSession = FALSE;
			m_sessionId      = nil;
			
			[self setupSessionId];
		}
		
		m_hibernationDate = nil;
	}
}


+(dispatch_queue_t) dispatchQueue {
	static dispatch_queue_t dispatchQueue;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dispatchQueue = dispatch_queue_create("webtrekk.queue", DISPATCH_QUEUE_SERIAL);
	});
	
	return dispatchQueue;
}


+(NSString*) everId {
	return self.sharedInstance->m_everId;
}


-(id) init {
	// this is a private party ;)
	return nil;
}


-(id) initPrivate {
	if ((self = [super init])) {
		[self setupEverId];
		[self setupOptedOut];
		[self setupUserAgent];
	}
	
	return self;
}


+(BOOL) optedOut {
	__block BOOL optedOut;
	dispatch_sync(self.dispatchQueue, ^{
		optedOut = self.sharedInstance->m_optedOut;
	});
	
	return optedOut;
}


-(void) setOptedOut:(BOOL)optedOut {
	if (m_optedOut == optedOut) {
		return;
	}
	
	m_optedOut = optedOut;
	
	[NSUserDefaults.standardUserDefaults setBool:optedOut forKey:kOptedOutProperty];
	
	if (optedOut) {
		[m_queue clear];
	}
}


+(void) setOptedOut:(BOOL)optedOut {
	dispatch_sync(self.dispatchQueue, ^{
		[self.sharedInstance setOptedOut:optedOut];
	});
}


-(void) setupBaseUrlWithServerUrl:(NSURL*)serverUrl trackId:(NSString*)trackId {
	m_baseUrl = [[serverUrl URLByAppendingPathComponent:trackId] URLByAppendingPathComponent:@"wt.pl"];
	
	WTDebug(@"baseUrl = %@", m_baseUrl);
}


-(void) setupEverId {
	NSString* everId;
	BOOL      isFirstSession;
	
	NSFileManager* fileManager = NSFileManager.defaultManager;
	
	NSURL* fileUrl    = [[fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:FALSE error:NULL] URLByAppendingPathComponent:@"webtrekk-id"];
	NSURL* oldFileUrl = [[fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:FALSE error:NULL] URLByAppendingPathComponent:@"webtrekk-id"];
	
	if ([fileManager fileExistsAtPath:oldFileUrl.path]) {
		[fileManager removeItemAtURL:fileUrl error:NULL];
		[fileManager moveItemAtURL:oldFileUrl toURL:fileUrl error:NULL];
	}
	
	everId = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:NULL];
	if (everId.length == 0) {
		everId = [NSString stringWithFormat:@"%06u%06u%07u", arc4random() % 1000000, arc4random() % 1000000, arc4random() % 10000000];
		[everId writeToURL:fileUrl atomically:TRUE encoding:NSUTF8StringEncoding error:NULL];
		
		isFirstSession = TRUE;
	}
	else {
		isFirstSession = FALSE;
	}
	
	m_everId         = everId;
	m_isFirstSession = isFirstSession;
	
	WTDebug(@"everId = %@", m_everId);
}


-(void) setupLifecycleHandler {
	m_hibernationObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification
																			object:nil
																			 queue:NSOperationQueue.mainQueue
																		usingBlock:
							 ^(NSNotification* notification) {
								 dispatch_sync(self.class.dispatchQueue, ^{
									 [self applicationDidEnterBackground];
								 });
							 }];
	
	m_wakeupObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillEnterForegroundNotification
																	   object:nil
																		queue:NSOperationQueue.mainQueue
																   usingBlock:
						^(NSNotification* notification) {
							dispatch_sync(self.class.dispatchQueue, ^{
								[self applicationWillEnterForeground];
							});
						}];
}


-(void) setupOptedOut {
	m_optedOut = [NSUserDefaults.standardUserDefaults boolForKey:kOptedOutProperty];
	
	WTDebug(@"optedOut = %@", m_optedOut ? @"true" : @"false");
}


-(void) setupQueueWithTrackId:(NSString*)trackId sendDelay:(NSTimeInterval)sendDelay {
	NSFileManager* fileManager = NSFileManager.defaultManager;
	
	NSURL* cachesUrl  = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:FALSE error:NULL];
	NSURL* fileUrl    = [cachesUrl URLByAppendingPathComponent:@"webtrekk-queue"];
	NSURL* oldFileUrl = [cachesUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"webtrekk-%@", [trackId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	if ([fileManager fileExistsAtPath:oldFileUrl.path]) {
		[fileManager removeItemAtURL:fileUrl error:NULL];
		[fileManager moveItemAtURL:oldFileUrl toURL:fileUrl error:NULL];
	}
	
	m_queue = [WTQueue newWithBackupFileUrl:fileUrl initialSendDelay:MIN(kInitialSendDelay,sendDelay) sendDelay:sendDelay];
}


-(void) setupSamplingWithRate:(NSUInteger)samplingRate {
	NSFileManager* fileManager = NSFileManager.defaultManager;
	
	NSURL* fileUrl    = [[fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:FALSE error:NULL] URLByAppendingPathComponent:@"webtrekk-sampling"];
	NSURL* oldFileUrl = [[fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:FALSE error:NULL] URLByAppendingPathComponent:@"webtrekk-sampling"];
	
	if ([fileManager fileExistsAtPath:oldFileUrl.path]) {
		[fileManager removeItemAtURL:fileUrl error:NULL];
		[fileManager moveItemAtURL:oldFileUrl toURL:fileUrl error:NULL];
	}
	
	NSString* data = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:NULL];
	if (data.length > 0) {
		NSArray* components = [data componentsSeparatedByString:@"|"];
		BOOL       isSampling       = [[components objectAtIndex:0] boolValue];
		NSUInteger lastSamplingRate = [[components objectAtIndex:1] integerValue];
		
		if (lastSamplingRate == samplingRate) {
			m_isSampling   = isSampling;
			m_samplingRate = samplingRate;
			
			return;
		}
	}
	
	BOOL isSampling = (samplingRate == 0 || arc4random() % samplingRate == 0);
	
	data = [NSString stringWithFormat:@"%u|%u", (isSampling ? 1 : 0), samplingRate];
	[data writeToURL:fileUrl atomically:TRUE encoding:NSUTF8StringEncoding error:NULL];
	
	m_isSampling   = isSampling;
	m_samplingRate = samplingRate;
	
	WTDebug(@"isSampling = %@, samplingRate = %u", (m_isSampling ? @"true" : @"false"), m_samplingRate);
}


-(void) setupSessionId {
	if (m_isFirstSession) {
		m_sessionId = m_everId;
	}
	else {
		m_sessionId = [NSString stringWithFormat:@"%06u%06u%07u", arc4random() % 1000000, arc4random() % 1000000, arc4random() % 10000000];
	}
	
	WTDebug(@"sessionId = %@", m_sessionId);
}


-(void) setupUserAgent {
	UIDevice* device = UIDevice.currentDevice;
	NSLocale* locale = NSLocale.currentLocale;
	
	m_userAgent = [NSString stringWithFormat:@"Tracking Library %@ (%@; %@ %@; %@)",
				   self.class.version, device.model, device.systemName, device.systemVersion, locale.localeIdentifier];
	
	WTDebug(@"userAgent = %@", m_userAgent);
}


+(Webtrekk*) sharedInstance {
	static Webtrekk* sharedInstance;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] initPrivate];
	});
	
	return sharedInstance;
}


+(void) startWithServerUrl:(NSURL*)serverUrl trackId:(NSString*)trackId {
	[self startWithServerUrl:serverUrl trackId:trackId samplingRate:0 sendDelay:kDefaultSendDelay];
}


+(void) startWithServerUrl:(NSURL*)serverUrl trackId:(NSString*)trackId samplingRate:(NSUInteger)samplingRate {
	[self startWithServerUrl:serverUrl trackId:trackId samplingRate:samplingRate sendDelay:kDefaultSendDelay];
}


+(void) startWithServerUrl:(NSURL*)serverUrl trackId:(NSString*)trackId samplingRate:(NSUInteger)samplingRate sendDelay:(NSTimeInterval)sendDelay {
	dispatch_sync(self.class.dispatchQueue, ^{
		[self.sharedInstance startWithServerUrl:serverUrl trackId:trackId samplingRate:samplingRate sendDelay:sendDelay];
	});
}


-(void) startWithServerUrl:(NSURL*)serverUrl trackId:(NSString*)trackId samplingRate:(NSUInteger)samplingRate sendDelay:(NSTimeInterval)sendDelay {
	if (serverUrl == nil) {
		WTWarn(@"Cannot start tracking: No server URL given.");
		return;
	}
	if (trackId.length == 0) {
		WTWarn(@"Cannot start tracking: No track id given.");
		return;
	}
	if (sendDelay < 1) {
		WTWarn(@"Cannot start tracking: Send delay must be at least one second.");
		return;
	}
	
	if (m_started) {
		[self stop];
	}
	
	WTDebug(@"Starting tracking...");
	
	[self setupBaseUrlWithServerUrl:serverUrl trackId:trackId];
	[self setupQueueWithTrackId:trackId sendDelay:sendDelay];
	[self setupSamplingWithRate:samplingRate];
	[self setupSessionId];
	[self setupLifecycleHandler];
	
	m_started = TRUE;
	
	WTDebug(@"Tracking started!");
}


+(void) stop {
	dispatch_sync(self.class.dispatchQueue, ^{
		[self.sharedInstance stop];
	});
}


-(void) stop {
	if (!m_started) {
		WTWarn(@"Cannot stop tracking as it isn't running.");
		return;
	}
	
	WTDebug(@"Stopping tracking...");
	
	[m_queue stop];
	
	[NSNotificationCenter.defaultCenter removeObserver:m_hibernationObserver];
	[NSNotificationCenter.defaultCenter removeObserver:m_wakeupObserver];
	
	m_baseUrl             = nil;
	m_hibernationDate     = nil;
	m_hibernationObserver = nil;
	m_isFirstSession      = FALSE;
	m_isSampling          = FALSE;
	m_queue               = nil;
	m_samplingRate        = 0;
	m_sessionId           = nil;
	m_wakeupObserver      = nil;
	
	m_started = FALSE;
	
	WTDebug(@"Tracking stopped!");
}


+(void) trackClick:(NSString*)clickId contentId:(NSString*)contentId {
	[self trackClick:clickId contentId:contentId additionalParameters:nil];
}


+(void) trackClick:(NSString*)clickId contentId:(NSString*)contentId additionalParameters:(NSDictionary*)additionalParameters {
	dispatch_sync(self.class.dispatchQueue, ^{
		[self.sharedInstance trackClick:clickId contentId:contentId additionalParameters:additionalParameters];
	});
}


-(void) trackClick:(NSString*)clickId contentId:(NSString*)contentId additionalParameters:(NSDictionary*)additionalParameters {
	// sanity checks for click id
	if (![clickId isKindOfClass:NSString.class]) {
		WTWarn(@"Got tracking event with a click id which is not a string but %@. Will ignore it.", NSStringFromClass([clickId class]));
		return;
	}
	
	[self trackContent:contentId additionalParameters:[NSMutableDictionary wtDictionaryWithDictionary:additionalParameters andObject:clickId forKey:kParameterClickId]];
}


+(void) trackContent:(NSString*)contentId {
	[self trackContent:contentId additionalParameters:nil];
}


+(void) trackContent:(NSString*)contentId additionalParameters:(NSDictionary*)additionalParameters {
	dispatch_sync(self.class.dispatchQueue, ^{
		[self.sharedInstance trackContent:contentId additionalParameters:additionalParameters];
	});
}


-(void) trackContent:(NSString*)contentId additionalParameters:(NSDictionary*)additionalParameters {
	// sanity check for content id
	if (![contentId isKindOfClass:NSString.class]) {
		WTWarn(@"Got tracking event with a content id which is not a string but %@. Will ignore it.", NSStringFromClass([contentId class]));
		return;
	}
	
	NSString* pixel = [NSString stringWithFormat:@"210,%@,0,0,0,0,%.0f", [contentId wtStringByEscapingUrlParameter], [[NSDate date] timeIntervalSince1970]];
	
	[self trackEventWithParameters:[NSMutableDictionary wtDictionaryWithDictionary:additionalParameters andObject:pixel forKey:kParameterPixel]];
}


+(void) trackEventWithParameters:(NSDictionary*)parameters {
	dispatch_sync(self.class.dispatchQueue, ^{
		[self.sharedInstance trackEventWithParameters:parameters];
	});
}


-(void) trackEventWithParameters:(NSDictionary*)parameters {
	if (!m_started) {
		WTWarn(@"Cannot track event as tracking is not started.");
		return;
	}
	
	if (m_optedOut || !m_isSampling) {
		return;
	}
	
	// sanity checks for parameters. you never now and don't want the tracking library to crash the whole app!
	if (![parameters isKindOfClass:NSDictionary.class]) {
		WTWarn(@"Got tracking event parameters which are not a dictionary but %@. Will ignore the request.", NSStringFromClass([parameters class]));
		return;
	}
	for (id parameterName in parameters) {
		id invalidObject = nil;
		if (![parameterName isKindOfClass:NSString.class]) {
			invalidObject = parameterName;
		}
		else {
			id parameterValue = [parameters objectForKey:parameterName];
			if (![parameterValue isKindOfClass:NSString.class]) {
				invalidObject = parameterValue;
			}
		}
		
		if (invalidObject != nil) {
			WTWarn(@"Dictionary with tracking event parameters must only contain strings. Got %@ somewhere and will ignore the request.", NSStringFromClass([invalidObject class]));
			return;
		}
	}
	
	NSMutableDictionary* allParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	[allParameters setObject:m_everId                                          forKey:kParameterEverId];
	[allParameters setObject:[NSString stringWithFormat:@"%u", m_samplingRate] forKey:kParameterSamplingRate];
	[allParameters setObject:m_sessionId                                       forKey:kParameterSessionId];
	[allParameters setObject:m_userAgent                                       forKey:kParameterUserAgent];
	
	NSMutableString* url = [NSMutableString stringWithString:m_baseUrl.absoluteString];
	
	BOOL appendedParameters = FALSE;
	
	NSString* dataParameter = [allParameters objectForKey:kParameterPixel];
	if (dataParameter != nil) {
		// pixel parameter must come first if present
		// pixel parameter must not be URL-encoded - its parts are already encoded
		
		[allParameters removeObjectForKey:kParameterPixel];
		
		[url appendString:@"?"];
		[url appendString:[kParameterPixel wtStringByEscapingUrlParameter]];
		[url appendString:@"="];
		[url appendString:dataParameter];
		
		appendedParameters = TRUE;
	}
	
	for (NSString* parameterName in allParameters) {
        if ([parameterName isEqualToString:kParameterPixel]) {
			// handled above
			continue;
		}
		
		if (appendedParameters) {
            [url appendString:@"&"];
		}
		else {
            [url appendString:@"?"];
			appendedParameters = TRUE;
		}
        
		NSString* parameterValue = [allParameters objectForKey:parameterName];
		
		[url appendString:[parameterName wtStringByEscapingUrlParameter]];
		[url appendString:@"="];
		[url appendString:[parameterValue wtStringByEscapingUrlParameter]];
	}
	
	WTDebug(@"Tracking: %@", url);
	
	[m_queue addUrl:url];
}


+(NSString*) version {
	return kVersion;
}

@end
