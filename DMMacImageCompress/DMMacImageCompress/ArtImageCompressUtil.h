//
//  ArtImageCompressUtil.h
//  DMMacImageCompress
//
//  Created by leoliu on 2018/4/26.
//  Copyright © 2018年 leoliu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArtImageCompressUtil : NSObject
- (void)compressImage:(NSImage *)aImage ToMaxSize:(CGSize)aMaxSize maxFileSize:(CGFloat)maxFileSize complete:(void(^)(CGSize size, NSData *data))complete;
@end
