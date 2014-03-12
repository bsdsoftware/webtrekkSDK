@interface WTQueue : NSObject

-(void) addUrl:               (NSString*)url;
-(void) clear;
+(id)   newWithBackupFileUrl: (NSURL*)backupFileUrl initialSendDelay:(NSTimeInterval)initialSendDelay sendDelay:(NSTimeInterval)sendDelay;
-(void) stop;

@end
