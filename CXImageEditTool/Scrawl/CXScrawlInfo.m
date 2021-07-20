//
//  CXScrawlInfo.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import "CXScrawlInfo.h"

@implementation CXScrawlInfo
- (instancetype)init {
    self = [super init];
    if (self) {
        self.linePoints = [NSMutableArray array];
    }
    return self;
}
@end
