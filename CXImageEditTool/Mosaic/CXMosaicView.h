//
//  CXMosaicView.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/7.
//

#import <UIKit/UIKit.h>


@class CXMosaicView;
@protocol CXMosaicViewDelegate <NSObject>
- (void)mosaicBegan:(CXMosaicView *)mosaicView;
- (void)mosaicDidEnd:(CXMosaicView *)mosaicView;
@end
@interface CXMosaicView : UIView
@property(nonatomic, weak) id<CXMosaicViewDelegate> delegate;
- (void)generateMosaicImage:(UIImage *)image;
- (BOOL)canRecall;
- (void)recall;
- (void)clear;
@end
