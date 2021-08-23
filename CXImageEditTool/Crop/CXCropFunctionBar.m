//
//  CXCropFunctionBar.m
//  chengxun
//
//  Created by zhoujie on 2021/8/5.
//

#import "CXCropFunctionBar.h"
#import "CXImageEditConfig.h"
@interface CXCropFunctionBar()
@property(nonatomic, strong) UIView *cancelFinishContainer;
//关闭按钮
@property(nonatomic, strong) UIButton *closeBtn;
//还原按钮
@property(nonatomic, strong) UIButton *restoreBtn;
//完成按钮
@property(nonatomic, strong) UIButton *finishBtn;
//旋转按钮
@property(nonatomic, strong) UIButton *rotateBtn;
@end

@implementation CXCropFunctionBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUpBottomToolBar];
    }
    return self;
}

//初始化底部功能按钮
- (void)setUpBottomToolBar {
    
    [self addSubview:self.cancelFinishContainer];
    [self.cancelFinishContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.mas_equalTo(0);
        }
        make.height.offset(44);
    }];
    
    UIView *barLine = [UIView new];
    barLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 0.2);
    [self addSubview:barLine];
    [barLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.mas_equalTo(0);
        make.height.offset(1);
        make.bottom.equalTo(self.cancelFinishContainer.mas_top);
    }];
    
    [self.cancelFinishContainer addSubview:self.closeBtn];
    [self.cancelFinishContainer addSubview:self.restoreBtn];
    [self.cancelFinishContainer addSubview:self.rotateBtn];
    [self.cancelFinishContainer addSubview:self.finishBtn];
    
    CGFloat spacing = (kScreenWidth - 24 * 2 - 24 * 4) / (4 - 1);
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(24);
        make.centerY.mas_equalTo(0);
        make.width.height.offset(24);
    }];
    
    [self.restoreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.closeBtn.mas_right).offset(spacing);
        make.centerY.equalTo(self.closeBtn);
        make.width.height.offset(24);
    }];
    
    [self.rotateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.restoreBtn.mas_right).offset(spacing);
        make.centerY.equalTo(self.closeBtn);
        make.width.height.offset(24);
    }];
    
    [self.finishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-24);
        make.centerY.mas_equalTo(0);
        make.width.height.offset(24);
    }];
    
    
}

#pragma mark ********* EventResponse *********
- (void)clickClose {
    [self hide];
    [self routerWithEventName:kCXCropFunctionBar_CloseBtn_Clicked DataInfo:nil];
}

- (void)clickRestore {
    [self routerWithEventName:kCXCropFunctionBar_RecoveryBtn_Clicked DataInfo:nil];
}

- (void)clickFinish {
    [self hide];
    [self routerWithEventName:kCXCropFunctionBar_FinishBtn_Clicked DataInfo:nil];
}

- (void)clickRotate {
    [self routerWithEventName:kCXCropFunctionBar_RotationBtn_Clicked DataInfo:nil];
}

#pragma mark ********* PublicMethod *********
- (void)isCanRecovery:(BOOL)isCanRecovery {
    self.restoreBtn.enabled = isCanRecovery ? YES : NO;
    self.restoreBtn.alpha = isCanRecovery ? 1.0 : 0.4;
}

#pragma mark ********* PublicMethod *********
- (void)show {
    self.alpha = 0;
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear;
    [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hide {
    [self isCanRecovery:NO];
    self.alpha = 1;
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear;
    [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark ********* Getter *********
- (UIView *)cancelFinishContainer {
    if (!_cancelFinishContainer) {
        _cancelFinishContainer = [UIView new];
    }
    return _cancelFinishContainer;
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
        [_restoreBtn setImage:[UIImage imageNamed:@"recovery"] forState:0];
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
