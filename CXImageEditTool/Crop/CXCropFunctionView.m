//
//  CXCropFunctionView.m
//  ImageEditDemo
//
//  Created by 精灵要跳舞 on 2021/7/3.
//

#import "CXCropFunctionView.h"
#import "Masonry.h"
#import "CXCropView.h"
#import "CXImageEditConfig.h"

//底部工具栏高度
#define kBottomToolBarHeight 79

@interface CXCropFunctionView()<CXCropViewDelegate>
//底部按钮工具栏
@property(nonatomic, strong) UIView *bottomToolBar;
//关闭按钮
@property(nonatomic, strong) UIButton *closeBtn;
//还原按钮
@property(nonatomic, strong) UIButton *restoreBtn;
//完成按钮
@property(nonatomic, strong) UIButton *finishBtn;
//旋转按钮
@property(nonatomic, strong) UIButton *rotateBtn;
//剪裁视图
@property (nonatomic, strong) CXCropView *cropView;

@property (nonatomic, strong) UIImage *editImage;
@end

@implementation CXCropFunctionView

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image {
    if (self = [super initWithFrame:frame]) {
        self.editImage = image;
        [self setUpView];
    }
    return self;
}

#pragma mark ********SetUpView********
- (void)setUpView {
    self.backgroundColor = [UIColor blackColor];
    CGRect cropFrame = CGRectMake(0, kStatusBarHeight, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - kBottomToolBarHeight - kStatusBarHeight);
    self.cropView = [[CXCropView alloc]initWithFrame:cropFrame image:_editImage];
    self.cropView.delegate = self;
    [self addSubview:self.cropView];
    [self setUpBottomToolBar];
}

//初始化底部功能按钮
- (void)setUpBottomToolBar {
    [self addSubview:self.bottomToolBar];
    [self.bottomToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.offset(kBottomToolBarHeight);
    }];
    
    UIView *barLine = [UIView new];
    barLine.backgroundColor = [UIColor whiteColor];
    [self.bottomToolBar addSubview:barLine];
    [barLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.mas_equalTo(0);
        make.height.offset(1);
    }];
    
    [self.bottomToolBar addSubview:self.closeBtn];
    [self.bottomToolBar addSubview:self.restoreBtn];
    [self.bottomToolBar addSubview:self.finishBtn];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(24);
        make.top.mas_equalTo(10);
        make.width.height.offset(24);
    }];
    
    [self.restoreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.centerY.equalTo(self.closeBtn);
    }];
    
    [self.finishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-24);
        make.top.mas_equalTo(10);
        make.width.height.offset(24);
    }];
    
    [self addSubview:self.rotateBtn];
    [self.rotateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.bottom.equalTo(self.bottomToolBar.mas_top).offset(-25);
    }];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.bottomToolBar.alpha = 0;
        self.rotateBtn.alpha = 0;
        
        UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear;
        [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
            self.bottomToolBar.alpha = 1;
            self.rotateBtn.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    }
}
#pragma mark ********* CXCropViewDelegate *********
- (void)cropViewShouldRecovery:(CXCropView *)cropView isCanRecovery:(BOOL)isCanRecovery {
    self.restoreBtn.alpha = isCanRecovery ? 1 : 0.4;
    self.restoreBtn.enabled = isCanRecovery;
}

#pragma mark ********* EventResponse *********
- (void)clickClose {
    [self removeFromSuperview];
}

- (void)clickFinish {
    __weak typeof(self) weakSelf = self;
    [self.cropView cropImageWithComplete:^(UIImage * _Nonnull image) {
        !self.completeCrop ? : self.completeCrop(image);
        [weakSelf removeFromSuperview];
    }];
}

//旋转
- (void)clickRotate {
    [self.cropView rotation];
}

//还原
- (void)clickRestore {
    [self.cropView recovery];
}

#pragma mark ********Getter********
- (UIView *)bottomToolBar {
    if (!_bottomToolBar) {
        _bottomToolBar = [UIView new];
    }
    return _bottomToolBar;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn addTarget:self action:@selector(clickClose) forControlEvents:UIControlEventTouchUpInside];
        [_closeBtn setImage:[UIImage imageNamed:@"crop_Close"] forState:0];
    }
    return _closeBtn;
}

- (UIButton *)restoreBtn {
    if (!_restoreBtn) {
        _restoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_restoreBtn addTarget:self action:@selector(clickRestore) forControlEvents:UIControlEventTouchUpInside];
        [_restoreBtn setTitle:@"还原" forState:0];
        _restoreBtn.enabled = NO;
        _restoreBtn.alpha = 0.4;
        _restoreBtn.titleLabel.textColor = [UIColor whiteColor];
    }
    return _restoreBtn;
}

- (UIButton *)finishBtn {
    if (!_finishBtn) {
        _finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_finishBtn addTarget:self action:@selector(clickFinish) forControlEvents:UIControlEventTouchUpInside];
        [_finishBtn setImage:[UIImage imageNamed:@"crop_Finish"] forState:0];
    }
    return _finishBtn;
}

- (UIButton *)rotateBtn {
    if (!_rotateBtn) {
        _rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rotateBtn setImage:[UIImage imageNamed:@"rotate"] forState:0];
        [_rotateBtn addTarget:self action:@selector(clickRotate) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rotateBtn;
}

@end
