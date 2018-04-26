//
//  ArtImageCompressUtil.m
//  DMMacImageCompress
//
//  Created by leoliu on 2018/4/26.
//  Copyright © 2018年 leoliu. All rights reserved.
//

#import "ArtImageCompressUtil.h"
#import "NSImage+DM.h"

@interface ArtImageCompressUtil()

@end

@implementation ArtImageCompressUtil

+ (instancetype)shared
{
    static ArtImageCompressUtil *share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}


- (void)compressImage:(NSImage *)aImage ToMaxSize:(CGSize)aMaxSize maxFileSize:(CGFloat)maxFileSize complete:(void(^)(CGSize size, NSData *data))complete
{
    //先调整分辨率
    __block CGSize maxSize = aMaxSize;
    if (CGSizeEqualToSize(aMaxSize, CGSizeZero)) {
        maxSize = CGSizeMake(2048, 2048);
    }
    CGSize imgSize = aImage.size;
    NSImage *reSizeImage = aImage;
    CGFloat scale = 2.;
    if (imgSize.width > maxSize.width * scale || imgSize.height > maxSize.height * scale) {
        reSizeImage = [aImage scaleAspectFitToSize:maxSize transparent:NO];
    }
    
    __block NSData *finallImageData = [reSizeImage TIFFRepresentation];
    NSUInteger sizeOrigin   = finallImageData.length;
    CGFloat sizeOriginMB = sizeOrigin / (1024. * 1024.);
    if (sizeOriginMB <= maxFileSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete) {
                complete(reSizeImage.size,finallImageData);
            }
        });
        return;
    }
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *tmp = [finallImageData copy];
        /*
         调整大小
         说明：压缩系数数组compressionQualityArr是从大到小存储。
         */
        //思路：使用二分法搜索
        finallImageData = [reSizeImage halfFuntionForMaxFileSize:maxFileSize];
        //如果还是未能压缩到指定大小，则进行降分辨率
        while (finallImageData.length == 0) {
            //每次降100分辨率
            if (maxSize.width-100 <= 0 || maxSize.height-100 <= 0) {
                finallImageData = tmp;
                break;
            }
            maxSize = CGSizeMake(maxSize.width-100, maxSize.height-100);
            NSImage *image = [aImage scaleAspectFitToSize:maxSize transparent:NO];
            if (!image) {
                finallImageData = tmp;
                break;
            } else {
                finallImageData = [image halfFuntionForMaxFileSize:maxFileSize];
            }
        }
        
        NSLog(@"===压缩后图片size = %@",NSStringFromSize(maxSize));
        NSAssert(finallImageData != nil,@"finallImageData为空了");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete) {
                complete(reSizeImage.size,finallImageData);
            }
        });
    });
}

@end

