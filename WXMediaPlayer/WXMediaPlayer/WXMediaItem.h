//
//  WXMediaItem.h
//  WXMediaPlayerKit
//
//Created by will.xu on 2018/02/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString *WXMediaItemInfoTitleKey;
extern NSString *WXMediaItemInfoAlubumTitleKey;
extern NSString *WXMediaItemInfoArtistKey;
extern NSString *WXMediaItemInfoArtworkKey;
extern NSString *WXMediaItemInfoURLKey;
extern NSString *WXMediaItemInfoContentTypeKey;

typedef NS_ENUM(NSUInteger, WXMediaItemContentType) {
	WXMediaItemContentTypeUnknown = -1,
	WXMediaItemContentTypeAudio = 0,
	WXMediaItemContentTypeVideo = 1
};

@interface WXMediaItem : NSObject <NSCoding, NSCopying>

- (instancetype)initWithMetaMedia:(id)media contentType:(WXMediaItemContentType)type;
- (instancetype)initWithInfo:(NSDictionary *)info;
- (UIImage *)artworkImageWithSize:(CGSize)size;
- (void)setArtworkImage:(UIImage *)image;
- (BOOL)isVideo;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *albumTitle;
@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) id metaMedia;
@property (nonatomic, copy) NSURL *assetURL;
@property (nonatomic, readonly) WXMediaItemContentType contentType;

@end
