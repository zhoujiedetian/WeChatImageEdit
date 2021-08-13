//
//  CXImageEditConfig.h
//  chengxun
//
//  Created by zhoujie on 2021/7/6.
//

#ifndef CXImageEditConfig_h
#define CXImageEditConfig_h

#import "Masonry.h"
#import "UIResponder+Router.h"

#pragma mark ********* UIColor *********
#define CXUIColorFromRGBA(rgbValue, alphaValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:alphaValue]

#define CXUIColorFromRGB(rgbValue) CXUIColorFromRGBA(rgbValue, 1.0)
//主题色，用于按钮背景色
#define kThemeColor CXUIColorFromRGB(0xFF7200)

#pragma mark ********* 导航栏相关 *********
#define iPhoneX (UIScreen.mainScreen.bounds.size.width >= 375.f && UIScreen.mainScreen.bounds.size.height >= 812.f)
#define kStatusBarHeight (iPhoneX?(44):(20))
#define CXNaviHeight 44
#define CXBottomSafeHeight   (iPhoneX?(34):(0))

#pragma mark ********* 屏幕宽高 *********
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#endif /* CXImageEditConfig_h */
