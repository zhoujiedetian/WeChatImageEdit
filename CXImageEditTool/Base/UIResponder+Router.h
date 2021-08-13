//
//  UIResponder+Router.h
//  chengxun
//
//  Created by zhoujie on 2020/6/30.
//  Copyright © 2020 westone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (Router)
- (void)routerWithEventName:(NSString *)eventName DataInfo:(NSDictionary *)dataInfo;
@end
