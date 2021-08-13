//
//  CXScrawlInfo.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXScrawlInfo : NSObject
//记录贝塞尔曲线的点位
@property(nonatomic, strong) NSMutableArray *linePoints;
//线宽
@property(nonatomic, assign) CGFloat lineWidth;
//线颜色
@property(nonatomic, strong) UIColor *lineColor;
@end

NS_ASSUME_NONNULL_END
