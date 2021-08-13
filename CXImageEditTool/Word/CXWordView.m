//
//  CXWordVi.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/1.
//

#import "CXWordView.h"
#import "Masonry.h"
#import "CXColorCell.h"
#import "UIImage+Mosaic.h"
#import "CXImageEditConfig.h"

#define kNumberOfColors 8
#define kColorsHeight 44
#define kTextViewOriginalHeight 60
#define kTextViewWidth (kScreenWidth - (16 * 2))

@interface CXWordView()<UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property(nonatomic, strong) UIImageView *backgroundIgv;
@property(nonatomic, strong) UIView *backgroundMask;
@property(nonatomic, strong) UIButton *cancelBtn;
@property(nonatomic, strong) UIButton *doneBtn;
@property(nonatomic, strong) UITextView *textVi;
//颜色选择器
@property(nonatomic, strong) UICollectionView *colorsCollection;
//颜色数组
@property(nonatomic, copy) NSArray *colorsArr;
//选择的颜色索引,默认值为0，代表白色
@property(nonatomic, assign) NSInteger selectColorIndex;
//是否为编辑
@property(nonatomic, assign) BOOL isEdit;
//当前键盘的frame
@property(nonatomic, assign) CGRect currentKeyBoardFrame;
//是否展示textVi背景色
@property(nonatomic, assign) BOOL isShowTextViewBg;
@end

@implementation CXWordView

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        [self _registerNotification];
        [self setUpViewWithImage:image];
    }
    return self;
}

- (void)dealloc {
    [self _removeNotification];
}

#pragma mark ********* SetUpView *********
- (void)setUpViewWithImage:(UIImage *)image {
    //颜色集合
    _colorsArr = @[CXUIColorFromRGB(0xffffff), CXUIColorFromRGB(0x000000), CXUIColorFromRGB(0xF5222D), CXUIColorFromRGB(0xFADB14), CXUIColorFromRGB(0x1890FF), CXUIColorFromRGB(0x52C41A), CXUIColorFromRGB(0x722ED1)];
    //默认颜色为第一个，白色
    _selectColorIndex = 0;
    
    self.backgroundColor = [UIColor clearColor];

    self.backgroundIgv.image = [image blurImageWithBlurNumber:0.3];
    [self addSubview:self.backgroundIgv];
    [self.backgroundIgv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(0);
    }];
    
    [self addSubview:self.backgroundMask];
    [self.backgroundMask mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(0);
    }];
    
    [self addSubview:self.cancelBtn];
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.mas_equalTo(kStatusBarHeight);
        }
        make.left.mas_equalTo(16);
        make.width.offset(56);
        make.height.offset(28);
    }];
    
    [self addSubview:self.doneBtn];
    [self.doneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.mas_equalTo(kStatusBarHeight);
        }
        make.right.mas_equalTo(-16);
        make.width.offset(56);
        make.height.offset(28);
    }];
    
    //计算空字符串时，textView的高度
    NSString *originStr = @"";
    CGRect textBounds = [originStr boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.textVi.frame) - self.textVi.textContainerInset.left - self.textVi.textContainerInset.right, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.textVi.font} context:nil];
    textBounds.size.height += self.textVi.textContainerInset.top;
    textBounds.size.height += self.textVi.textContainerInset.bottom;
    self.textVi.frame = CGRectMake(0, 0, kTextViewWidth, textBounds.size.height);
    [self insertSubview:self.textVi belowSubview:self.cancelBtn];
    
    CGRect colorRect = CGRectMake(0, kScreenHeight - CXBottomSafeHeight - kColorsHeight, kScreenWidth, kColorsHeight);
    self.colorsCollection.frame = colorRect;
    [self.colorsCollection registerClass:[CXColorCell class] forCellWithReuseIdentifier:@"CXColorCell"];
    [self addSubview:self.colorsCollection];
    
    [self.textVi becomeFirstResponder];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview) {
       //添加到了父视图
        CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"position"];
        basic.fromValue = [NSValue valueWithCGPoint:CGPointMake(kScreenWidth/2, kScreenHeight * 1.5)];
        basic.toValue = [NSValue valueWithCGPoint:CGPointMake(kScreenWidth/2, kScreenHeight * 0.5)];
        basic.duration = 0.25;
        basic.fillMode = kCAFillModeForwards;
        [self.layer addAnimation:basic forKey:nil];
    }
}

#pragma mark ********* UITextViewDelegate *********
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    UITextRange *textRange = [textView markedTextRange];
    UITextPosition *position = [textView positionFromPosition:textRange.start offset:0];
    if (!position) {
        if (textView.text.length > 100) {
            textView.text = [textView.text substringToIndex:100];
        }
    }
    NSString *text = textView.text;
    CGRect textBounds = [text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.textVi.frame) - self.textVi.textContainerInset.left - self.textVi.textContainerInset.right, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.textVi.font} context:nil];
    textBounds.size.height += self.textVi.textContainerInset.top;
    textBounds.size.height += self.textVi.textContainerInset.bottom;
    NSLog(@"%@", NSStringFromCGRect(textBounds));
    if (CGRectGetHeight(textBounds) != CGRectGetHeight(self.textVi.frame)) {
        self.textVi.bounds = CGRectMake(0, 0, CGRectGetWidth(self.textVi.frame), CGRectGetHeight(textBounds));
        [self _updateTextViewFrame];
    }
}

#pragma mark ********* UICollectionViewDelegate *********

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kNumberOfColors;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 16, 0, 16);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (kScreenWidth - 16 * 2 - 10 * (kNumberOfColors - 1)) / kNumberOfColors;
    return CGSizeMake(width, kColorsHeight);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CXColorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CXColorCell" forIndexPath:indexPath];
    if (indexPath.row < _colorsArr.count) {
        [cell freshWithWord:_colorsArr[indexPath.row] isSelected:(indexPath.row == _selectColorIndex)];
    }else {
        [cell freshWithWord:nil isSelected:_isShowTextViewBg];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //颜色选择器
    if (indexPath.row < _colorsArr.count) {
        //选择颜色
        UIColor *selectColor = _colorsArr[indexPath.row];
        _selectColorIndex = indexPath.row;
        if (_isShowTextViewBg) {
            self.textVi.backgroundColor = selectColor;
            //显示背景时，如果选择颜色为白色，则自动切换成黑色
            if (_selectColorIndex == 0) {
                self.textVi.textColor = [UIColor blackColor];
            }else {
                self.textVi.textColor = [UIColor whiteColor];
            }
        }else {
            self.textVi.textColor = selectColor;
        }
        
    }else {
        _isShowTextViewBg = !_isShowTextViewBg;
        //选择背景色
        if (_isShowTextViewBg) {
            UIColor *selectedColor = _colorsArr[_selectColorIndex];
            self.textVi.backgroundColor = selectedColor;
            //显示背景时，如果选择颜色为白色，则自动切换成黑色
            if (_selectColorIndex == 0) {
                self.textVi.textColor = [UIColor blackColor];
            }else {
                self.textVi.textColor = [UIColor whiteColor];
            }
        }else {
            self.textVi.backgroundColor = [UIColor clearColor];
            self.textVi.textColor = _colorsArr[_selectColorIndex];
        }
    }
    [self.colorsCollection reloadData];
}

#pragma mark ********* KeyBoardNotification *********
- (void)keyboardWillShow:(NSNotification *)notif {
    
    NSInteger curve = [[notif userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSInteger _animationCurve = curve<<16;
    CGFloat _animationDuration = [[notif userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    _currentKeyBoardFrame = [[notif userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:_animationDuration delay:0 options:(_animationCurve|UIViewAnimationOptionBeginFromCurrentState) animations:^{
        __strong __typeof__(self) strongSelf = weakSelf;
        strongSelf.colorsCollection.frame = CGRectMake(0, CGRectGetMinY(strongSelf.currentKeyBoardFrame) - kColorsHeight, kScreenWidth, kColorsHeight);
    } completion:NULL];
    
    [self _updateTextViewFrame];
}

- (void)keyboardWillHide:(NSNotification *)notif {
    
    NSInteger curve = [[notif userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSInteger _animationCurve = curve<<16;
    CGFloat _animationDuration = [[notif userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    _currentKeyBoardFrame = CGRectZero;
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:_animationDuration delay:0 options:(_animationCurve|UIViewAnimationOptionBeginFromCurrentState) animations:^{
        __strong __typeof__(self) strongSelf = weakSelf;
        strongSelf.colorsCollection.frame = CGRectMake(0, kScreenHeight - CXBottomSafeHeight - kColorsHeight, kScreenWidth, kColorsHeight);
    } completion:NULL];
    
    [self _updateTextViewFrame];
}

#pragma mark ********* Touches *********
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textVi becomeFirstResponder];
}

#pragma mark ********* EventResponse *********
- (void)clickCancel {
    if (_isEdit && self.editCancel) {
        self.editCancel();
    }
    if (_delegate && [_delegate respondsToSelector:@selector(didClickCancel:)]) {
        [_delegate didClickCancel:self];
    }
    [self removeFromSuperview];
}

- (void)clickAddWord {
    if (self.textVi.text.length == 0) {
        return;
    }
    if (_isEdit && self.editComplete) {
        self.editComplete(self.textVi.text, _colorsArr[_selectColorIndex], self.isShowTextViewBg);
        [self removeFromSuperview];
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(didAddWord:textColor:isShowBg:)]) {
        [_delegate didAddWord:self.textVi.text textColor:_colorsArr[_selectColorIndex] isShowBg:_isShowTextViewBg];
    }
    [self removeFromSuperview];
}

#pragma mark ********* PublicMethod *********
- (void)setText:(NSString *)text textColor:(UIColor *)textColor isShowBg:(BOOL)isShowBg {
    _isEdit = YES;
    self.textVi.text = text;
    for (int i = 0; i < _colorsArr.count; i++) {
        UIColor *color = _colorsArr[i];
        if (CGColorEqualToColor(color.CGColor, textColor.CGColor)) {
            _selectColorIndex = i;
            break;
        }
    }
    self.textVi.textColor = textColor;
    _isShowTextViewBg = isShowBg;
    if (_isShowTextViewBg) {
        self.textVi.backgroundColor = textColor;
        //显示背景时，如果选择颜色为白色，则自动切换成黑色
        if (_selectColorIndex == 0) {
            self.textVi.textColor = [UIColor blackColor];
        }else {
            self.textVi.textColor = [UIColor whiteColor];
        }
    }else {
        self.textVi.textColor = textColor;
    }
    [self.colorsCollection reloadData];
}

#pragma mark ********* PrivateMethod *********
- (void)_registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)_removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)_updateTextViewFrame {
    if (CGRectEqualToRect(_currentKeyBoardFrame, CGRectZero)) {
        //隐藏键盘
        
    }else {
        //弹出键盘
        
    }
    CGFloat visibleHeight = kScreenHeight - CGRectGetHeight(_currentKeyBoardFrame) - kColorsHeight;
    CGFloat y = (visibleHeight - self.textVi.bounds.size.height) * 0.5;
    CGRect textViewFrame = CGRectMake(16, y, kTextViewWidth, self.textVi.bounds.size.height);
    if (CGRectGetMaxY(textViewFrame) > visibleHeight) {
        textViewFrame.origin.y = visibleHeight - self.textVi.bounds.size.height;
    }
    self.textVi.frame = textViewFrame;
}

#pragma mark ********* Getter *********
- (UIImageView *)backgroundIgv {
    if (!_backgroundIgv) {
        _backgroundIgv = [UIImageView new];
        _backgroundIgv.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _backgroundIgv;
}

- (UIView *)backgroundMask {
    if (!_backgroundMask) {
        _backgroundMask = [UIView new];
        _backgroundMask.backgroundColor = CXUIColorFromRGBA(0x000000, 0.6);
    }
    return _backgroundMask;
}

- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:0];
        [_cancelBtn setTitle:@"取消" forState:0];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_cancelBtn addTarget:self action:@selector(clickCancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneBtn.backgroundColor = kThemeColor;
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:0];
        [_doneBtn setTitle:@"完成" forState:0];
        _doneBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _doneBtn.clipsToBounds = YES;
        _doneBtn.layer.cornerRadius = 3;
        [_doneBtn addTarget:self action:@selector(clickAddWord) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}

- (UITextView *)textVi {
    if (!_textVi) {
        _textVi = [UITextView new];
        _textVi.backgroundColor = [UIColor clearColor];
        _textVi.textColor = [UIColor whiteColor];
        _textVi.font = [UIFont boldSystemFontOfSize:32];
        _textVi.returnKeyType = UIReturnKeyDone;
        _textVi.delegate = self;
        _textVi.textContainerInset = UIEdgeInsetsMake(8.0f, 16.0f, 8.0f, 16.0f);
        _textVi.textContainer.lineFragmentPadding = 0;
        _textVi.clipsToBounds = YES;
        _textVi.layer.cornerRadius = 8;
        _textVi.tintColor = kThemeColor;
    }
    return _textVi;
}

- (UICollectionView *)colorsCollection {
    if (!_colorsCollection) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _colorsCollection = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _colorsCollection.delegate = self;
        _colorsCollection.dataSource = self;
        _colorsCollection.backgroundColor = [UIColor clearColor];
    }
    return _colorsCollection;
}

@end
