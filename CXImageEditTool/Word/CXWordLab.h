//
//  CXWordLab.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXWordLab : UIView
@property(nonatomic, strong) UIColor *textColor;
@property(nonatomic, copy) NSString *text;
@property(nonatomic, assign) BOOL isShowBackgroundVi;
@property(nonatomic, copy) void (^closeBlock)(void);
//展示边界,1.5s后自动隐藏边界
- (void)showBorderAutoHide;
- (void)showBorderForever;
//延时1.5s隐藏border
- (void)hideBorder;
//立即隐藏border
- (void)hideBorderRightNow;
@end

NS_ASSUME_NONNULL_END
