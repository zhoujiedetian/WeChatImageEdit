//
//  CXScrawlInfo.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXScrawlInfo : NSObject
@property(nonatomic, strong) NSMutableArray *linePoints;
@property(nonatomic, assign) CGFloat lineWidth;
@property(nonatomic, strong) UIColor *lineColor;
@end

NS_ASSUME_NONNULL_END
