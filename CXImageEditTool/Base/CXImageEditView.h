//
//  CXImageEditVC.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
///编辑图片Controller
@interface CXImageEditView: UIView
//自定义返回操作
@property(nonatomic, copy) void (^customBackAction)(void);
@property(nonatomic, copy) void (^completeEdit)(UIImage *resultImg);
//记录需要编辑的图片
@property(nonatomic, strong) UIImage *editImage;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

///使用frame初始化需要赋值editImage
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
///使用image初始化需要赋值frame
- (instancetype)initWithEditImage:(UIImage *)image NS_DESIGNATED_INITIALIZER;

- (void)clearAllEditHandle;
@end

NS_ASSUME_NONNULL_END
