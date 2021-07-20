//
//  CXCropFunctionView.h
//  ImageEditDemo
//
//  Created by 精灵要跳舞 on 2021/7/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXCropFunctionView : UIView
@property(nonatomic, copy) void (^completeCrop)(UIImage *image);
- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
