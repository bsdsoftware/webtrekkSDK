#import "WTQueue.h"

// TODO: refactor using GCD

static const NSUInteger     MAXIMUM_URL_COUNT          = 1000;
static const NSTimeInterval NETWORK_CONNECTION_TIMEOUT = 60;      // one minute


@interface WTQueue ()

@property(nonatomic,retain) NSURLConnection* currentConnection;
@property(nonatomic,retain) NSString*        currentUrl;
@property(nonatomic,assign) bool             sendNextRequestQueued;
@property(nonatomic,assign) bool             shutdownRequested;
@property(nonatomic,retain) NSMutableArray*  urls;

@end



@implementation WTQueue {
	
	NSURL*         m_backupFileUrl;
	NSTimeInterval m_initialSendDelay;
	NSUInteger     m_numberOfSuccessfulSends;
	NSTimeInterval m_sendDelay;
	
}

@synthesize currentConnection     = m_currentConnection;
@synthesize currentUrl            = m_currentUrl;
@synthesize sendNextRequestQueued = m_sendNextRequestQueued;
@synthesize shutdownRequested     = m_shutdownRequested;
@synthesize urls                  = m_urls;



-(void) dealloc {
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	[notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification        object:nil];
	[notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification           object:nil];
}


-(void) addUrl:(NSString*)url {
	@synchronized (self) {
		if (self.shutdownRequested) {
			WTDebug(@"[WebtrekkQueue addUrl:] Cannot add url after shutting down.");
			return;
		}
		
		if (self.urls.count >= MAXIMUM_URL_COUNT) {
			[self.urls removeObjectAtIndex:0];
		}
		
		[self.urls addObject:url];
		
		[self sendNextRequestLater];
	}
}


-(void) applicationBecomesInactive {
	WTDebug(@"[WebtrekkQueue applicationBecomesInactive] Application no longer in foreground.");
	
	[self saveBackup];
}


-(void) applicationDidReceiveMemoryWarning {
	WTDebug(@"[WebtrekkQueue applicationDidReceiveMemoryWarning] Application may be killed soon.");
	
	[self saveBackup];
}


-(void) clear {
	@synchronized (self) {
		if (m_urls.count > 0) {
			WTDebug(@"[WebtrekkQueue clear] Dropping %u URLs.", m_urls.count);
			
			[m_urls removeAllObjects];
		}
		
		[self saveBackup];
	}
}


-(void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	@synchronized (self) {
		if (connection != self.currentConnection) {
			return;
		}
		
		bool recoverable = false;
		if ([error.domain isEqualToString:NSURLErrorDomain]) {
			switch (error.code) {
				case NSURLErrorBadServerResponse:
				case NSURLErrorCallIsActive:
				case NSURLErrorCancelled:
				case NSURLErrorCannotConnectToHost:
				case NSURLErrorCannotFindHost:
				case NSURLErrorDataNotAllowed:
				case NSURLErrorDNSLookupFailed:
				case NSURLErrorInternationalRoamingOff:
				case NSURLErrorNetworkConnectionLost:
				case NSURLErrorNotConnectedToInternet:
				case NSURLErrorTimedOut:
				case NSURLErrorZeroByteResource:
					recoverable = true;
					break;
			}
		}
		
		WTDebug(@"[WebtrekkQueue connection:didFailWithError:] Connection failed with error %@.", error);
		
		if (recoverable) {
			// problems with the network. we can wait.
			[self endConnectionAndRemoveUrl:false];
		}
		else {
			// the URL will most likely cause a permanent recursion. we cannot handle that.
			WTDebug(@"[WebtrekkQueue connection:didFailWithError:] Removing URL from queue because error cannot be handled.");
			
			[self endConnectionAndRemoveUrl:true];
		}
	}
}


-(void) connectionDidFinishLoading:(NSURLConnection*)connection {
	@synchronized (self) {
		if (connection != self.currentConnection) {
			return;
		}
		
		WTDebug(@"[WebtrekkQueue connectionDidFinishLoading:] Connection did neither fail nor succeed. This should never happen.");
		
		// problems with this code?! we can wait.
		[self endConnectionAndRemoveUrl:false];
	}
}


-(void) connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response {
	@synchronized (self) {
		if (connection != self.currentConnection) {
			return;
		}
		
		NSInteger statusCode = response.statusCode;
		if (statusCode >= 200 && statusCode <= 299) {
			WTDebug(@"[WebtrekkQueue connection:didReceiveResponse:] Completed request to '%@'.", self.currentUrl);
			
			++m_numberOfSuccessfulSends;
			
			[self endConnectionAndRemoveUrl:true];
		}
		else {
			WTDebug(@"[WebtrekkQueue connection:didReceiveResponse:] Received status %u for '%@'.", statusCode, self.currentUrl);
			
			if (statusCode <= 499 || statusCode >= 600) {
				// client-side error. we cannot handle that.
				WTDebug(@"[WebtrekkQueue connection:didReceiveResponse:] Removing URL from queue because status code cannot be handled.");
				
				[self endConnectionAndRemoveUrl:true];
			}
			else {
				// server-side error. we can wait.
				[self endConnectionAndRemoveUrl:false];
			}
		}
	}
}


-(void) endConnectionAndRemoveUrl:(bool)removeUrl {
	NSString* url = self.currentUrl;
	
	self.currentConnection = nil;
	self.currentUrl        = nil;
	
	if (removeUrl) {
		NSUInteger index = [self.urls indexOfObject:url];
		if (index != NSNotFound) {
			// we don't use removeObject: because the array may contain the url multiple times and we only want to remove the first one
			[self.urls removeObjectAtIndex:index];
		}
		
		if (self.urls.count == 0) {
			// end of burst
			[self performSelectorInBackground:@selector(saveBackup) withObject:nil];
		}
		
		[self sendNextRequest];
	}
	else {
		[self performSelectorInBackground:@selector(saveBackup) withObject:nil];
		
		[self sendNextRequestLater];
	}
}


-(id) initWithBackupFileUrl:(NSURL*)backupFileUrl initialSendDelay:(NSTimeInterval)initialSendDelay sendDelay:(NSTimeInterval)sendDelay {
	if (self = [super init]) {
		m_backupFileUrl    = backupFileUrl;
		m_initialSendDelay = initialSendDelay;
		m_sendDelay        = sendDelay;
		
		self.urls = [NSMutableArray array];
		
		[self loadBackup];
		
		if (self.urls.count > 0) {
			WTDebug(@"[WebtrekkQueue initWithBackupFilePath:] Sending %u backupped requests now.", self.urls.count);
			[self sendNextRequest];
		}
		
		NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:[UIApplication sharedApplication]];
		[notificationCenter addObserver:self selector:@selector(applicationBecomesInactive)         name:UIApplicationWillResignActiveNotification        object:[UIApplication sharedApplication]];
		[notificationCenter addObserver:self selector:@selector(applicationBecomesInactive)         name:UIApplicationWillTerminateNotification           object:[UIApplication sharedApplication]];
	}
	
	return self;
}


-(void) loadBackup {
	@try {
		self.urls = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:m_backupFileUrl.path]];
	}
	@catch (NSException* e) {
		WTDebug(@"[WebtrekkQueue loadBackup] Cannot load backup: %@", e);
	}
}


+(id) newWithBackupFileUrl:(NSURL*)backupFileUrl initialSendDelay:(NSTimeInterval)initialSendDelay sendDelay:(NSTimeInterval)sendDelay {
	return [[self alloc] initWithBackupFileUrl:backupFileUrl initialSendDelay:initialSendDelay sendDelay:sendDelay];
}


-(void) saveBackup {
	@synchronized (self) {
		@autoreleasepool {
			if (self.urls.count > 0) {
				WTDebug(@"[WebtrekkQueue saveBackup] Saving backup.");
				[NSKeyedArchiver archiveRootObject:self.urls toFile:m_backupFileUrl.path];
			}
			else {
				[NSFileManager.defaultManager removeItemAtURL:m_backupFileUrl error:NULL];
			}
		}
	}
}


-(void) sendNextRequest {
	@synchronized (self) {
		if (![NSThread isMainThread]) {
			self.sendNextRequestQueued = true;
			
			// we don't know how long this thread's run loop persists, so we add the connection to the main thread's run loop
			[self performSelectorOnMainThread:@selector(sendNextRequest) withObject:nil waitUntilDone:FALSE];
			return;
		}
		
		self.sendNextRequestQueued = false;
		
		if (self.shutdownRequested) {
			return;
		}
		
		if (self.currentConnection != nil) {
			WTDebug(@"[Webtrekk sendNextRequest] Prevented opening of more than one connection at once. This should not happen.");
			return;
		}
		
		do {
			if (self.urls.count == 0) {
				WTDebug(@"[Webtrekk sendNextRequest] Nothing to do.");
				return;
			}
			
			NSString* url = [self.urls objectAtIndex:0];
			
			NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:NETWORK_CONNECTION_TIMEOUT];
			
			self.currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:TRUE];
			if (self.currentConnection == nil) {
				WTDebug(@"[WebrekkQueue sendNextRequest] Removing invalid URL '%@' from queue.", url);
				
				[self.urls removeObjectAtIndex:0];
			}
			else {
				WTDebug(@"[WebrekkQueue sendNextRequest] Opening connection to '%@'.", url);
				
				self.currentUrl = url;
			}
		}
		while (self.currentConnection == nil);
	}
}


-(void) sendNextRequestLater {
	if (![NSThread isMainThread]) {
		// we don't know how long this thread's run loop persists, so we add the delayed execution to the main thread's run loop
		[self performSelectorOnMainThread:@selector(sendNextRequestLater) withObject:nil waitUntilDone:FALSE];
		return;
	}
	
	@synchronized (self) {
		if (self.shutdownRequested) {
			return;
		}
		
		if (self.currentConnection != nil) {
			return;
		}
		
		if (self.urls.count == 0) {
			return;
		}
		
		if (!self.sendNextRequestQueued) {
			self.sendNextRequestQueued = true;
			
			NSTimeInterval delay;
			if (m_numberOfSuccessfulSends == 0) {
				delay = m_initialSendDelay;
			}
			else {
				delay = m_sendDelay;
			}
			
			[self performSelector:@selector(sendNextRequest) withObject:nil afterDelay:delay];
			
			WTDebug(@"[Webtrekk sendNextRequestLater] Will process next URL in %f seconds.", delay);
		}
	}
}


-(void) stop {
	if (![NSThread isMainThread]) {
		// we don't know on which run loop we are.
		[self performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:TRUE];
		return;
	}
	
	@synchronized (self) {
		if (self.shutdownRequested) {
			return;
		}
		
		self.shutdownRequested = true;
		
		NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		[notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification        object:nil];
		[notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification           object:nil];
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendNextRequest) object:nil];
		
		[self saveBackup];
	}
}

@end
