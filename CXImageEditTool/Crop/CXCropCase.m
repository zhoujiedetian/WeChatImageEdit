//
//  CXCropCase.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/11.
//

#import "CXCropCase.h"
#import "Masonry.h"
#import "CXImageEditConfig.h"
#import "CXEditModel.h"

//剪裁框四个角大小
#define kCornerWidth 32
//剪裁框白色边的宽度
#define kCornerWhiteWidth 4
//最小剪裁宽度
#define kMinCropWidth 100
//最小剪裁高度
#define kMinCropHeight 100


typedef NS_ENUM(NSInteger, CXCropCornerType) {
    CXCropCornerTypeLeftTop = 101,
    CXCropCornerTypeRightTop,
    CXCropCornerTypeLeftBottom,
    CXCropCornerTypeRightBottom,
    CXCropCornerTypeTop,
    CXCropCornerTypeLeft,
    CXCropCornerTypeBottom,
    CXCropCornerTypeRight
};

@interface CXCropCase()
@property(nonatomic, strong) UIImageView *leftTopIgv;
@property(nonatomic, strong) UIImageView *rightTopIgv;
@property(nonatomic, strong) UIImageView *leftBottomIgv;
@property(nonatomic, strong) UIImageView *rightBottomIgv;

//顶部白线
@property(nonatomic, strong) UIView *topLine;
//顶部之下第一根白线
@property(nonatomic, strong) UIView *firstHorizontalLine;
//顶部之下第二根白线
@property(nonatomic, strong) UIView *secondHorizontalLine;
//底部白线
@property(nonatomic, strong) UIView *bottomLine;
//左侧白线
@property(nonatomic, strong) UIView *leftLine;
//左侧之右第一根白线
@property(nonatomic, strong) UIView *firstVerticalLine;
//左侧之右第二根白线
@property(nonatomic, strong) UIView *secondVerticalLine;
//右侧白线
@property(nonatomic, strong) UIView *rightLine;

@property(nonatomic, weak) UIScrollView *scroll;
@property(nonatomic, weak) UIImageView *imageVi;
//黑色蒙版图层
@property(nonatomic, strong) CAShapeLayer *maskLayer;

//旋转方向
@property(nonatomic, assign) CXCropViewRotationDirection rotationDirection;

//最大剪裁区域
@property(nonatomic, assign) CGRect maxCropRect;
//图片初始化Frame
@property(nonatomic, assign) CGRect imageOriginFrame;
//剪裁框初始位置
@property(nonatomic, assign) CGRect originCropFrame;
//当前的剪裁框位置
@property(nonatomic, assign) CGRect currentCropFrame;
//图片初始宽度
@property(nonatomic, assign) CGFloat initialImageWidth;
//图片初始高度
@property(nonatomic, assign) CGFloat initialImageHeight;
//scroll初始倍率
@property(nonatomic, assign) CGFloat initialScrollZoomScale;
//能否还原
@property (nonatomic, assign) BOOL isCanRecovery;
//是否正在拖动剪裁框
@property(nonatomic, assign) BOOL isPanning;
@end

@implementation CXCropCase

- (instancetype)initWithFrame:(CGRect)frame scrollVi:(UIScrollView *)scroll imageView:(UIImageView *)imageView {
    self = [super initWithFrame:frame];
    if (self) {
        self.scroll = scroll;
        self.imageVi = imageView;
        [self setUpView];
        [self _layoutInitialCropCaseAndScrollByInitialZoomScale];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame scrollVi:(UIScrollView *)scroll imageView:(UIImageView *)imageView cropModel:(CXCropModel *)cropModel {
    self = [super initWithFrame:frame];
    if (self) {
        self.scroll = scroll;
        self.imageVi = imageView;
        [self setUpView];
        [self _layoutInitialCropCaseAndScrollByCropModel:cropModel];
    }
    return self;
}

- (void)setUpView {
    self.initialScrollZoomScale = 0.7;
    self.backgroundColor = [UIColor clearColor];
    
    self.maskLayer = [CAShapeLayer layer];
    [self.layer addSublayer:self.maskLayer];
    
    [self addSubview:self.leftTopIgv];
    [self addSubview:self.rightTopIgv];
    [self addSubview:self.leftBottomIgv];
    [self addSubview:self.rightBottomIgv];
    
    [self addSubview:self.topLine];
    [self addSubview:self.firstHorizontalLine];
    [self addSubview:self.secondHorizontalLine];
    [self addSubview:self.bottomLine];
    [self addSubview:self.leftLine];
    [self addSubview:self.firstVerticalLine];
    [self addSubview:self.secondVerticalLine];
    [self addSubview:self.rightLine];
}

- (void)_layoutInitialCropCaseAndScrollByInitialZoomScale {
    //计算最大剪裁区域
    [self _caculateMaxCropRect];
    
    //调整图片frame
    UIView *imageContainer = self.imageVi.superview;
    CGSize imageSize = [self _caculateAdaptationImageSizeWithImageSize:CGSizeMake(self.imageVi.image.size.width, self.imageVi.image.size.height)];
    imageContainer.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    self.imageVi.frame = CGRectMake(0, 0, imageSize.width / self.scroll.zoomScale, imageSize.height / self.scroll.zoomScale);
    self.imageOriginFrame = imageContainer.frame;
    
    //初始化剪裁框四个角
    [self _caculateInitialCropCaseFrame];
    [self _updateCropCaseFrame:self.originCropFrame];
    //更新遮罩
    [self _updateImageViewMask];
    
    //更新scroll的内间距和偏移量
    UIEdgeInsets initialContentInset = [self _caculateInitailScrollViewEdge:imageSize];
    self.scroll.contentInset = initialContentInset;
    self.scroll.contentOffset = CGPointMake(-initialContentInset.left, -initialContentInset.top);
    self.scroll.contentSize = imageSize;
}

- (void)_layoutInitialCropCaseAndScrollByCropModel:(CXCropModel *)cropModel {
    
    //计算最大剪裁区域
    [self _caculateMaxCropRect];
    
    //图片的初始大小
    self.imageOriginFrame = cropModel.imageViewOriginFrame;
    
    //更新剪裁框位置
    self.initialImageWidth = cropModel.cropCaseInitialFrame.size.width;
    self.initialImageHeight = cropModel.cropCaseInitialFrame.size.height;
    self.originCropFrame = cropModel.cropCaseInitialFrame;
    self.currentCropFrame = cropModel.cropCaseFrame;
    [self _updateCropCaseFrame:self.currentCropFrame];
    //更新遮罩
    [self _updateImageViewMask];
    //更新scroll的内间距
    [self _updateContentInsetWithCropFrame:self.currentCropFrame];
    
    self.scroll.maximumZoomScale = kMaxZoomScale;
    CGFloat minZoomScale = 1;
    CGFloat adjustWidth = cropModel.cropCaseFrame.size.width;
    CGFloat adjustHeight = cropModel.cropCaseFrame.size.height;
    if (cropModel.cropCaseFrame.size.width >= cropModel.cropCaseFrame.size.height) {
        minZoomScale = adjustWidth / self.initialImageWidth;
        CGFloat imageH = self.initialImageHeight * minZoomScale;
        CGFloat trueImageH = adjustHeight;
        if (imageH < trueImageH) {
            minZoomScale *= (trueImageH / imageH);
        }
    } else {
        minZoomScale = adjustHeight / self.initialImageHeight;
        CGFloat imageW = self.initialImageWidth * minZoomScale;
        CGFloat trueImageW = adjustWidth;
        if (imageW < trueImageW) {
            minZoomScale *= (trueImageW / imageW);
        }
    }
    self.scroll.minimumZoomScale = minZoomScale * self.initialScrollZoomScale;
}

- (void)didMoveToSuperview {
    //检测还原按钮能否点击
    [self _checkShouldRecovery];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    //如果剪裁框正在拖动，拦截事件并处理
    if (_isPanning) {
        return YES;
    }
    
    //如果scroll正在拖动或者正在缩放，不拦截事件
    if (self.scroll.isDragging || self.scroll.isZooming) {
        return NO;
    }
    
    CGRect leftTopFrame = self.leftTopIgv.frame;
    CGRect leftBottomFrame = self.leftBottomIgv.frame;
    CGRect rightTopFrame = self.rightTopIgv.frame;
    CGRect rightBottomFrame = self.rightBottomIgv.frame;
    if (CGRectContainsPoint(leftTopFrame, point) ||
        CGRectContainsPoint(leftBottomFrame, point) ||
        CGRectContainsPoint(rightTopFrame, point) ||
        CGRectContainsPoint(rightBottomFrame, point)) {
        return YES;
    }
    return NO;
}

#pragma mark ********* EventResponse *********
- (void)cropCaseMoved:(UIPanGestureRecognizer *)pan {
    UIView *panVi = pan.view;
    //每次移动的距离
    CGPoint translate = [pan translationInView:self];
    [pan setTranslation:CGPointZero inView:self];
    //取对角坐标，如果x不变动则记录minX，变动则记录MaxX，如果y不变动则记录minY，变动则记录MaxY，
    static CGPoint startCropCaseDiagonal;
    //记录开始移动之前的宽
    static CGFloat startWidth;
    //记录开始移动之前的高
    static CGFloat startHeight;
    if (pan.state == UIGestureRecognizerStateBegan) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        //停止scroll的滑动动画
        if (self.scroll.isDecelerating) {
            [self.scroll setContentOffset:self.scroll.contentOffset animated:NO];
        }
        //隐藏黑色遮罩
        self.maskLayer.hidden = YES;
        self.isPanning = YES;
        
        switch (panVi.tag) {
            case CXCropCornerTypeLeftTop:
                startCropCaseDiagonal = CGPointMake(self.currentCropFrame.origin.x + self.currentCropFrame.size.width, self.currentCropFrame.origin.y + self.currentCropFrame.size.height);
                break;
            case CXCropCornerTypeRightTop:
                startCropCaseDiagonal = CGPointMake(self.currentCropFrame.origin.x, self.currentCropFrame.origin.y + self.currentCropFrame.size.height);
                break;
            case CXCropCornerTypeLeftBottom:
                startCropCaseDiagonal = CGPointMake(self.currentCropFrame.origin.x + self.currentCropFrame.size.width, self.currentCropFrame.origin.y);
                break;
            case CXCropCornerTypeRightBottom:
                startCropCaseDiagonal = CGPointMake(self.currentCropFrame.origin.x, self.currentCropFrame.origin.y);
                break;
                
            default:
                break;
        }
        
        startWidth = self.currentCropFrame.size.width;
        startHeight = self.currentCropFrame.size.height;
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        CGFloat x = self.currentCropFrame.origin.x;
        CGFloat y = self.currentCropFrame.origin.y;
        CGFloat width = self.currentCropFrame.size.width;
        CGFloat height = self.currentCropFrame.size.height;
        CGFloat widthScale = 0;
        CGFloat heightScale = 0;
        switch (panVi.tag) {
            case CXCropCornerTypeLeftTop:
            {
                x += translate.x;
                y += translate.y;
                
                //x不能超出最大剪裁区域
                if (x <= self.maxCropRect.origin.x) {
                    x = self.maxCropRect.origin.x;
                }
                
                //y不能超出最大剪裁区域
                if (y <= self.maxCropRect.origin.y) {
                    y = self.maxCropRect.origin.y;
                }
                
                width = startCropCaseDiagonal.x - x;
                //最小剪裁区域为（100，100）
                if (width <= kMinCropWidth) {
                    width = kMinCropWidth;
                    x = startCropCaseDiagonal.x - width;
                }
                height = startCropCaseDiagonal.y - y;
                if (height <= kMinCropHeight) {
                    height = kMinCropHeight;
                    y = startCropCaseDiagonal.y - height;
                }
                
                //剪裁的高度和宽度不能超过图片最大放大值下的宽高
                if (width > startWidth) {
                    widthScale = width / self.initialImageWidth;
                }
                if (height > startHeight) {
                    heightScale = height / self.initialImageHeight;
                }
                if (widthScale > self.scroll.maximumZoomScale) {
                    width = self.initialImageWidth * self.scroll.maximumZoomScale;
                    x = startCropCaseDiagonal.x - width;
                }
                if (heightScale > self.scroll.maximumZoomScale) {
                    height = self.initialImageHeight * self.scroll.maximumZoomScale;
                    y = startCropCaseDiagonal.y - height;
                }
            }
                break;
            case CXCropCornerTypeRightTop:
            {
                y += translate.y;
                width += translate.x;
                
                if (y < self.maxCropRect.origin.y) {
                    y = self.maxCropRect.origin.y;
                }
                
                CGFloat maxCropX = CGRectGetMaxX(self.maxCropRect);
                if (x + width > maxCropX) {
                    width = maxCropX - startCropCaseDiagonal.x;
                }
                
                height = startCropCaseDiagonal.y - y;
                //最小剪裁区域为（100，100）
                if (width <= kMinCropWidth) {
                    width = kMinCropWidth;
                }
                if (height <= kMinCropHeight) {
                    height = kMinCropHeight;
                    y = startCropCaseDiagonal.y - height;
                }
                
                //剪裁的高度和宽度不能超过图片最大放大值下的宽高
                if (width > startWidth) {
                    widthScale = width / self.initialImageWidth;
                }
                if (height > startHeight) {
                    heightScale = height / self.initialImageHeight;
                }
                if (widthScale > self.scroll.maximumZoomScale) {
                    width = self.initialImageWidth * self.scroll.maximumZoomScale;
                }
                if (heightScale > self.scroll.maximumZoomScale) {
                    height = self.initialImageHeight * self.scroll.maximumZoomScale;
                    y = startCropCaseDiagonal.y - height;
                }
            }
                break;
            case CXCropCornerTypeLeftBottom:
            {
                x += translate.x;
                height += translate.y;
                
                //x不能超出最大剪裁区域
                if (x <= self.maxCropRect.origin.x) {
                    x = self.maxCropRect.origin.x;
                }
                
                CGFloat maxCropY = CGRectGetMaxY(self.maxCropRect);
                if (y + height > maxCropY) {
                    height = maxCropY - startCropCaseDiagonal.y;
                }
                
                width = startCropCaseDiagonal.x - x;
                //最小剪裁区域为（100，100）
                if (width <= kMinCropWidth) {
                    width = kMinCropWidth;
                    x = startCropCaseDiagonal.x - width;
                }
                if (height <= kMinCropHeight) {
                    height = kMinCropHeight;
                }
                
                //剪裁的高度和宽度不能超过图片最大放大值下的宽高
                if (width > startWidth) {
                    widthScale = width / self.initialImageWidth;
                }
                if (height > startHeight) {
                    heightScale = height / self.initialImageHeight;
                }
                if (widthScale > self.scroll.maximumZoomScale) {
                    width = self.initialImageWidth * self.scroll.maximumZoomScale;
                    x = startCropCaseDiagonal.x - width;
                }
                if (heightScale > self.scroll.maximumZoomScale) {
                    height = self.initialImageHeight * self.scroll.maximumZoomScale;
                }
            }
                break;
            case CXCropCornerTypeRightBottom:
            {
                width += translate.x;
                height += translate.y;
                
                CGFloat maxCropX = CGRectGetMaxX(self.maxCropRect);
                if (x + width > maxCropX) {
                    width = maxCropX - startCropCaseDiagonal.x;
                }
                
                CGFloat maxCropY = CGRectGetMaxY(self.maxCropRect);
                if (y + height > maxCropY) {
                    height = maxCropY - startCropCaseDiagonal.y;
                }
                
                //最小剪裁区域为（100，100）
                if (width <= kMinCropWidth) {
                    width = kMinCropWidth;
                }
                if (height <= kMinCropHeight) {
                    height = kMinCropHeight;
                }
                
                //剪裁的高度和宽度不能超过图片最大放大值下的宽高
                if (width > startWidth) {
                    widthScale = width / self.initialImageWidth;
                }
                if (height > startHeight) {
                    heightScale = height / self.initialImageHeight;
                }
                if (widthScale > self.scroll.maximumZoomScale) {
                    width = self.initialImageWidth * self.scroll.maximumZoomScale;
                }
                if (heightScale > self.scroll.maximumZoomScale) {
                    height = self.initialImageHeight * self.scroll.maximumZoomScale;
                }
            }
                break;
            default:
                break;
        }
        
        //Zoom
        CGFloat zoomScale = MAX(widthScale, heightScale);
        zoomScale *= self.initialScrollZoomScale;
        if (zoomScale > self.scroll.zoomScale) {
            self.scroll.zoomScale = zoomScale;
        }
        
        [self _updateCropCaseFrame:CGRectMake(x, y, width, height)];
        
        //ContentOffset
        CGPoint contentOffset = self.scroll.contentOffset;
        CGSize contentSize = self.scroll.contentSize;
        CGRect convertFrame = [self convertRect:self.currentCropFrame toView:self.scroll];
        if (convertFrame.origin.x < 0) {
            contentOffset.x -= convertFrame.origin.x;
        }else if (CGRectGetMaxX(convertFrame) > contentSize.width) {
            contentOffset.x -= CGRectGetMaxX(convertFrame) - contentSize.width;
        }
        
        if (convertFrame.origin.y < 0) {
            contentOffset.y -= convertFrame.origin.y;
        }else if (CGRectGetMaxY(convertFrame) > contentSize.height) {
            contentOffset.y -= CGRectGetMaxY(convertFrame) - contentSize.height;
        }
        if (!CGPointEqualToPoint(contentOffset, self.scroll.contentOffset)) {
            self.scroll.contentOffset = contentOffset;
        }
        
        
    }else if (pan.state == UIGestureRecognizerStateEnded ||
              pan.state == UIGestureRecognizerStateCancelled ||
              pan.state == UIGestureRecognizerStateFailed) {
        
        [self performSelector:@selector(_makeCropCaseCenter) withObject:nil afterDelay:0.65];
        self.isPanning = NO;
    }else {

    }
}

//使剪裁框居中
- (void)_makeCropCaseCenter {
    [self _updateCropCaseToCenterWithAnimationDuration:0.25 isAdjustResize:YES];
}

#pragma mark ********* PublicMethod *********
//外部接口，更新旋转方向
- (void)rotationWithDirection:(CXCropViewRotationDirection)rotationDirection {
    [self _updateRotation:rotationDirection];
    [self _updateCropCaseToCenterWithAnimationDuration:-1 isAdjustResize:YES];
}

- (void)rotation {
    self.rotationDirection = (self.rotationDirection + 1) % 4;
    CGFloat scale = 0;
    if (self.rotationDirection == CXCropViewRotationDirectionLeft ||
        self.rotationDirection == CXCropViewRotationDirectionRight) {
        scale = kScreenWidth / self.scroll.bounds.size.height;
    }else {
        scale = self.scroll.bounds.size.height / kScreenWidth;
    }
    CGFloat angle = -M_PI / 2;

    CATransform3D svTransform = self.scroll.layer.transform;
    svTransform = CATransform3DRotate(svTransform, angle, 0, 0, 1);

    CATransform3D fvTransform = self.layer.transform;
    fvTransform = CATransform3DRotate(fvTransform, angle, 0, 0, 1);

    
    UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
        self.scroll.layer.transform = svTransform;
        self.layer.transform = fvTransform;
        [self rotationWithDirection:self.rotationDirection];
    } completion:^(BOOL finished) {

    }];
}

//还原
- (void)recovery {
    self.scroll.minimumZoomScale = 0.7;
    self.scroll.maximumZoomScale = kMaxZoomScale;
    
    self.maskLayer.hidden = YES;
    [self _updateRotation:CXCropViewRotationDirectionUp];
    self.currentCropFrame = self.originCropFrame;
    [UIView animateWithDuration:0.2 animations:^{
        self.scroll.zoomScale = 0.7;
        self.scroll.layer.transform = CATransform3DIdentity;
        self.layer.transform = CATransform3DIdentity;
        self.layer.opacity = 1;
        [self _updateCropCaseToCenterWithAnimationDuration:-1 isAdjustResize:YES];
    } completion:^(BOOL finished) {
        self.window.userInteractionEnabled = YES;
    }];
}

//剪裁图片
- (void)cropImageWithComplete:(void (^)(UIImage * image, CXCropModel *cropModel))complete; {
    UIImage *image = self.imageVi.image;

    UIImageOrientation orientation;
    switch (self.rotationDirection) {
        case CXCropViewRotationDirectionUp:
            orientation = UIImageOrientationLeft;
            break;

        case CXCropViewRotationDirectionDown:
            orientation = UIImageOrientationDown;
            break;

        case CXCropViewRotationDirectionRight:
            orientation = UIImageOrientationRight;
            break;

        default:
            orientation = UIImageOrientationUp;
            break;
    }

    CGRect cropFrame = [self convertRect:self.currentCropFrame toView:self.imageVi];

    // 宽高比不变，所以宽度高度的比例是一样
    CGFloat scale = image.size.width / self.imageVi.bounds.size.width;
    CGFloat orgX = cropFrame.origin.x * scale;
    CGFloat orgY = cropFrame.origin.y * scale;
    CGFloat width = cropFrame.size.width * scale;
    CGFloat height = cropFrame.size.height * scale;

    CGRect cropRect = CGRectMake(orgX, orgY, width, height);
    
    double topPercentToImage = CGRectGetMinY(cropFrame) / CGRectGetHeight(self.imageVi.frame);
    double leftPercentToImage = CGRectGetMinX(cropFrame) / CGRectGetWidth(self.imageVi.frame);
    double bottomPercentToImage = 1 - CGRectGetMaxY(cropFrame) / CGRectGetHeight(self.imageVi.frame);
    double rightPercentToImage = 1 - CGRectGetMaxX(cropFrame) / CGRectGetWidth(self.imageVi.frame);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        CGImageRef imgRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);

        CGFloat deviceScale = [UIScreen mainScreen].scale;
        UIGraphicsBeginImageContextWithOptions(cropFrame.size, 0, deviceScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, cropFrame.size.height);
        CGContextScaleCTM(context, 1, -1);
        CGContextDrawImage(context, CGRectMake(0, 0, cropFrame.size.width, cropFrame.size.height), imgRef);

        UIImage *newImg = UIGraphicsGetImageFromCurrentImageContext();
        newImg = [strongSelf _getTargetDirectionImage:newImg];

        CGImageRelease(imgRef);
        UIGraphicsEndImageContext();

        dispatch_async(dispatch_get_main_queue(), ^{
            
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:cropFrame];
            maskLayer.path = bezierPath.CGPath;
            self.imageVi.superview.layer.mask = maskLayer;
            
            CXCropModel *cropModel = [CXCropModel new];
            cropModel.contentOffset = self.scroll.contentOffset;
            cropModel.contentInset = self.scroll.contentInset;
            cropModel.zoomScale = self.scroll.zoomScale;
            cropModel.cropCaseFrame = self.currentCropFrame;
            cropModel.cropFrameOnImageView = cropFrame;
            cropModel.cropCaseInitialFrame = self.originCropFrame;
            cropModel.cropImage = newImg;
            cropModel.cropToImagePercentEdge = UIEdgeInsetsMake(topPercentToImage, leftPercentToImage, bottomPercentToImage, rightPercentToImage);
            cropModel.imageViewOriginFrame = self.imageOriginFrame;
            cropModel.rotationDirection = self.rotationDirection;
            complete(newImg, cropModel);
        });
    });
}

- (void)beginImageresizer {
    self.maskLayer.hidden = YES;
}

- (void)endedImageresizer {
    UIEdgeInsets contentInset = [self _updateContentInsetWithCropFrame:[self _adjustCropCaseFrameToSuitable]];
    self.scroll.contentInset = contentInset;
    [self _updateImageViewMask];
}

- (void)cancelDelayHandle {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark ********* PrivateMethod *********
//计算最大剪裁区域
- (void)_caculateMaxCropRect {
    //最大的剪裁宽度
//    CGFloat maxCropWidth = (CGRectGetWidth(self.superview.frame) - kCropLeft - kCropRight);
    CGFloat maxCropWidth = kScreenWidth * 0.7;
    //最大的剪裁高度
//    CGFloat maxCropHeight = (CGRectGetHeight(self.superview.frame) - kCropTop - kCropBottom);
    CGFloat maxCropHeight = kScreenHeight * 0.7;
    CGRect result;
    CGFloat x;
    CGFloat y;
    CGFloat width;
    CGFloat height;
    
    width = maxCropWidth;
    height = maxCropHeight;
    
    if (_rotationDirection == CXCropViewRotationDirectionLeft ||
        _rotationDirection == CXCropViewRotationDirectionRight) {
        width = maxCropHeight;
        height = maxCropWidth;
    }
    x = (self.bounds.size.width - width) * 0.5;
    y = (self.bounds.size.height - height) * 0.5;
    y = (self.bounds.size.height - kStatusBarHeight - (CXBottomSafeHeight + 44) - height) * 0.5 + kStatusBarHeight;
    result = CGRectMake(x, y, width, height);
    self.maxCropRect = result;
}

//计算初始化剪裁框的位置
- (void)_caculateInitialCropCaseFrame {
    UIView *imageContainer = self.imageVi.superview;
    self.initialImageWidth = imageContainer.frame.size.width;
    self.initialImageHeight = imageContainer.frame.size.height;
//    CGFloat x = CGRectGetMinX(self.maxCropRect) + (CGRectGetWidth(self.maxCropRect) - self.initialImageWidth) * 0.5;
    CGFloat x = (self.bounds.size.width - self.initialImageWidth) * 0.5;
//    CGFloat y = CGRectGetMinY(self.maxCropRect) + (CGRectGetHeight(self.maxCropRect) - self.initialImageHeight) * 0.5;
    CGFloat y = (self.bounds.size.height - self.initialImageHeight) * 0.5;
    CGFloat width = self.initialImageWidth;
    CGFloat height = self.initialImageHeight;
    self.originCropFrame = CGRectMake(x, y, width, height);
    self.currentCropFrame = self.originCropFrame;
}

//更新剪裁框四个角位置
- (void)_updateCropCaseFrame:(CGRect)cropCaseFrame {
    self.currentCropFrame = cropCaseFrame;
    self.leftTopIgv.frame = CGRectMake(cropCaseFrame.origin.x - kCornerWhiteWidth, cropCaseFrame.origin.y - kCornerWhiteWidth, kCornerWidth, kCornerWidth);
    self.rightTopIgv.frame = CGRectMake(CGRectGetMaxX(cropCaseFrame) - kCornerWidth + kCornerWhiteWidth, cropCaseFrame.origin.y - kCornerWhiteWidth, kCornerWidth, kCornerWidth);
    self.leftBottomIgv.frame = CGRectMake(cropCaseFrame.origin.x - kCornerWhiteWidth, CGRectGetMaxY(cropCaseFrame) - kCornerWidth + kCornerWhiteWidth, kCornerWidth, kCornerWidth);
    self.rightBottomIgv.frame = CGRectMake(CGRectGetMaxX(cropCaseFrame) - kCornerWidth + kCornerWhiteWidth, CGRectGetMaxY(cropCaseFrame) - kCornerWidth + kCornerWhiteWidth, kCornerWidth, kCornerWidth);
    
    self.topLine.frame = CGRectMake(cropCaseFrame.origin.x, cropCaseFrame.origin.y, CGRectGetWidth(cropCaseFrame), 1);
    self.firstHorizontalLine.frame = CGRectMake(cropCaseFrame.origin.x, cropCaseFrame.origin.y + CGRectGetHeight(cropCaseFrame) * (1 / 3.0), CGRectGetWidth(cropCaseFrame), 1);
    self.secondHorizontalLine.frame = CGRectMake(cropCaseFrame.origin.x, cropCaseFrame.origin.y + CGRectGetHeight(cropCaseFrame) * (2 / 3.0), CGRectGetWidth(cropCaseFrame), 1);
    self.bottomLine.frame = CGRectMake(cropCaseFrame.origin.x, CGRectGetMaxY(cropCaseFrame) - 1, CGRectGetWidth(cropCaseFrame), 1);

    self.leftLine.frame = CGRectMake(cropCaseFrame.origin.x, cropCaseFrame.origin.y, 1, CGRectGetHeight(cropCaseFrame));
    self.firstVerticalLine.frame = CGRectMake(cropCaseFrame.origin.x + CGRectGetWidth(cropCaseFrame) * (1 / 3.0), cropCaseFrame.origin.y, 1, CGRectGetHeight(cropCaseFrame));
    self.secondVerticalLine.frame = CGRectMake(cropCaseFrame.origin.x + CGRectGetWidth(cropCaseFrame) * (2 / 3.0), cropCaseFrame.origin.y, 1, CGRectGetHeight(cropCaseFrame));
    self.rightLine.frame = CGRectMake(CGRectGetMaxX(cropCaseFrame) - 1, cropCaseFrame.origin.y, 1, CGRectGetHeight(cropCaseFrame));
}

//更新旋转方向
- (void)_updateRotation:(CXCropViewRotationDirection)rotationDirection {
    _rotationDirection = rotationDirection;
    [self _caculateMaxCropRect];
}

//更新剪裁框位置
- (void)_updateCropCaseToCenterWithAnimationDuration:(CGFloat)duration isAdjustResize:(BOOL)isAdjustResize {
    
    CGFloat adjustX = 0;
    CGFloat adjustY = 0;
    CGFloat adjustWidth = 0;
    CGFloat adjustHeight = 0;
    if (isAdjustResize) {
        CGFloat cropCaseWHScale = self.currentCropFrame.size.width / self.currentCropFrame.size.height;
        if (cropCaseWHScale >= 1) {
            adjustWidth = CGRectGetWidth(self.maxCropRect);
            adjustHeight = adjustWidth / cropCaseWHScale;
            if (adjustHeight > CGRectGetHeight(self.maxCropRect)) {
                adjustHeight = CGRectGetHeight(self.maxCropRect);
                adjustWidth = adjustHeight * cropCaseWHScale;
            }
            //防止达到最大zoom值，剪裁框超过图片的宽度
            if (adjustWidth > self.initialImageWidth * self.scroll.maximumZoomScale) {
                adjustWidth = self.initialImageWidth * self.scroll.maximumZoomScale;
                adjustHeight = adjustWidth / cropCaseWHScale;
            }
        } else {
            adjustHeight = CGRectGetHeight(self.maxCropRect);
            adjustWidth = adjustHeight * cropCaseWHScale;
            if (adjustWidth > CGRectGetWidth(self.maxCropRect)) {
                adjustWidth = CGRectGetWidth(self.maxCropRect);
                adjustHeight = adjustWidth / cropCaseWHScale;
            }
            //防止达到最大zoom值，剪裁框超过图片的高度
            if (adjustHeight > self.initialImageHeight * self.scroll.maximumZoomScale) {
                adjustHeight = self.initialImageHeight * self.scroll.maximumZoomScale;
                adjustWidth = adjustHeight * cropCaseWHScale;
            }
        }
//        adjustX = self.maxCropRect.origin.x + (CGRectGetWidth(self.maxCropRect) - adjustWidth) * 0.5;
        adjustX = (self.bounds.size.width - adjustWidth) * 0.5;
//        adjustY = self.maxCropRect.origin.y + (CGRectGetHeight(self.maxCropRect) - adjustHeight) * 0.5;
        adjustY = (self.bounds.size.height - adjustHeight) * 0.5;
    }else {
//        adjustWidth = CGRectGetWidth(self.currentCropFrame);
//        adjustHeight = CGRectGetHeight(self.currentCropFrame);
//        adjustX = self.currentCropFrame.origin.x;
//        adjustY = self.currentCropFrame.origin.y;
//        if (_rotationDirection == CXCropViewRotationDirectionUp) {
//            adjustY = adjustY - (kCropBottom - kCropTop);
//        }
    }
    CGRect adjustFrame = CGRectMake(adjustX, adjustY, adjustWidth, adjustHeight);
    
    //contentInset
    UIEdgeInsets contentInset = [self _updateContentInsetWithCropFrame:adjustFrame];
    
    //contentOffset
    CGPoint contentOffset = CGPointZero;
    CGPoint origin = self.currentCropFrame.origin;
    CGPoint originOnImageVi = [self convertPoint:origin toView:self.imageVi];
    // 这个convertPoint是相对self.imageVi.bounds上的点，所以要✖️zoomScale拿到相对frame实际显示的大小
    contentOffset.x = -contentInset.left + originOnImageVi.x * self.scroll.zoomScale;
    contentOffset.y = -contentInset.top + originOnImageVi.y * self.scroll.zoomScale;
    
    //zoom
    CGFloat convertScale = self.currentCropFrame.size.width / adjustWidth;
//    CGFloat diffX = -adjustFrame.origin.x * convertScale;
//    CGFloat diffY = -adjustFrame.origin.y * convertScale;
//    CGRect zoomFrame = CGRectInset(self.currentCropFrame, diffX, diffY);
    CGFloat testScale = 1 / convertScale;
    CGFloat scrollScale = self.scroll.zoomScale * testScale;
    if (scrollScale < self.scroll.minimumZoomScale) {
        self.scroll.minimumZoomScale = scrollScale;
    }
    CGFloat testWidth = self.scroll.bounds.size.width / testScale;
    CGFloat testHeight = self.scroll.bounds.size.height / testScale;
    CGRect zoomFrame = CGRectMake(CGRectGetMidX(self.currentCropFrame) - 0.5 * testWidth, CGRectGetMidY(self.currentCropFrame) - 0.5 * testHeight, testWidth, testHeight);
    zoomFrame = [self convertRect:zoomFrame toView:self.imageVi];
    
    void (^zoomBlock)(void) = ^{
        self.scroll.contentInset = contentInset;
        self.scroll.contentOffset = contentOffset;
        [self.scroll zoomToRect:zoomFrame animated:NO];
        
    };
    
    void (^completeBlock)(void) = ^{
        
        [self _updateImageViewMask];
        
        self.window.userInteractionEnabled = YES;

        CGFloat minZoomScale = 1;
        if (adjustWidth >= adjustHeight) {
            minZoomScale = adjustWidth / self.initialImageWidth;
            CGFloat imageH = self.initialImageHeight * minZoomScale;
            CGFloat trueImageH = adjustHeight;
            if (imageH < trueImageH) {
                minZoomScale *= (trueImageH / imageH);
            }
        } else {
            minZoomScale = adjustHeight / self.initialImageHeight;
            CGFloat imageW = self.initialImageWidth * minZoomScale;
            CGFloat trueImageW = adjustWidth;
            if (imageW < trueImageW) {
                minZoomScale *= (trueImageW / imageW);
            }
        }
        self.scroll.minimumZoomScale = minZoomScale * self.initialScrollZoomScale;
    };
    if (duration > 0) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^{
            zoomBlock();
            [self _updateCropCaseFrame:adjustFrame];
        } completion:^(BOOL finished) {
            completeBlock();
        }];
    }else {
        [self _updateCropCaseFrame:adjustFrame];
        zoomBlock();
        completeBlock();
    }
    
}

//根据剪裁框来更新scroll的内间距
- (UIEdgeInsets)_updateContentInsetWithCropFrame:(CGRect)cropFrame {
    CGFloat top = 0;
    CGFloat left = 0;
    CGFloat bottom = 0;
    CGFloat right = 0;
    top = cropFrame.origin.y;
    left = cropFrame.origin.x;
    bottom = self.bounds.size.height - CGRectGetMaxY(cropFrame);
    right = self.bounds.size.width - CGRectGetMaxX(cropFrame);
    UIEdgeInsets contentInset = UIEdgeInsetsMake(top, left, bottom, right);
    return contentInset;
}

- (BOOL)_isEqualOriginalFrame {
    CGSize imageresizerSize = self.currentCropFrame.size;
    CGSize imageViewSzie = self.imageVi.bounds.size;
    return (fabs(imageresizerSize.width - imageViewSzie.width) <= 1 &&
            fabs(imageresizerSize.height - imageViewSzie.height) <= 1);
}

//根据方向获取正确的图片
- (UIImage *)_getTargetDirectionImage:(UIImage *)image {
    UIImageOrientation orientation;
    switch (self.rotationDirection) {
        case CXCropViewRotationDirectionLeft:
            orientation = UIImageOrientationLeft;
            break;
            
        case CXCropViewRotationDirectionDown:
            orientation = UIImageOrientationDown;
            break;
            
        case CXCropViewRotationDirectionRight:
            orientation = UIImageOrientationRight;
            break;
            
        default:
            orientation = UIImageOrientationUp;
            break;
    }
    return [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:orientation];
}

//调整剪裁框到合适的大小
- (CGRect)_adjustCropCaseFrameToSuitable {
    CGFloat adjustWidth = 0;
    CGFloat adjustHeight = 0;
    CGFloat cropCaseWHScale = self.currentCropFrame.size.width / self.currentCropFrame.size.height;
    if (cropCaseWHScale >= 1) {
        adjustWidth = CGRectGetWidth(self.maxCropRect);
        adjustHeight = adjustWidth / cropCaseWHScale;
        if (adjustHeight > CGRectGetHeight(self.maxCropRect)) {
            adjustHeight = CGRectGetHeight(self.maxCropRect);
            adjustWidth = adjustHeight * cropCaseWHScale;
        }
        //防止达到最大zoom值，剪裁框超过图片的宽度
        if (adjustWidth > self.initialImageWidth * self.scroll.maximumZoomScale) {
            adjustWidth = self.initialImageWidth * self.scroll.maximumZoomScale;
            adjustHeight = adjustWidth / cropCaseWHScale;
        }
    } else {
        adjustHeight = CGRectGetHeight(self.maxCropRect);
        adjustWidth = adjustHeight * cropCaseWHScale;
        if (adjustWidth > CGRectGetWidth(self.maxCropRect)) {
            adjustWidth = CGRectGetWidth(self.maxCropRect);
            adjustHeight = adjustWidth / cropCaseWHScale;
        }
        //防止达到最大zoom值，剪裁框超过图片的高度
        if (adjustHeight > self.initialImageHeight * self.scroll.maximumZoomScale) {
            adjustHeight = self.initialImageHeight * self.scroll.maximumZoomScale;
            adjustWidth = adjustHeight * cropCaseWHScale;
        }
    }
    CGFloat adjustX = self.maxCropRect.origin.x + (CGRectGetWidth(self.maxCropRect) - adjustWidth) * 0.5;
    CGFloat adjustY = self.maxCropRect.origin.y + (CGRectGetHeight(self.maxCropRect) - adjustHeight) * 0.5;
    return CGRectMake(adjustX, adjustY, adjustWidth, adjustHeight);
}

//计算图片适配后的大小
- (CGSize)_caculateAdaptationImageSizeWithImageSize:(CGSize)imageSize {
    //计算图片方向
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    CGFloat screenRatio = CGRectGetWidth(self.maxCropRect) / CGRectGetHeight(self.maxCropRect);
    CGFloat imageRatio = imageWidth / imageHeight;
    BOOL isHorizontal = (imageRatio >= screenRatio);
    
    //计算图片适配后的大小
    CGSize result;
    if (isHorizontal) {
        result = CGSizeMake(CGRectGetWidth(self.maxCropRect), imageHeight * (CGRectGetWidth(self.maxCropRect) / imageWidth));
    }else {
        result = CGSizeMake(imageWidth * (CGRectGetHeight(self.maxCropRect) / imageHeight), CGRectGetHeight(self.maxCropRect));
    }
    return result;
}

//计算scrollView的内间距
- (UIEdgeInsets)_caculateInitailScrollViewEdge:(CGSize)imageSize {
    UIEdgeInsets result;
    result = UIEdgeInsetsMake(
                              (self.scroll.bounds.size.height - imageSize.height) * 0.5,
                              (self.scroll.bounds.size.width - imageSize.width) * 0.5,
                              (self.scroll.bounds.size.height - imageSize.height) * 0.5,
                              (self.scroll.bounds.size.width - imageSize.width) * 0.5
                              );
    return result;
}

//更新图片黑色遮罩
- (void)_updateImageViewMask {
    
    if (self.maskLayer.hidden == YES) {
        
    }
    self.maskLayer.hidden = NO;
    UIBezierPath *clearPath = [UIBezierPath bezierPathWithRect:self.currentCropFrame];
    UIBezierPath *fillPath = [UIBezierPath bezierPathWithRect:self.bounds];
    [fillPath appendPath:clearPath];
    [fillPath setUsesEvenOddFillRule:YES];
    self.maskLayer.fillRule = kCAFillRuleEvenOdd;
    self.maskLayer.path = fillPath.CGPath;
    self.maskLayer.fillColor = CXUIColorFromRGBA(0x000000, 0.6).CGColor;
    
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = @0;
    opacity.toValue = @1;
    opacity.duration = 0.25;
    opacity.removedOnCompletion = YES;
    [self.maskLayer addAnimation:opacity forKey:nil];
    
    [self _checkShouldRecovery];
}

//检测是否可以还原
- (void)_checkShouldRecovery {
    NSLog(@"%d", CGRectEqualToRect(self.imageVi.superview.frame, self.imageOriginFrame));
    NSLog(@"%d", _rotationDirection == CXCropViewRotationDirectionUp);
    NSLog(@"%d", self.scroll.zoomScale == self.initialScrollZoomScale);
    NSLog(@"%d", CGRectEqualToRect(self.currentCropFrame, self.originCropFrame));
//    BOOL isImageViewSizeSame = CGRectEqualToRect(self.imageVi.superview.frame, self.imageOriginFrame);
    BOOL isImageViewSizeSame = (fabs(CGRectGetWidth(self.imageVi.superview.frame) - CGRectGetWidth(self.imageOriginFrame)) < 0.05 &&
    fabs(CGRectGetHeight(self.imageVi.superview.frame) - CGRectGetHeight(self.imageOriginFrame)) < 0.05);
    BOOL isDirectionUp = (_rotationDirection == CXCropViewRotationDirectionUp);
    BOOL isZoomScaleOriginal = (self.scroll.zoomScale == self.initialScrollZoomScale);
    BOOL isCropCaseOriginal = CGRectEqualToRect(self.currentCropFrame, self.originCropFrame);
    if (isImageViewSizeSame && isDirectionUp && isZoomScaleOriginal && isCropCaseOriginal) {
        [self routerWithEventName:kCXCropCase_IsCanRecovery DataInfo:@{@"isCanRecovery" : @(NO)}];
    }else {
        [self routerWithEventName:kCXCropCase_IsCanRecovery DataInfo:@{@"isCanRecovery" : @(YES)}];
    }
}

- (void)dealloc
{
    NSLog(@"123");
}

#pragma mark ********* Getter *********
- (UIImageView *)leftTopIgv {
    if (!_leftTopIgv) {
        _leftTopIgv = [UIImageView new];
        _leftTopIgv.image = [UIImage imageNamed:@"corner_left_top"];
        _leftTopIgv.userInteractionEnabled = YES;
        _leftTopIgv.tag = CXCropCornerTypeLeftTop;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(cropCaseMoved:)];
        [_leftTopIgv addGestureRecognizer:pan];
    }
    return _leftTopIgv;
}

- (UIImageView *)rightTopIgv {
    if (!_rightTopIgv) {
        _rightTopIgv = [UIImageView new];
        _rightTopIgv.image = [UIImage imageNamed:@"corner_right_top"];
        _rightTopIgv.tag = CXCropCornerTypeRightTop;
        _rightTopIgv.userInteractionEnabled = YES;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(cropCaseMoved:)];
        [_rightTopIgv addGestureRecognizer:pan];
    }
    return _rightTopIgv;
}

- (UIImageView *)leftBottomIgv {
    if (!_leftBottomIgv) {
        _leftBottomIgv = [UIImageView new];
        _leftBottomIgv.image = [UIImage imageNamed:@"corner_left_bottom"];
        _leftBottomIgv.tag = CXCropCornerTypeLeftBottom;
        _leftBottomIgv.userInteractionEnabled = YES;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(cropCaseMoved:)];
        [_leftBottomIgv addGestureRecognizer:pan];
    }
    return _leftBottomIgv;
}

- (UIImageView *)rightBottomIgv {
    if (!_rightBottomIgv) {
        _rightBottomIgv = [UIImageView new];
        _rightBottomIgv.image = [UIImage imageNamed:@"corner_right_bottom"];
        _rightBottomIgv.tag = CXCropCornerTypeRightBottom;
        _rightBottomIgv.userInteractionEnabled = YES;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(cropCaseMoved:)];
        [_rightBottomIgv addGestureRecognizer:pan];
    }
    return _rightBottomIgv;
}

- (UIView *)topLine {
    if (!_topLine) {
        _topLine = [UIView new];
        _topLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 1);
    }
    return _topLine;
}

- (UIView *)firstHorizontalLine {
    if (!_firstHorizontalLine) {
        _firstHorizontalLine = [UIView new];
        _firstHorizontalLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 0.4);
    }
    return _firstHorizontalLine;
}

- (UIView *)secondHorizontalLine {
    if (!_secondHorizontalLine) {
        _secondHorizontalLine = [UIView new];
        _secondHorizontalLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 0.4);
    }
    return _secondHorizontalLine;
}

- (UIView *)bottomLine {
    if (!_bottomLine) {
        _bottomLine = [UIView new];
        _bottomLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 1);
    }
    return _bottomLine;
}

- (UIView *)leftLine {
    if (!_leftLine) {
        _leftLine = [UIView new];
        _leftLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 1);
    }
    return _leftLine;
}

- (UIView *)firstVerticalLine {
    if (!_firstVerticalLine) {
        _firstVerticalLine = [UIView new];
        _firstVerticalLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 0.4);
    }
    return _firstVerticalLine;
}

- (UIView *)secondVerticalLine {
    if (!_secondVerticalLine) {
        _secondVerticalLine = [UIView new];
        _secondVerticalLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 0.4);
    }
    return _secondVerticalLine;
}

- (UIView *)rightLine {
    if (!_rightLine) {
        _rightLine = [UIView new];
        _rightLine.backgroundColor = CXUIColorFromRGBA(0xFFFFFF, 1);
    }
    return _rightLine;
}

@end
