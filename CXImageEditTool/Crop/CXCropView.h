//
//  CXCropView.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/10.
//

#import <UIKit/UIKit.h>
@class CXCropView;
NS_ASSUME_NONNULL_BEGIN
@protocol CXCropViewDelegate <NSObject>

- (void)cropViewShouldRecovery:(CXCropView *)cropView isCanRecovery:(BOOL)isCanRecovery;

@end

@interface CXCropView : UIView
@property(nonatomic, weak) id<CXCropViewDelegate> delegate;
- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image;
- (void)rotation;
- (void)recovery;
- (void)cropImageWithComplete:(void (^)(UIImage * image))complete;
@end

NS_ASSUME_NONNULL_END
