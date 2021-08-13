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

static NSString * const kCXCropCase_IsCanRecovery = @"kCXCropCase_IsCanRecovery";

typedef NS_ENUM(NSInteger, CXCropViewRotationDirection) {
    CXCropViewRotationDirectionUp = 0,
    CXCropViewRotationDirectionLeft,
    CXCropViewRotationDirectionDown,
    CXCropViewRotationDirectionRight
};
@class CXCropModel;
/// 剪裁框
@interface CXCropCase : UIView
@property (nonatomic, assign, readonly) BOOL isCanRecovery;
- (instancetype)initWithFrame:(CGRect)frame scrollVi:(UIScrollView *)scroll imageView:(UIImageView *)imageView;
- (instancetype)initWithFrame:(CGRect)frame scrollVi:(UIScrollView *)scroll imageView:(UIImageView *)imageView cropModel:(CXCropModel *)cropModel;
- (void)rotationWithDirection:(CXCropViewRotationDirection)rotationDirection;
- (void)rotation;
- (void)recovery;
- (void)cropImageWithComplete:(void (^)(UIImage * image, CXCropModel *cropModel))complete;
- (void)beginImageresizer;
- (void)endedImageresizer;
- (void)cancelDelayHandle;
@end

NS_ASSUME_NONNULL_END
