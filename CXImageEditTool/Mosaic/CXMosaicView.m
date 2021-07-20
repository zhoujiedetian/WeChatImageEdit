//
//  CXMosaicView.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/7.
//

#import "CXMosaicView.h"
#import "CXMosaicInfo.h"
#import "UIImage+Mosaic.h"

#define kPixOfMosaic 10
#define kWidthOfMosaic 10

@interface CXMosaicView()
@property(nonatomic, strong) NSMutableArray *lineInfos;

@property(nonatomic, strong) CALayer *mosaicLayer;
@property(nonatomic, strong) CAShapeLayer *maskLayer;
@property(nonatomic, strong) UIPanGestureRecognizer *pan;

@property(nonatomic, assign) CGMutablePathRef path;
@end

@implementation CXMosaicView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
    }
    return self;
}

#pragma mark ********* SetUpView *********
- (void)setUpView {
    _lineInfos = [NSMutableArray array];
    self.mosaicLayer.backgroundColor = [UIColor blueColor].CGColor;
    [self.layer addSublayer:self.mosaicLayer];
    
    //初始化遮罩图层
    [self.layer addSublayer:self.maskLayer];
    self.mosaicLayer.mask = self.maskLayer;
    
    _pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panMosaice:)];
    [self addGestureRecognizer:_pan];
    
    self.path = CGPathCreateMutable();
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.mosaicLayer.frame = self.frame;
}

#pragma mark ********* EventResponse *********
- (void)panMosaice:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        CGPoint startPoint = [pan locationInView:self];
        if (!self.path) {
            self.path = CGPathCreateMutable();
        }
        CGPathMoveToPoint(self.path, NULL, startPoint.x, startPoint.y);
        CGMutablePathRef path = CGPathCreateMutableCopy(self.path);
        NSMutableArray *pathArr = [NSMutableArray array];
        [pathArr addObject:(__bridge id _Nonnull)(path)];
        [_lineInfos addObject:pathArr];
        CGPathRelease(path);
        
        if (_delegate && [_delegate respondsToSelector:@selector(mosaicBegan:)]) {
            [_delegate mosaicBegan:self];
        }
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint endPoint = [pan locationInView:self];
        CGPathAddLineToPoint(self.path, NULL, endPoint.x, endPoint.y);
        CGMutablePathRef path = CGPathCreateMutableCopy(self.path);
        [[_lineInfos lastObject] addObject:(__bridge id _Nonnull)(path)];
        [self _drawMaskLayer];
        CGPathRelease(path);
    }else if (pan.state == UIGestureRecognizerStateEnded ||
              pan.state == UIGestureRecognizerStateCancelled) {
        if (_delegate && [_delegate respondsToSelector:@selector(mosaicDidEnd:)]) {
            [_delegate mosaicDidEnd:self];
        }
    }else {

    }
}

#pragma mark ********* PublicMethod *********
- (void)generateMosaicImage:(UIImage *)image {
    UIImage *mosaicImage = [image getMosaicImageFromOrginImageBlockLevel:kPixOfMosaic];
    self.mosaicLayer.contents = (__bridge id _Nullable)[mosaicImage CGImage];
}

- (BOOL)canRecall {
    return (_lineInfos.count > 0);
}

- (void)recall {
    if (_lineInfos.count > 0) {
        [_lineInfos removeLastObject];
    }
    
    [self _drawMaskLayer];
    self.path = nil;
    if (_lineInfos.count == 0) {
        self.maskLayer.path = NULL;
    }
}

#pragma mark ********* PrivateMethod *********
- (void)_drawMaskLayer {
    for (int i = 0; i < _lineInfos.count; i++) {
        NSArray *pathArr = _lineInfos[i];
        for (int i = 0; i < pathArr.count; i++) {
            CGMutablePathRef path = (__bridge CGMutablePathRef)(pathArr[i]);
            self.maskLayer.path = path;
        }
    }
}

#pragma mark ********* Getter *********
- (CALayer *)mosaicLayer {
    if (!_mosaicLayer) {
        _mosaicLayer = [CALayer layer];
    }
    return _mosaicLayer;
}

- (CAShapeLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [CAShapeLayer layer];
        _maskLayer.frame = self.bounds;
        _maskLayer.lineCap = kCALineCapRound;
        _maskLayer.lineJoin = kCALineJoinRound;
        _maskLayer.lineWidth = kWidthOfMosaic;
        _maskLayer.strokeColor = [[UIColor blueColor] CGColor];
        _maskLayer.fillColor = nil;
    }
    return _maskLayer;
}

@end
