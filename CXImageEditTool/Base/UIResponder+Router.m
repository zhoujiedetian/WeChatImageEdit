//
//  UIResponder+Router.m
//  chengxun
//
//  Created by zhoujie on 2020/6/30.
//  Copyright © 2020 westone. All rights reserved.
//

#import "UIResponder+Router.h"

@implementation UIResponder (Router)

- (void)routerWithEventName:(NSString *)eventName DataInfo:(NSDictionary *)dataInfo {
    [self.nextResponder routerWithEventName:eventName DataInfo:dataInfo];
}
@end
