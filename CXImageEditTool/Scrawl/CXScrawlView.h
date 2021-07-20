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
@property(nonatomic, strong) UIColor *currentDrawColor;
@property(nonatomic, assign) CGFloat currentDrawWidth;
//能否撤回
- (BOOL)canRecall;
//撤回
- (void)recall;
@end
