//
//  CXCropView.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/10.
//

#import "CXCropView.h"
#import "Masonry.h"
#import "CXCropCase.h"
#import "UIImage+Crop.h"
#import "CXImageEditConfig.h"



#define CXBottomSafeHeight   (iPhoneX?(34):(0))

@interface CXCropView()<UIScrollViewDelegate>
@property(nonatomic, strong) UIScrollView *myScroll;
//缓存需要编辑的图片
@property(nonatomic, strong) UIImage *editImage;
//图片容器
@property(nonatomic, strong) UIImageView *editIgv;
//剪裁框
@property(nonatomic, strong) CXCropCase *cropCase;
//旋转方向
@property(nonatomic, assign) CXCropViewRotationDirection rotationDirection;
@end

@implementation CXCropView

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image {
    self = [super initWithFrame:frame];
    if (self) {
        self.editImage = image;
        [self setUpView];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"123");
}

#pragma mark ********* SetUpView *********
- (void)setUpView {
    self.backgroundColor = [UIColor blackColor];
    
    //设置scrollView的frame
    CGFloat scrollHeight = CGRectGetHeight(self.frame);
    CGFloat scrollWidth = CGRectGetHeight(self.frame);
    self.myScroll.frame = CGRectMake(-(scrollWidth - CGRectGetWidth(self.frame)) * 0.5, -(scrollWidth - CGRectGetHeight(self.frame)) * 0.5, scrollWidth, scrollHeight);
    [self addSubview:self.myScroll];
    
    [self.myScroll addSubview:self.editIgv];
    
    self.cropCase = [[CXCropCase alloc]initWithFrame:self.myScroll.frame scrollVi:self.myScroll imageView:self.editIgv];
    [self.cropCase addObserver:self forKeyPath:@"isCanRecovery" options:NSKeyValueObservingOptionNew context:nil];
    [self addSubview:self.cropCase];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isCanRecovery"]) {
        BOOL isCanRecovery = [change[@"new"] boolValue];
        if (_delegate && [_delegate respondsToSelector:@selector(cropViewShouldRecovery:isCanRecovery:)]) {
            [_delegate cropViewShouldRecovery:self isCanRecovery:isCanRecovery];
        }
    }
}

#pragma mark ********* UIScrollViewDelegate *********
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSLog(@"scrollViewWillBeginDragging");
    [self.cropCase beginImageresizer];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"scrollViewDidEndDecelerating");
    [self.cropCase endedImageresizer];
}

//结束拖动后无加速度
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (CGPointEqualToPoint(velocity, CGPointZero)) {
        NSLog(@"scrollViewWillEndDragging");
        [self.cropCase endedImageresizer];
    }
}

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.editIgv;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
    NSLog(@"scrollViewWillBeginZooming");
    [self.cropCase beginImageresizer];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    NSLog(@"scrollViewDidEndZooming");
    [self.cropCase endedImageresizer];
}

#pragma mark ********PublicMethod********
- (void)rotation {
    [self.cropCase rotation];
}

- (void)recovery {
    [self.cropCase recovery];
}

- (void)cropImageWithComplete:(void (^)(UIImage * image))complete {
    [self.cropCase cropImageWithComplete:complete];
}

#pragma mark ********* PrivateMethod *********

#pragma mark ********* Getter *********
- (UIScrollView *)myScroll {
    if (!_myScroll) {
        _myScroll = [[UIScrollView alloc]init];
        _myScroll.backgroundColor = [UIColor blackColor];
        _myScroll.delegate = self;
        _myScroll.maximumZoomScale = kMaxZoomScale;
        _myScroll.minimumZoomScale = kMinZoomScale;
        _myScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        _myScroll.showsVerticalScrollIndicator = NO;
        _myScroll.showsHorizontalScrollIndicator = NO;
        _myScroll.bounces = YES;
    }
    return _myScroll;
}

- (UIImageView *)editIgv {
    if (!_editIgv) {
        _editIgv = [UIImageView new];
        _editIgv.image = _editImage;
        _editIgv.contentMode = UIViewContentModeScaleToFill;
    }
    return _editIgv;
}
@end
