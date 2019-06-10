//
//  WXMediaPlayer.h
//  WXMediaPlayerKit
//
//  Created by Akira Matsuda on 2014/01/10.
//  Copyright (c) 2014年 Akira Matsuda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "WXMediaItem.h"

@class WXMediaPlayer;

#define WXMediaPlayerSDKVersionStr @"2.0.0"
#define WXMediaPlayerSDKBuildNumberStr @"12"

typedef NS_ENUM(NSUInteger, WXMediaPlaybackState) {
	WXMediaPlaybackStateStopped,
	WXMediaPlaybackStatePlaying,
	WXMediaPlaybackStatePaused,
    WXMediaPlaybackStateLoading,
    WXMediaPlaybackStateFailed,
};

typedef NS_ENUM(NSUInteger, WXMediaRepeatMode) {
	WXMediaRepeatModeDefault,
	WXMediaRepeatModeOne,
	WXMediaRepeatModeAll,
	WXMediaRepeatModeNone = WXMediaRepeatModeDefault
};

extern NSString *const WXMediaPlayerPauseNotification;
extern NSString *const WXMediaPlayerStopNotification;

@protocol WXMediaPlayerDelegate <NSObject>

@required
- (BOOL)mediaPlayerWillStartPlaying:(WXMediaPlayer *)player media:(WXMediaItem *)media;

@optional
- (void)mediaPlayerWillChangeState:(WXMediaPlaybackState)state;
- (void)mediaPlayerDidStartPlaying:(WXMediaPlayer *)player media:(WXMediaItem *)media;
- (void)mediaPlayerDidFinishPlaying:(WXMediaPlayer *)player media:(WXMediaItem *)media;
- (void)mediaPlayerDidStop:(WXMediaPlayer *)player media:(WXMediaItem *)media;
- (void)mediaPlayerDidChangeCurrentTime:(WXMediaPlayer *)player;
- (void)mediaPlayerDidChangeRepeatMode:(WXMediaRepeatMode)mode player:(WXMediaPlayer *)player;
- (void)mediaPlayerDidChangeShuffleMode:(BOOL)enabled player:(WXMediaPlayer *)player;
- (void)mediaPlayerDidUpdateStreamingProgress:(float)progress player:(WXMediaPlayer *)player media:(WXMediaItem *)media;
- (void)mediaPlayerDidFailedWithError:(NSError *)error player:(WXMediaPlayer *)player media:(WXMediaItem *)media;
- (void)mediaPlayerWillStartLoading:(WXMediaPlayer *)player media:(WXMediaItem *)media;
- (void)mediaPlayerDidEndLoading:(WXMediaPlayer *)player media:(WXMediaItem *)media;

//Possible connection loss or connection is too slow.
- (void)mediaPlayerDidBufferEmpty:(WXMediaPlayer *)player media:(WXMediaItem *)media;
@end

@interface WXMediaPlayer : NSObject

@property (nonatomic, weak) id<WXMediaPlayerDelegate> delegate;
@property (nonatomic, readonly) WXMediaItem *nowPlayingItem;
@property (nonatomic, readonly) WXMediaPlaybackState playbackState;
@property (nonatomic, assign) WXMediaRepeatMode repeatMode;
@property (nonatomic, readonly) BOOL shuffleMode;
@property (nonatomic, readonly) NSInteger index;
@property (nonatomic, readonly) NSString *currentAudioSessionCategory;

+ (instancetype)sharedPlayer;
- (AVPlayer *)corePlayer;
- (void)pauseOtherPlayer;
- (void)stopOtherPlayer;
- (void)addMedia:(WXMediaItem *)media;
- (void)removeMediaAtIndex:(NSUInteger)index;
- (void)replaceMediaAtIndex:(WXMediaItem *)media index:(NSInteger)index;
- (void)removeAlWXediaInQueue;
- (void)setQueue:(NSArray *)queue;
- (void)playMedia:(WXMediaItem *)media;
- (void)play;
- (void)playAtIndex:(NSInteger)index;
- (void)stop;
- (void)pause;
- (void)playNextMedia;
- (void)playPreviousMedia;
- (NSArray *)queue;
- (NSUInteger)numberOfQueue;
- (void)seekTo:(NSTimeInterval)time;
- (void)setShuffleEnabled:(BOOL)enabled;
- (UIImage *)thumbnailAtTime:(CGFloat)time;
- (UIImage *)representativeThumbnail;
- (NSError *)setAudioSessionCategory:(NSString *)category;

/// NOTICE: 播放直播HLS的时候数据是不准确的，当前播放时间值仅代表此次播放的时长
- (NSTimeInterval)currentPlaybackTime;
- (NSTimeInterval)currentPlaybackDuration;

@end

