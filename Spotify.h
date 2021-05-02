#import <AVKit/AVKit.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <UIKit/UIKit.h>

@interface CSCoverSheetViewController : UIViewController
@property(nonatomic, strong) AVQueuePlayer *canvasPlayer;
@property(nonatomic, strong) AVPlayerLayer *canvasPlayerLayer;
@property(nonatomic, strong) AVPlayerLooper *canvasPlayerLooper;
-(void)recreateCanvasPlayer;
-(void)clearCanvas;
@end
@interface SBMediaController : NSObject
+ (id)sharedInstance;
-(BOOL)isPaused;
-(BOOL)isPlaying;
@end
@interface SPTCanvasTrackCheckerImplementation : NSObject
-(_Bool)isCanvasEnabledForTrack:(id)arg1;
-(void)downloadCanvas:(NSURL *)canvasURL;
@end
@interface SPTStatefulPlayer : NSObject
@property (nonatomic, assign) BOOL previouslyPaused;
- (_Bool)isPaused;
-(id)currentTrack;
-(void)deleteCachedPlayer;
@end
@interface SPTPlayerTrack : NSObject
@property(copy, nonatomic) NSURL *URI;
@end
@interface LSApplicationProxy
+(LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bundleId;
-(NSURL *)containerURL;
@end
@interface SPTCanvasMetadataResolverImplementation : NSObject
-(id)createCanvasRequest;
@end

SPTPlayerTrack *currentTrack;
NSString *downloadedItem;