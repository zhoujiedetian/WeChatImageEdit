//
//  CXWordLab.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/2.
//

#import "CXWordLab.h"
#import "Masonry.h"

#define kEdgeSpace 5
#define kWordFont 32

@interface CXWordLab()
@property(nonatomic, strong) UIView *backgroundVi;
@property(nonatomic, strong) UILabel *contentLab;
@property(nonatomic, strong) UIButton *closeBtn;
@end

@implementation CXWordLab

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (void)setUpView {
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.userInteractionEnabled = YES;
    [self addSubview:self.backgroundVi];
    [self addSubview:self.contentLab];
    [self.contentLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(32);
        make.top.mas_equalTo(24);
        make.right.mas_equalTo(-32);
        make.bottom.mas_equalTo(-24);
    }];
    
    [self.backgroundVi mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentLab.mas_left).offset(-16);
        make.top.equalTo(self.contentLab.mas_top).offset(-8);
        make.right.equalTo(self.contentLab.mas_right).offset(16);
        make.bottom.equalTo(self.contentLab.mas_bottom).offset(8);
    }];
    
    [self addSubview:self.closeBtn];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_right);
        make.centerY.equalTo(self.mas_top);
    }];
}

- (CGSize)sizeThatFits:(CGSize)size {
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect wordBound = [_text boundingRectWithSize:size options:options attributes:@{NSFontAttributeName : self.contentLab.font} context:nil];
    return CGSizeMake(floorf(wordBound.size.width) + 1 + 32 * 2, floorf(wordBound.size.height) + 1 + 24 * 2);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect btnRect = self.closeBtn.frame;
    if (CGRectContainsPoint(btnRect, point)) {
        return YES;
    }else {
        return [super pointInside:point withEvent:event];
    }
}

#pragma mark ********* EventResponse *********
- (void)clickClose {
    if (self.closeBlock) {
        self.closeBlock();
    }
}

#pragma mark ********* PublicMethod *********
- (void)showBorderAutoHide {
    self.layer.borderWidth = 1;
    self.closeBtn.hidden = NO;
    [self hideBorder];
}

- (void)showBorderForever {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.layer.borderWidth = 1;
    self.closeBtn.hidden = NO;
}

- (void)hideBorder {
    [self performSelector:@selector(_hideBorder) withObject:nil afterDelay:1.5];
}

- (void)hideBorderRightNow {
    [self _hideBorder];
}

- (void)_hideBorder {
    self.layer.borderWidth = 0;
    self.closeBtn.hidden = YES;
}

#pragma mark ********* Setter *********
- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.contentLab.textColor = textColor;
}

- (void)setText:(NSString *)text {
    _text = text;
    self.contentLab.text = text;
}

- (void)setIsShowBackgroundVi:(BOOL)isShowBackgroundVi {
    _isShowBackgroundVi = isShowBackgroundVi;
    if (_isShowBackgroundVi) {
        self.backgroundVi.backgroundColor = [UIColor whiteColor];
    }else {
        self.backgroundVi.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark ********* Getter *********
- (UILabel *)contentLab {
    if (!_contentLab) {
        _contentLab = [UILabel new];
        _contentLab.font = [UIFont boldSystemFontOfSize:kWordFont];
        _contentLab.numberOfLines = 0;
    }
    return _contentLab;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:0];
        [_closeBtn addTarget:self action:@selector(clickClose) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UIView *)backgroundVi {
    if (!_backgroundVi) {
        _backgroundVi = [UIView new];
        _backgroundVi.backgroundColor = [UIColor clearColor];
        _backgroundVi.clipsToBounds = YES;
        _backgroundVi.layer.cornerRadius = 8;
    }
    return _backgroundVi;
}
@end
