//
//  CXEditModel.h
//  chengxun
//
//  Created by zhoujie on 2021/8/6.
//  Copyright © 2021 westone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CXCropCase.h"
@interface CXCropModel : NSObject
//scroll偏移量
@property(nonatomic, assign) CGPoint contentOffset;
//scroll内间距
@property(nonatomic, assign) UIEdgeInsets contentInset;
//scroll缩放倍率
@property(nonatomic, assign) CGFloat zoomScale;
//剪裁框大小
@property(nonatomic, assign) CGRect cropCaseFrame;
//剪裁框相对于图片的位置
@property(nonatomic, assign) CGRect cropFrameOnImageView;
//剪裁框初始大小
@property(nonatomic, assign) CGRect cropCaseInitialFrame;
//剪裁后的图片
@property(nonatomic, strong) UIImage *cropImage;
//剪裁框距离图片内间距占据图片大小的百分比
@property(nonatomic, assign) UIEdgeInsets cropToImagePercentEdge;
//图片初始大小
@property(nonatomic, assign) CGRect imageViewOriginFrame;
//旋转方向
@property(nonatomic, assign) CXCropViewRotationDirection rotationDirection;
@end

//记录编辑图片的操作
@interface CXEditModel : NSObject
//添加文字数组
@property(nonatomic, strong) NSMutableArray *words;
//编辑操作
@property(nonatomic, strong) CXCropModel *cropModel;
@end


