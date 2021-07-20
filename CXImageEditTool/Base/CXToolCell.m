//
//  CXToolCell.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import "CXToolCell.h"
#import "CXImageEditConfig.h"

@interface CXToolCell()
@property(nonatomic, strong) UIButton *finishBtn;
@property(nonatomic, strong) UIImageView *btnIgv;
@end

@implementation CXToolCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
    }
    return self;
}

#pragma mark ********* SetUpView *********
- (void)setUpView {
    [self.contentView addSubview:self.btnIgv];
    [self.btnIgv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self.contentView addSubview:self.finishBtn];
    [self.finishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);
        make.width.offset(64);
        make.height.offset(32);
    }];
}

#pragma mark ********* PublicMethod *********
- (void)freshWithData:(NSString *)data{
    if (!data) {
        _btnIgv.hidden = YES;
        _finishBtn.hidden = NO;
    }else {
        _btnIgv.hidden = NO;
        _finishBtn.hidden = YES;
        _btnIgv.image = [UIImage imageNamed:data];
    }
    
}

#pragma mark ********* Getter *********
- (UIImageView *)btnIgv {
    if (!_btnIgv) {
        _btnIgv = [UIImageView new];
        _btnIgv.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _btnIgv;
}

- (UIButton *)finishBtn {
    if (!_finishBtn) {
        _finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishBtn.backgroundColor = kThemeColor;
        _finishBtn.clipsToBounds = YES;
        _finishBtn.layer.cornerRadius = 3;
        [_finishBtn setTitleColor:[UIColor whiteColor] forState:0];
        [_finishBtn setTitle:@"完成" forState:0];
        _finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _finishBtn.enabled = NO;
    }
    return _finishBtn;
}
@end
