#import "SpringBoard.h"

%hook SpringBoard
-(void)noteInterfaceOrientationChanged:(long long)arg1 duration:(double)arg2 logMessage:(id)arg3 {
	%orig;
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"resizeCanvas" object:nil];
}
%end

%hook SBMediaController
-(BOOL)isApplicationActivityActive {
	if(!%orig) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"recreateCanvas" object:@"com.spotify.client" userInfo:@{@"url": @"remove"}];
	}
	return %orig;
}
-(void)_setNowPlayingApplication:(id)arg1 {
	if(!arg1) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"recreateCanvas" object:@"com.spotify.client" userInfo:@{@"url": @"remove"}];
	}
	return %orig;
}
%end

%hook CSCoverSheetViewController
%property (nonatomic, strong) AVQueuePlayer *canvasPlayer;
%property (nonatomic, strong) AVPlayerLayer *canvasPlayerLayer;
%property (nonatomic, strong) AVPlayerLooper *canvasPlayerLooper;
%property (nonatomic, strong) UIImageView *firstFrameView;
%property (nonatomic, assign) BOOL isVisible;
%property (nonatomic, strong) NSMutableArray *items;
%new
-(void)togglePlayer:(NSNotification *)note {
	NSNumber *isPlaying = [[note userInfo] objectForKey:@"isPlaying"];
	// NSLog(@"canvasBackground toggling player for lockscreen isPlaying: %@", isPlaying);
	[isPlaying boolValue] ? [self.canvasPlayer play] : [self.canvasPlayer pause];
	shouldPlayCanvas = [isPlaying boolValue];
}
%new
-(void)resizeCanvas {
	[self.firstFrameView setFrame:[[self view] frame]];
	[self.canvasPlayerLayer setFrame:[[[self view] layer] bounds]];
}
%new
-(void)recreateCanvasPlayer:(NSNotification *)note {
	NSString *currentVideoURL = [[note userInfo] objectForKey:@"currentURL"];
	NSString *nextVideoURL = [[note userInfo] objectForKey:@"nextURL"];
	// NSLog(@"canvasBackground currentURL: %@ nextURL: %@", currentVideoURL, nextVideoURL);
	if(![currentVideoURL isEqualToString:@"remove"]) {
		// NSLog(@"canvasBackground count: %ld", [self.canvasPlayer.items count]);
		for(AVPlayerItem *item in self.canvasPlayer.items) {
			NSLog(@"canvasBackground item: %@", item);
		}
		if([self.canvasPlayer.items count] > 1) {
			NSLog(@"canvasBackground advanced");
			// NSLog(@"canvasBackground count: %ld", [self.canvasPlayer.items count]);
			[self.canvasPlayer advanceToNextItem];
			NSLog(@"canvasBackground currentItem: %@", self.canvasPlayer.currentItem);
		}
		else {
			NSLog(@"canvasBackground didn't advance");
			NSLog(@"canvasBackground count: %ld", [self.canvasPlayer.items count]);
			AVPlayerItem *currentItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:currentVideoURL]];
			[self.canvasPlayer insertItem:currentItem afterItem:nil];
			NSLog(@"canvasBackground count: %ld", [self.canvasPlayer.items count]);
		}
		// self.canvasPlayerLooper = [AVPlayerLooper playerLooperWithPlayer:self.canvasPlayer templateItem:self.canvasPlayer.currentItem];
		// [[NSNotificationCenter defaultCenter] removeObserver:self];
		// NSLog(@"canvasBackground currentItem: %@", self.canvasPlayer.currentItem);
		[[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:self.canvasPlayer.currentItem queue:nil usingBlock:^(NSNotification *note) {
			// NSLog(@"canvasBackground object: %@");
			[self.canvasPlayer.currentItem seekToTime:kCMTimeZero completionHandler:nil];
			[self.canvasPlayer play];
		}];
		// AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[(AVURLAsset *)nextItem.asset URL] options:nil];
		// AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
		// UIImage *firstFrame = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
		// [self.firstFrameView setImage:firstFrame];
		// self.canvasPlayerLooper = [AVPlayerLooper playerLooperWithPlayer:self.canvasPlayer templateItem:self.canvasPlayer.currentItem];
		// [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.canvasPlayer.currentItem];
		if(self.isVisible) {
			// NSLog(@"canvasBackground playing after recreating");
			[self.canvasPlayer play];
		}
	}
	else {
		// NSLog(@"canvasBackground removing");
		[self.firstFrameView setHidden:YES];
		[self.canvasPlayer removeAllItems];
	}
	if(![nextVideoURL isEqualToString:@"remove"]) {
		NSLog(@"canvasBackground inserting");
		AVPlayerItem *nextItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:nextVideoURL]];
		// [self.canvasPlayer removeAllItems];
		[self.canvasPlayer insertItem:nextItem afterItem:nil];
	}
	// for(AVPlayerItem *item in self.canvasPlayer.items) {
	// 	NSLog(@"canvasBackground item: %@", item);
	// }
}
-(void)viewDidLoad {
	%orig;
	// self.firstFrameView = [[UIImageView alloc] init];
	// [self.firstFrameView setFrame:[[self view] frame]];
	// [self.firstFrameView setContentMode:UIViewContentModeScaleAspectFill];
	// [self.firstFrameView setClipsToBounds:YES];
	// [self.firstFrameView setHidden:YES];
	self.canvasPlayer = [[AVQueuePlayer alloc] init];
	self.canvasPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.canvasPlayer];
	[self.canvasPlayer setVolume:0];
	[self.canvasPlayer setPreventsDisplaySleepDuringVideoPlayback:NO];
	[self.canvasPlayer setActionAtItemEnd:AVPlayerActionAtItemEndPause];
	[self.canvasPlayerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[self.canvasPlayerLayer setFrame:[[[self view] layer] bounds]];
	[[[self view] layer] insertSublayer:self.canvasPlayerLayer atIndex:0];
	// [[self view] insertSubview:self.firstFrameView atIndex:0];
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(recreateCanvasPlayer:) name:@"recreateCanvas" object:@"com.spotify.client"];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeCanvas) name:@"resizeCanvas" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(togglePlayer:) name:@"togglePlayer" object:nil];
}
-(void)viewWillAppear:(BOOL)animated {
	%orig;
	// NSLog(@"canvasBackground lockscreen appeared");
	self.isVisible = YES;
	[self resizeCanvas];
	SBMediaController *controller = [%c(SBMediaController) sharedInstance];
	if(![controller isPaused] && ![controller isPlaying]) {
		[self.canvasPlayer removeAllItems];
	}
	if(shouldPlayCanvas)
		[self.canvasPlayer play];
}
-(void)viewDidDisappear:(BOOL)animated {
	%orig;
	// NSLog(@"canvasBackground lockscreen disappeared");
	self.isVisible = NO;
	[self.canvasPlayer pause];
}
%end

// %hook SBHomeScreenViewController
// %property (nonatomic, strong) AVQueuePlayer *canvasPlayer;
// %property (nonatomic, strong) AVPlayerLayer *canvasPlayerLayer;
// %property (nonatomic, strong) AVPlayerLooper *canvasPlayerLooper;
// %property (nonatomic, strong) UIImageView *firstFrameView;
// %property (nonatomic, assign) BOOL isVisible;
// %new
// -(void)togglePlayer:(NSNotification *)note {
// 	NSNumber *isPlaying = [[note userInfo] objectForKey:@"isPlaying"];
// 	NSLog(@"canvasBackground toggling player for lockscreen isPlaying: %@", isPlaying);
// 	[isPlaying boolValue] ? [self.canvasPlayer play] : [self.canvasPlayer pause];
// }
// %new
// -(void)resizeCanvas {
// 	[self.canvasPlayerLayer setFrame:[[[self view] layer] bounds]];
// }
// %new
// -(void)recreateCanvasPlayer:(NSNotification *)note {
// 	NSString *canvasVideoURL = [[note userInfo] objectForKey:@"url"];
// 	if(![canvasVideoURL isEqualToString:@"remove"]) {
// 		NSLog(@"canvasBackground recreating");
// 		[self.firstFrameView setHidden:NO];
// 		[self.canvasPlayer setActionAtItemEnd:AVPlayerActionAtItemEndAdvance];
// 		AVPlayerItem *nextItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:canvasVideoURL]];
// 		AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[(AVURLAsset *)nextItem.asset URL] options:nil];
// 		AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
// 		UIImage *firstFrame = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
// 		[self.firstFrameView setImage:firstFrame];
// 		self.canvasPlayerLooper = [AVPlayerLooper playerLooperWithPlayer:self.canvasPlayer templateItem:nextItem];
// 		if(self.isVisible) {
// 			NSLog(@"canvasBackground playing after recreating");
// 			[self.canvasPlayer play];
// 		}
// 	}
// 	else {
// 		NSLog(@"canvasBackground removing");
// 		[self.firstFrameView setHidden:YES];
// 		[self.canvasPlayer removeAllItems];
// 	}
// }
// -(void)viewDidLoad {
// 	%orig;
// 	self.firstFrameView = [[UIImageView alloc] init];
// 	[self.firstFrameView setFrame:[[self view] frame]];
// 	[self.firstFrameView setContentMode:UIViewContentModeScaleAspectFill];
// 	[self.firstFrameView setClipsToBounds:YES];
// 	[self.firstFrameView setHidden:YES];
// 	self.canvasPlayer = [[AVQueuePlayer alloc] init];
// 	self.canvasPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.canvasPlayer];
// 	[self.canvasPlayer setVolume:0];
// 	[self.canvasPlayer setPreventsDisplaySleepDuringVideoPlayback:NO];
// 	[self.canvasPlayerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
// 	[self.canvasPlayerLayer setFrame:[[[self view] layer] bounds]];
// 	[[[self view] layer] insertSublayer:self.canvasPlayerLayer atIndex:0];
// 	[[self view] insertSubview:self.firstFrameView atIndex:0];
// 	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
// 	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
// 	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(recreateCanvasPlayer:) name:@"recreateCanvas" object:@"com.spotify.client"];
// 	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeCanvas) name:@"resizeCanvas" object:nil];
// 	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(togglePlayer:) name:@"togglePlayer" object:nil];
// }
// -(void)viewWillAppear:(BOOL)animated {
// 	%orig;
// 	NSLog(@"canvasBackground homescreen appeared");
// 	self.isVisible = YES;
// 	[self resizeCanvas];
// 	SBMediaController *controller = [%c(SBMediaController) sharedInstance];
// 	if(![controller isPaused] && ![controller isPlaying]) {
// 		[self.canvasPlayer removeAllItems];
// 	}
// 	[self.canvasPlayer play];
// }
// -(void)viewDidDisappear:(BOOL)animated {
// 	%orig;
// 	NSLog(@"canvasBackground homescreen disappeard");
// 	self.isVisible = NO;
// 	[self.canvasPlayer pause];
// }
// %end