//
//  CXEditModel.m
//  chengxun
//
//  Created by zhoujie on 2021/8/6.
//  Copyright © 2021 westone. All rights reserved.
//

#import "CXEditModel.h"

@implementation CXCropModel

@end

@implementation CXEditModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.words = [NSMutableArray array];
    }
    return self;
}
@end
