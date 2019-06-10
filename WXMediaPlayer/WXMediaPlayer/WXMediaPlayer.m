//
//  WXMediaPlayer.m
//  WXMediaPlayerKit
//
//  Created by Akira Matsuda on 2014/01/10.
//  Copyright (c) 2014年 Akira Matsuda. All rights reserved.
//

#import "WXMediaPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

// --- notification ---
NSString *const WXMediaPlayerPauseNotification = @"WXMediaPlayerPauseNotification";
NSString *const WXMediaPlayerStopNotification = @"WXMediaPlayerStopNotification";

// --- player item KVO observer keypath ---
NSString *const kWXLoadedTimeRanges = @"loadedTimeRanges"; // for load time ranges
NSString *const kWXPlaybackBufferEmpty = @"playbackBufferEmpty"; //for buffer empty
NSString *const kWXItemStatus = @"status"; //for play's status

// --- start play load values ---
NSString *const kWXTracks = @"tracks";

static void *AudioControllerBufferingObservationContext = &AudioControllerBufferingObservationContext;

@interface WXMediaPlayer () {
	NSMutableArray *_queue;

    AVPlayer    *_player;
    id          _playerObserver;
	WXMediaPlaybackState _playbackState;
    WXMediaItem          *_nowPlayingItem;
    
}
@property (nonatomic, strong) NSMutableArray *currentQueue;


@end

@implementation WXMediaPlayer

@synthesize playbackState = _playbackState;

static WXMediaPlayer *sharedPlayer;

+ (instancetype)sharedPlayer
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedPlayer = [[self class] new];
	});

	return sharedPlayer;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_player = [AVPlayer new];
		_queue = [NSMutableArray new];
		self.currentQueue = _queue;
        
        NSLog(@"-----------------------------");
        NSLog(@"init live player version:%@ ,builder:%@",WXMediaPlayerSDKVersionStr,WXMediaPlayerSDKBuildNumberStr);
        NSLog(@"-----------------------------");
        
		_repeatMode = WXMediaRepeatModeDefault;
		_shuffleMode = YES;
		_currentAudioSessionCategory = AVAudioSessionCategoryPlayback;
        
        [self addWXPlayerNotifications];
	}

	return self;
}

- (void)dealloc
{
	self.delegate = nil;
    
    [self removeWXPlayerNotifications];
    
    [self removeWXPlayerItemObservers];
}


- (void)addWXPlayerItemObservers{
    
    @try {
        if (self.corePlayer.currentItem) {
            [self.corePlayer.currentItem addObserver:self forKeyPath:kWXLoadedTimeRanges options:NSKeyValueObservingOptionNew context:AudioControllerBufferingObservationContext];
            [self.corePlayer.currentItem addObserver:self forKeyPath:kWXPlaybackBufferEmpty options:NSKeyValueObservingOptionNew context:AudioControllerBufferingObservationContext];
            [self.corePlayer.currentItem addObserver:self forKeyPath:kWXItemStatus options:NSKeyValueObservingOptionNew context:AudioControllerBufferingObservationContext];
        }
    } @catch (NSException *exception) {
        NSLog(@"[EXCEPTION] %@",exception);
    } @finally {
        
    }
}


- (void)removeWXPlayerItemObservers
{
    if (self.corePlayer.currentItem) {
        @try {
            [self.corePlayer.currentItem removeObserver:self forKeyPath:kWXLoadedTimeRanges context:AudioControllerBufferingObservationContext];
            [self.corePlayer.currentItem removeObserver:self forKeyPath:kWXPlaybackBufferEmpty context:AudioControllerBufferingObservationContext];
            [self.corePlayer.currentItem removeObserver:self forKeyPath:kWXItemStatus context:AudioControllerBufferingObservationContext];
            
        } @catch (NSException *exception) {
            NSLog(@"[EXCEPTION] exception = %@",exception);
        }
    }
}

-(void)addWXPlayerNotifications{
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(pause) name:WXMediaPlayerPauseNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(stop) name:WXMediaPlayerStopNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

-(void)removeWXPlayerNotifications{
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:WXMediaPlayerPauseNotification object:nil];
    [notificationCenter removeObserver:self name:WXMediaPlayerStopNotification object:nil];
    [notificationCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

#pragma mark -

- (AVPlayer *)corePlayer
{
	return _player;
}

- (void)pauseOtherPlayer
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:WXMediaPlayerPauseNotification object:nil];
	[notificationCenter postNotificationName:WXMediaPlayerPauseNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(pause) name:WXMediaPlayerPauseNotification object:nil];
}

- (void)stopOtherPlayer
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:WXMediaPlayerStopNotification object:nil];
	[notificationCenter postNotificationName:WXMediaPlayerStopNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(stop) name:WXMediaPlayerStopNotification object:nil];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	AVPlayerItem *item = notification.object;
	if (_player.currentItem == item) {
		[self playNextMedia];
	}
}

- (void)addMedia:(WXMediaItem *)media
{
	[self.currentQueue addObject:media];
}

- (void)removeMediaAtIndex:(NSUInteger)index
{
	WXMediaItem *item = _currentQueue[index];
	if (item == _nowPlayingItem) {
		_nowPlayingItem = nil;
		[self playNextMedia];
	}
	[self.currentQueue removeObjectAtIndex:index];
}

- (void)replaceMediaAtIndex:(WXMediaItem *)media index:(NSInteger)index
{
	WXMediaItem *item = _currentQueue[index];
	if (item == _nowPlayingItem) {
		_nowPlayingItem = nil;
	}
	[self.currentQueue replaceObjectAtIndex:index withObject:media];
}

- (void)removeAlWXediaInQueue
{
	_nowPlayingItem = nil;
	[self stop];
	[self.currentQueue removeAllObjects];
}

- (void)setQueue:(NSArray *)queue
{
	for (WXMediaItem *item in queue) {
		[_queue addObject:item];
	}
	self.currentQueue = _queue;
}

- (void)updateLockScreenInfo
{
	NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
	[songInfo setObject:[_nowPlayingItem title] ?: @"" forKey:MPMediaItemPropertyTitle];
	[songInfo setObject:[_nowPlayingItem albumTitle] ?: @"" forKey:MPMediaItemPropertyAlbumTitle];
	[songInfo setObject:[_nowPlayingItem artist] ?: @"" forKey:MPMediaItemPropertyArtist];
	[songInfo setObject:@([self currentPlaybackTime]) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
	[songInfo setObject:@([self currentPlaybackDuration]) forKey:MPMediaItemPropertyPlaybackDuration];
	UIImage *artworkImage = [_nowPlayingItem artworkImageWithSize:CGSizeMake(320, 320)];
	if (artworkImage) {
		MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:artworkImage];
		[songInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
	}
	[[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

- (void)playMedia:(WXMediaItem *)media
{
    [self stop];
    
	if ([self.delegate respondsToSelector:@selector(mediaPlayerWillStartPlaying:media:)] == NO
        || [self.delegate mediaPlayerWillStartPlaying:self media:media] == YES) {
		if (media != nil) {
			_nowPlayingItem = media;

            [self setCurrentState:WXMediaPlaybackStateLoading];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if([self.delegate respondsToSelector:@selector(mediaPlayerWillStartLoading:media:)]) {
                    [self.delegate mediaPlayerWillStartLoading:self media:_nowPlayingItem];
                }
            });
            
            _player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
            //Setup the delegate for custom URL.
            AVURLAsset *urlAsset = nil;
            
            //-----------------------------
            //NOTICE: 对于scheme为Http的m3u8的流地址，系统会自动创建一个AVAssetResourceLoader代理，设置下面代码无用，不会进入任何回调
//            AVAssetResourceLoader *resourceLoader = urlAsset.resourceLoader;
//            [WXMediaItemStreamingCache addResourceLoader:resourceLoader forAsset:urlAsset];
            //------------------------------
            
            //start load asynchronously
            [urlAsset loadValuesAsynchronouslyForKeys:@[kWXTracks] completionHandler:^{
                //Safely remove any previously added observer before adding new one
                [self removeWXPlayerItemObservers];
                NSError *error = nil;
                
                //check whether tracks has loaded
                AVKeyValueStatus trackStatus = [urlAsset statusOfValueForKey:kWXTracks error:&error];
                switch (trackStatus) {
                    case AVKeyValueStatusLoaded:
                        // Sucessfully loaded, continue processing
                    {
                        NSLog(@"[INFO] already load asset track status: %zd, tracks count = %ld", trackStatus,urlAsset.tracks.count);
                        
                        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:urlAsset];
                        [self.corePlayer replaceCurrentItemWithPlayerItem:item];
                        
                        [self addWXPlayerItemObservers];
                        
                        [self play];
                    }
                        break;
                    case AVKeyValueStatusFailed:
                        // Examine NSError pointer to determine failure
                    {
                        NSLog(@"[FAILED] unable to load asset track status: %zd error: %@", trackStatus, error);
                        [self setCurrentState:WXMediaPlaybackStateStopped];
                        
                        if([self.delegate respondsToSelector:@selector(mediaPlayerDidFailedWithError:player:media:)]) {
                            [self.delegate mediaPlayerDidFailedWithError:error player:self media:_nowPlayingItem];
                        }
                    }
                        break;
                    case AVKeyValueStatusCancelled:
                        // Loading cancelled
                        break;
                    default:
                        // Handle all other cases
                        break;
                }
            }];
        
			__weak WXMediaPlayer *bself = self;
			_playerObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
				if ([bself.delegate respondsToSelector:@selector(mediaPlayerDidChangeCurrentTime:)]) {
					[bself.delegate mediaPlayerDidChangeCurrentTime:bself];
				}
			}];
		}
	}
}

- (void)play
{
	if (_playbackState == WXMediaPlaybackStateStopped) {
		[_player seekToTime:CMTimeMake(0, 1)];
	}
	if (_nowPlayingItem == nil) {
		[self playMedia:self.currentQueue.firstObject];
	}
	else {
		[_player play];
	}

	[self setCurrentState:WXMediaPlaybackStatePlaying];
}

- (void)playAtIndex:(NSInteger)index
{
	_index = MAX(0, MIN(index, self.currentQueue.count - 1));
	[self playMedia:self.currentQueue[_index]];
}

- (void)stop
{
    [self.corePlayer pause];
    [self setCurrentState:WXMediaPlaybackStateStopped];
    if (_nowPlayingItem || self.corePlayer.currentItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(mediaPlayerDidStop:media:)]) {
                [self.delegate mediaPlayerDidStop:self media:_nowPlayingItem];
            }
        });
        
        _nowPlayingItem = nil;
    }
    if (_playerObserver) {
        [_player removeTimeObserver:_playerObserver];
        _playerObserver = NULL;
    }
}

- (void)pause
{
	[_player pause];
	[self setCurrentState:WXMediaPlaybackStatePaused];
}

- (void)playNextMedia
{
	if ([self.delegate respondsToSelector:@selector(mediaPlayerDidFinishPlaying:media:)]) {
		[self.delegate mediaPlayerDidFinishPlaying:self media:_nowPlayingItem];
	}
	if (self.currentQueue.count) {
		if (_repeatMode == WXMediaRepeatModeDefault) {
			if (_index >= self.currentQueue.count - 1) {
				_index = 0;
				[self stop];
			}
			else {
				_index++;
				[self playMedia:self.currentQueue[_index]];
			}
		}
		else if (_repeatMode == WXMediaRepeatModeAll) {
			if (_index >= self.currentQueue.count - 1) {
				_index = 0;
			}
			else {
				_index++;
			}
			[self playMedia:self.currentQueue[_index]];
		}
		else {
			[self playMedia:self.nowPlayingItem];
		}
	}
	else if (_repeatMode == WXMediaRepeatModeOne || _repeatMode == WXMediaRepeatModeAll) {
		[self playMedia:self.nowPlayingItem];
	}
}

- (void)playPreviousMedia
{
	if ([self.delegate respondsToSelector:@selector(mediaPlayerDidFinishPlaying:media:)]) {
		[self.delegate mediaPlayerDidFinishPlaying:self media:_nowPlayingItem];
	}
	if (self.currentQueue.count) {
		if (_repeatMode == WXMediaRepeatModeDefault) {
			if (_index - 1 < 0) {
				_index = 0;
				[self stop];
			}
			else {
				_index--;
				[self playMedia:self.currentQueue[_index]];
			}
		}
		else if (_repeatMode == WXMediaRepeatModeAll) {
			if (_index - 1 < 0) {
				_index = self.currentQueue.count - 1;
			}
			else {
				_index--;
			}
			[self playMedia:self.currentQueue[_index]];
		}
		else {
			[self playMedia:self.currentQueue[_index]];
		}
	}
	else if (_repeatMode == WXMediaRepeatModeOne || _repeatMode == WXMediaRepeatModeAll) {
		[self playMedia:self.nowPlayingItem];
	}
}

- (NSArray *)queue
{
	NSArray *newArray = [self.currentQueue copy];
	return newArray;
}

- (NSUInteger)numberOfQueue
{
	return self.currentQueue.count;
}

- (NSTimeInterval)currentPlaybackTime
{
	return _player.currentTime.value == 0 ? 0 : _player.currentTime.value / _player.currentTime.timescale;
}

- (NSTimeInterval)currentPlaybackDuration
{
	return CMTimeGetSeconds([[_player.currentItem asset] duration]);
}

- (void)seekTo:(NSTimeInterval)time
{
	[_player seekToTime:CMTimeMake(time, 1)];
}

- (void)setShuffleEnabled:(BOOL)enabled
{
	_shuffleMode = enabled;
	if ([self numberOfQueue] > 0 && _shuffleMode) {
		NSMutableArray *newArray = nil;
		self.currentQueue = newArray;
	}
	else {
		self.currentQueue = _queue;
	}

	if ([self.delegate respondsToSelector:@selector(mediaPlayerDidChangeShuffleMode:player:)]) {
		[self.delegate mediaPlayerDidChangeShuffleMode:enabled player:self];
	}
}

- (void)setRepeatMode:(WXMediaRepeatMode)repeatMode
{
	_repeatMode = repeatMode;
	if ([self.delegate respondsToSelector:@selector(mediaPlayerDidChangeRepeatMode:player:)]) {
		[self.delegate mediaPlayerDidChangeRepeatMode:repeatMode player:self];
	}
}

- (WXMediaItem *)nowPlayingItem{
    return _nowPlayingItem;
}

#pragma mark - private

- (void)setCurrentState:(WXMediaPlaybackState)state
{
	if (state == _playbackState) {
		return;
	}

	if ([self.delegate respondsToSelector:@selector(mediaPlayerWillChangeState:)]) {
		[self.delegate mediaPlayerWillChangeState:state];
	}

	if (state == WXMediaPlaybackStatePlaying) {
		NSError *e = nil;
		AVAudioSession *audioSession = [AVAudioSession sharedInstance];
		[audioSession setCategory:self.currentAudioSessionCategory error:&e];
		[audioSession setActive:YES error:&e];
        if (e) {
            NSLog(@"[ERROR] set audioSession category error :%@",e);
        }
	}

	_playbackState = state;
}

- (UIImage *)thumbnailAtTime:(CGFloat)time
{
	AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:[[_player currentItem] asset]];
	imageGenerator.appliesPreferredTrackTransform = YES;
	NSError *error = NULL;
	CMTime ctime = CMTimeMake(time, 1);
	CGImageRef imageRef = [imageGenerator copyCGImageAtTime:ctime actualTime:NULL error:&error];
	UIImage *resultImage = [[UIImage alloc] initWithCGImage:imageRef];
	CGImageRelease(imageRef);

	return resultImage;
}

- (UIImage *)representativeThumbnail
{
	return [self thumbnailAtTime:self.currentPlaybackDuration / 2];
}

- (NSError *)setAudioSessionCategory:(NSString *)category
{
	NSError *e = nil;
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:category error:&e];
	_currentAudioSessionCategory = category;
	return e;
}
#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString*)aPath ofObject:(id)anObject change:(NSDictionary*)aChange context:(void*)aContext {
    
    if (aContext == AudioControllerBufferingObservationContext) {
        AVPlayerItem* playerItem = (AVPlayerItem*)anObject;
        if ([aPath isEqualToString:kWXPlaybackBufferEmpty]) {
            NSLog(@"[ERROR] player isPlaybackBufferEmpty error %@",playerItem.error);
            if (playerItem.isPlaybackBufferEmpty && CMTIME_COMPARE_INLINE(playerItem.currentTime, >, kCMTimeZero) && //video has started
                CMTIME_COMPARE_INLINE(playerItem.currentTime, <, playerItem.duration) //video hasn't reached the end
                ) { //instance variable to track playback state
                // Possible connection loss or connection is too slow.
                [self setCurrentState:WXMediaPlaybackStateLoading];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(mediaPlayerDidBufferEmpty:media:)]) {
                        [self.delegate mediaPlayerDidBufferEmpty:self media:_nowPlayingItem];
                    }
                });
            }
        }
        else if ([aPath isEqualToString:kWXLoadedTimeRanges]){

            NSValue* value = [playerItem.loadedTimeRanges firstObject];
            if(value) {
                CMTimeRange range;
                [value getValue:&range];
                float start = CMTimeGetSeconds(range.start);
                float duration = CMTimeGetSeconds(range.duration);
                
                CGFloat videoAvailable = start + duration;
                CGFloat totalDuration = CMTimeGetSeconds(self.corePlayer.currentItem.asset.duration);
                CGFloat progress = videoAvailable / totalDuration;
                
                // UI must be update on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    if([self.delegate respondsToSelector:@selector(mediaPlayerDidUpdateStreamingProgress:player:media:)]){
                        [self.delegate mediaPlayerDidUpdateStreamingProgress:progress player:self media:_nowPlayingItem];
                    }
                });
            }
        }
        else if ([aPath isEqualToString:kWXItemStatus]){
            
            if([self.delegate respondsToSelector:@selector(mediaPlayerDidEndLoading:media:)]) {
                [self.delegate mediaPlayerDidEndLoading:self media:_nowPlayingItem];
            }
            
            if (playerItem.status == AVPlayerItemStatusFailed) {
                //Possibly show error message or attempt replay from tart
                //Description from the docs:
                //  Indicates that the player can no longer play AVPlayerItem instances because of an error. The error is described by
                //  the value of the player's error property.
                [self setCurrentState:WXMediaPlaybackStateFailed];
                NSLog(@"[ERROR] player occur error %@",playerItem.error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([self.delegate respondsToSelector:@selector(mediaPlayerDidFailedWithError:player:media:)]) {
                        [self.delegate mediaPlayerDidFailedWithError:playerItem.error player:self media:_nowPlayingItem];
                    }
                });
            }
            else if (playerItem.status == AVPlayerItemStatusReadyToPlay){
                
                [_player play];
                if ([self.delegate respondsToSelector:@selector(mediaPlayerDidStartPlaying:media:)]) {
                    [self.delegate mediaPlayerDidStartPlaying:self media:_nowPlayingItem];
                }
            }
        }
    }
}
@end


