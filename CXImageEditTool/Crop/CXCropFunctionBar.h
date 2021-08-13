//
//  CXCropFunctionBar.h
//  chengxun
//
//  Created by zhoujie on 2021/8/5.
//  Copyright © 2021 westone. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
static NSString * const kCXCropFunctionBar_CloseBtn_Clicked = @"kCXCropFunctionBar_CloseBtn_Clicked";
static NSString * const kCXCropFunctionBar_RecoveryBtn_Clicked = @"kCXCropFunctionBar_RecoveryBtn_Clicked";
static NSString * const kCXCropFunctionBar_FinishBtn_Clicked = @"kCXCropFunctionBar_FinishBtn_Clicked";
static NSString * const kCXCropFunctionBar_RotationBtn_Clicked = @"kCXCropFunctionBar_RotationBtn_Clicked";
@interface CXCropFunctionBar : UIView
- (void)show;
- (void)hide;
- (void)isCanRecovery:(BOOL)isCanRecovery;
@end

NS_ASSUME_NONNULL_END
