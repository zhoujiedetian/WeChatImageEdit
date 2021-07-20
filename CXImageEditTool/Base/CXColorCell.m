//
//  CXColorCell.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/1.
//

#import "CXColorCell.h"
#import "Masonry.h"

#define kColorWidth 20
#define kCornerViewWidth 24
@interface CXColorCell()
@property(nonatomic, strong) UIImageView *recallIgv;
@property(nonatomic, strong) UIView *cornerVi;
@property(nonatomic, strong) UIView *colorVi;
@end

@implementation CXColorCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
    }
    return self;
}

#pragma mark ********* SetUpView *********
- (void)setUpView {
    [self.contentView addSubview:self.cornerVi];
    [self.cornerVi mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);
        make.width.height.offset(kCornerViewWidth);
    }];
    
    [self.contentView addSubview:self.colorVi];
    [self.colorVi mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);
        make.width.height.offset(kColorWidth);
    }];
    
    [self.contentView addSubview:self.recallIgv];
    [self.recallIgv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);;
        make.width.height.offset(kCornerViewWidth);
    }];
}

#pragma mark ********* PublicMethod *********
- (void)freshWithColor:(UIColor *)color isSelected:(BOOL)isSelected {
    if (!color) {
        self.recallIgv.hidden = NO;
        self.colorVi.hidden = YES;
        self.cornerVi.hidden = YES;
    }else {
        self.recallIgv.hidden = YES;
        self.colorVi.hidden = NO;
        self.colorVi.backgroundColor = color;
        self.cornerVi.hidden = !isSelected;
    }
}

- (void)freshWithWord:(UIColor *)color isSelected:(BOOL)isSelected {
    if (!color) {
        self.recallIgv.hidden = NO;
        self.colorVi.hidden = YES;
        self.cornerVi.hidden = YES;
        self.recallIgv.alpha = 1;
        if (isSelected) {
            self.recallIgv.image = [UIImage imageNamed:@"word_selected"];
        }else {
            self.recallIgv.image = [UIImage imageNamed:@"word_bg"];
        }
    }else {
        self.recallIgv.hidden = YES;
        self.colorVi.hidden = NO;
        self.colorVi.backgroundColor = color;
        self.cornerVi.hidden = !isSelected;
    }
}

- (void)enableRecall:(BOOL)enable {
    //仅处理图片的展示，撤回操作在CXImageEditVC -> collectionView: didSelectItemAtIndexPath:
    CGFloat alpha = enable ? 1 : 0.4;
    self.recallIgv.alpha = alpha;
}

#pragma mark ********* Getter *********
- (UIView *)cornerVi {
    if (!_cornerVi) {
        _cornerVi = [UIView new];
        _cornerVi.backgroundColor = [UIColor whiteColor];
        _cornerVi.clipsToBounds = YES;
        _cornerVi.layer.cornerRadius = kCornerViewWidth / 2;
        _cornerVi.hidden = YES;
    }
    return _cornerVi;
}

- (UIView *)colorVi {
    if (!_colorVi) {
        _colorVi = [UIView new];
        _colorVi.clipsToBounds = YES;
        _colorVi.layer.cornerRadius = kColorWidth / 2;
        _colorVi.layer.borderColor = [UIColor whiteColor].CGColor;
        _colorVi.layer.borderWidth = 1;
    }
    return _colorVi;
}

- (UIImageView *)recallIgv {
    if (!_recallIgv) {
        _recallIgv = [UIImageView new];
        _recallIgv.image = [UIImage imageNamed:@"recall"];
        _recallIgv.alpha = 0.4;
    }
    return _recallIgv;
}
@end
