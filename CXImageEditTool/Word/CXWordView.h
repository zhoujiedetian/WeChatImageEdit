//
//  CXWordVi.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/1.
//

#import <UIKit/UIKit.h>
@class CXWordView;
NS_ASSUME_NONNULL_BEGIN
@protocol CXWordViewDelegate <NSObject>
- (void)didAddWord:(NSString *)text textColor:(UIColor *)textColor isShowBg:(BOOL)isShowBg;
- (void)didClickCancel:(CXWordView *)wordView;
@end

@interface CXWordView : UIView
@property(nonatomic, weak) id<CXWordViewDelegate> delegate;
//取消
@property(nonatomic, copy) void (^cancel)(void);
//编辑模式(双击添加的文字)下取消
@property(nonatomic, copy) void (^editCancel)(void);
//编辑模式(双击添加的文字)下完成
@property(nonatomic, copy) void (^editComplete)(NSString *content, UIColor *textColor, BOOL isShowBg);
- (instancetype)initWithImage:(UIImage *)image;
- (void)setText:(NSString *)text textColor:(UIColor *)textColor isShowBg:(BOOL)isShowBg;
@end

NS_ASSUME_NONNULL_END
