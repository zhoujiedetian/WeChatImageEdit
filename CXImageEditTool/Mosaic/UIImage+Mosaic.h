//
//  UIImage+Mosaic.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Mosaic)
/// 图片模糊处理
- (UIImage *)blurImageWithBlurNumber:(CGFloat)blur;

/// 转换成马赛克,level代表一个点转为多少level*level的正方形
- (UIImage *)getMosaicImageFromOrginImageBlockLevel:(NSUInteger)level;
@end

NS_ASSUME_NONNULL_END
