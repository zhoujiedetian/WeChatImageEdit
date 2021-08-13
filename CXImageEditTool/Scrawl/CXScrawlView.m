//
//  CXScrawlView.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import "CXScrawlView.h"
#import "CXScrawlInfo.h"
@interface CXScrawlView()
//涂鸦线段集合
@property(nonatomic, strong) NSMutableArray *lineInfos;
//滑动手势
@property(nonatomic, strong) UIPanGestureRecognizer *pan;
@end

@implementation CXScrawlView
- (instancetype)init {
    self = [super init];
    if (self) {
        self.lineInfos = [NSMutableArray array];
        self.currentDrawColor = [UIColor redColor];
        self.currentDrawWidth = 4;
        self.backgroundColor = [UIColor clearColor];
        
        _pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panScrawl:)];
        [self addGestureRecognizer:_pan];
    }
    return self;
}


#pragma mark ********* PublicMethod *********
- (BOOL)canRecall {
    return (self.lineInfos.count > 0);
}

- (void)recall {
    if (![self canRecall]) {
        return;
    }
    [self.lineInfos removeLastObject];
    [self setNeedsDisplay];
}

- (void)clear {
    [self.lineInfos removeAllObjects];
    [self setNeedsDisplay];
}

- (void)panScrawl:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        CGPoint startPoint = [pan locationInView:self];
        CXScrawlInfo *lineInfo = [CXScrawlInfo new];
        lineInfo.lineColor = _currentDrawColor;
        lineInfo.lineWidth = _currentDrawWidth;
        [lineInfo.linePoints addObject:[NSValue valueWithCGPoint:startPoint]];
        [_lineInfos addObject:lineInfo];
        [self setNeedsDisplay];
        
        if (_delegate && [_delegate respondsToSelector:@selector(scrawlBegan:)]) {
            [_delegate scrawlBegan:self];
        }
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint endPoint = [pan locationInView:self];
        CXScrawlInfo *lineInfo = _lineInfos.lastObject;
        [lineInfo.linePoints addObject:[NSValue valueWithCGPoint:endPoint]];
        [self setNeedsDisplay];
    }else if (pan.state == UIGestureRecognizerStateEnded ||
              pan.state == UIGestureRecognizerStateCancelled) {
        if (_delegate && [_delegate respondsToSelector:@selector(scrawlDidEnd:)]) {
            [_delegate scrawlDidEnd:self];
        }
    }else {

    }
}


#pragma mark ********* Draw *********
- (void)drawRect:(CGRect)rect {
    if (_lineInfos.count == 0) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    for (CXScrawlInfo *lineInfo in _lineInfos) {
        CGContextBeginPath(context);
        CGPoint startPoint = [lineInfo.linePoints.firstObject CGPointValue];
        CGContextMoveToPoint(context, startPoint.x, startPoint.y);
        if (lineInfo.linePoints.count > 1) {
            for (int i = 1; i < lineInfo.linePoints.count; i++) {
                CGPoint endPoint = [lineInfo.linePoints[i] CGPointValue];
                CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            }
        }else {
            CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
        }
        CGContextSetStrokeColorWithColor(context, lineInfo.lineColor.CGColor);
        CGContextSetLineWidth(context, lineInfo.lineWidth);
        CGContextStrokePath(context);
    }
}
@end
