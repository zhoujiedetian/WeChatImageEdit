//
//  CXCropCase.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kMaxZoomScale 4
#define kMinZoomScale 1

typedef NS_ENUM(NSInteger, CXCropViewRotationDirection) {
    CXCropViewRotationDirectionUp = 0,
    CXCropViewRotationDirectionLeft,
    CXCropViewRotationDirectionDown,
    CXCropViewRotationDirectionRight
};

/// 剪裁框
@interface CXCropCase : UIView
@property (nonatomic, assign, readonly) BOOL isCanRecovery;
- (instancetype)initWithFrame:(CGRect)frame scrollVi:(UIScrollView *)scroll imageView:(UIImageView *)imageView;
- (void)rotationWithDirection:(CXCropViewRotationDirection)rotationDirection;
- (void)rotation;
- (void)recovery;
- (void)cropImageWithComplete:(void (^)(UIImage * image))complete;
- (void)beginImageresizer;
- (void)endedImageresizer;
@end

NS_ASSUME_NONNULL_END
