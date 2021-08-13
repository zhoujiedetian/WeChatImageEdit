//
//  CXScrawlView.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import <UIKit/UIKit.h>
@class CXScrawlView;

@protocol CXScrawlViewDelegate <NSObject>
- (void)scrawlBegan:(CXScrawlView *)scrawlView;
- (void)scrawlDidEnd:(CXScrawlView *)scrawlView;
@end

@interface CXScrawlView : UIView
@property(nonatomic, weak) id<CXScrawlViewDelegate> delegate;
//当前的涂鸦颜色
@property(nonatomic, strong) UIColor *currentDrawColor;
//当前的涂鸦画笔宽度
@property(nonatomic, assign) CGFloat currentDrawWidth;
//能否撤回
- (BOOL)canRecall;
//撤回
- (void)recall;
//全部擦除
- (void)clear;
@end
