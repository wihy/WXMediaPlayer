//
//  WXMediaItem.m
//  WXMediaPlayerKit
//
//Created by will.xu on 2018/02/21.
//

#import "WXMediaItem.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface WXMediaItem () {
	id metaMedia_;
	NSString *title_;
	NSString *albumTitle_;
	NSString *artist_;
	UIImage *artworkImage_;
	NSURL *url_;
}

@end

@implementation WXMediaItem

NSString *WXMediaItemInfoTitleKey = @"WXMediaItemInfoTitleKey";
NSString *WXMediaItemInfoAlubumTitleKey = @"WXMediaItemInfoAlubumTitleKey";
NSString *WXMediaItemInfoArtistKey = @"WXMediaItemInfoArtistKey";
NSString *WXMediaItemInfoArtworkKey = @"WXMediaItemInfoArtworkKey";
NSString *WXMediaItemInfoURLKey = @"WXMediaItemInfoURLKey";
NSString *WXMediaItemInfoContentTypeKey = @"WXMediaItemInfoContentTypeKey";

@synthesize title = title_;
@synthesize albumTitle = albumTitle_;
@synthesize artist = artist_;
@synthesize assetURL = url_;

- (void)dealloc
{
	WX_RELEASE(title_);
	WX_RELEASE(albumTitle_);
	WX_RELEASE(artist_);
	WX_RELEASE(artworkImage_);
	WX_RELEASE(url_);
	WX_DEALLOC(super);
}

- (instancetype)initWithMetaMedia:(id)media contentType:(WXMediaItemContentType)type
{
	self = [super init];
	if (self) {
		metaMedia_ = media;
		_contentType = type;
	}

	return self;
}

- (instancetype)initWithInfo:(NSDictionary *)info
{
	self = [super init];
	if (self) {
		title_ = ([info[WXMediaItemInfoTitleKey] isKindOfClass:[NSString class]] ? [info[WXMediaItemInfoTitleKey] copy] : nil);
		albumTitle_ = ([info[WXMediaItemInfoAlubumTitleKey] isKindOfClass:[NSString class]] ? [info[WXMediaItemInfoAlubumTitleKey] copy] : nil);
		artist_ = ([info[WXMediaItemInfoArtistKey] isKindOfClass:[NSString class]] ? [info[WXMediaItemInfoArtistKey] copy] : nil);
		artworkImage_ = ([info[WXMediaItemInfoArtworkKey] isKindOfClass:[UIImage class]] ? [info[WXMediaItemInfoArtworkKey] copy] : nil);
		url_ = ([info[WXMediaItemInfoURLKey] isKindOfClass:[NSURL class]] ? [info[WXMediaItemInfoURLKey] copy] : nil);
		_contentType = (WXMediaItemContentType)([info[WXMediaItemInfoContentTypeKey] isKindOfClass:[NSNumber class]] ? [info[WXMediaItemInfoContentTypeKey] integerValue] : -1);
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self) {
		title_ = [coder decodeObjectForKey:WXMediaItemInfoTitleKey];
		albumTitle_ = [coder decodeObjectForKey:WXMediaItemInfoAlubumTitleKey];
		artist_ = [coder decodeObjectForKey:WXMediaItemInfoArtistKey];
		artworkImage_ = [coder decodeObjectForKey:WXMediaItemInfoArtworkKey];
		url_ = [coder decodeObjectForKey:WXMediaItemInfoURLKey];
		_contentType = (WXMediaItemContentType)[[coder decodeObjectForKey:WXMediaItemInfoContentTypeKey] integerValue];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:title_ forKey:WXMediaItemInfoTitleKey];
	[coder encodeObject:albumTitle_ forKey:WXMediaItemInfoAlubumTitleKey];
	[coder encodeObject:artist_ forKey:WXMediaItemInfoArtistKey];
	[coder encodeObject:artworkImage_ forKey:WXMediaItemInfoArtworkKey];
	[coder encodeObject:url_ forKey:WXMediaItemInfoURLKey];
	[coder encodeObject:[NSNumber numberWithInteger:_contentType] forKey:WXMediaItemInfoContentTypeKey];
}

- (id)copyWithZone:(NSZone *)zone
{
	NSMutableDictionary *newInfo = [NSMutableDictionary new];
	if (self.title) {
		NSString *newString = [self.title copy];
		WX_AUTORELEASE(newString);
		newInfo[WXMediaItemInfoTitleKey] = newString ?: [NSNull null];
	}
	if (self.albumTitle) {
		NSString *newString = [self.albumTitle copy];
		WX_AUTORELEASE(newString);
		newInfo[WXMediaItemInfoAlubumTitleKey] = newString ?: [NSNull null];
	}
	if (self.artist) {
		NSString *newString = [self.artist copy];
		WX_AUTORELEASE(newString);
		newInfo[WXMediaItemInfoArtistKey] = newString ?: [NSNull null];
	}
	if (artworkImage_) {
		UIImage *newImage = [artworkImage_ copy];
		WX_AUTORELEASE(newImage);
		newInfo[WXMediaItemInfoArtworkKey] = newImage ?: [NSNull null];
	}
	if (self.assetURL) {
		NSURL *newURL = [self.assetURL copy];
		WX_AUTORELEASE(newURL);
		newInfo[WXMediaItemInfoURLKey] = newURL ?: [NSNull null];
	}
	newInfo[WXMediaItemInfoContentTypeKey] = [NSNumber numberWithInteger:_contentType];

	WXMediaItem *newObject = [[[self class] allocWithZone:zone] initWithInfo:newInfo];
	WX_RELEASE(newInfo);

	return newObject;
}

- (id)valueWithProperty:(NSString *)property cache:(id)cache
{
	id returnValue = nil;
	if ([metaMedia_ isKindOfClass:[MPMediaItem class]]) {
		returnValue = cache = [metaMedia_ valueForProperty:property];
	}

	return returnValue;
}

- (NSString *)title
{
	return title_ ?: [self valueWithProperty:MPMediaItemPropertyTitle cache:title_];
}

- (NSString *)albumTitle
{
	return albumTitle_ ?: [self valueWithProperty:MPMediaItemPropertyAlbumTitle cache:albumTitle_];
}

- (NSString *)artist
{
	return artist_ ?: [self valueWithProperty:MPMediaItemPropertyArtist cache:artist_];
}

- (UIImage *)artworkImageWithSize:(CGSize)size
{
	UIImage * (^f)(id) = ^UIImage *(id metaMedia)
	{
		UIImage *image = nil;
		if ([metaMedia isKindOfClass:[MPMediaItem class]]) {
			artworkImage_ = image = [[metaMedia_ valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:size];
		}

		return image;
	};

	return artworkImage_ ?: f(metaMedia_);
}

- (void)setArtworkImage:(UIImage *)image
{
	artworkImage_ = [image copy];
}

- (NSURL *)assetURL
{
	return url_ ?: [self valueWithProperty:MPMediaItemPropertyAssetURL cache:url_];
}

- (id)metaMedia
{
	return metaMedia_;
}

- (BOOL)isVideo
{
	return _contentType == WXMediaItemContentTypeVideo;
}

- (NSString *)description
{
	return [@{ @"title" : title_ ?: @"nil",
		@"album" : albumTitle_ ?: @"nil",
		@"artist" : artist_ ?: @"nil",
		@"url" : url_ ?: @"nil",
		@"artwork" : artworkImage_ ?: @"nil",
		@"content type" : _contentType == WXMediaItemContentTypeAudio ? @"WXMediaItemContentTypeAudio" : @"WXMediaItemContentTypeVideo",
		@"meta media" : metaMedia_ ?: @"nil" } description];
}

@end
