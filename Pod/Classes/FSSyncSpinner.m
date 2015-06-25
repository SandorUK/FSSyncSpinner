//
//  FSSyncSpinner.m
//  Pods
//
//  Created by Wenchao Ding on 3/8/15.
//
//

#import "FSSyncSpinner.h"

#define kRotationPeriod 0.5
#define kDisappearDuration 0.3

#define kSuccessColor [UIColor colorWithRed:42/255.0 green:172/255.0 blue:0/255.0 alpha:1.0]
#define kFailureColor [UIColor colorWithRed:42/255.0 green:172/255.0 blue:0/255.0 alpha:1.0]
#define kSyncColor [UIColor colorWithRed:35/255.0 green:118/255.0 blue:237/255.0 alpha:1.0]

@interface FSSyncSpinnerRing : CALayer

@property (strong, nonatomic) CAShapeLayer *arcLayer;
@property (strong, nonatomic) CAShapeLayer *arrowLayer;

@end

@implementation FSSyncSpinnerRing

- (instancetype)initWith:(BOOL)arrows andThickness:(CGFloat)thickness andColor:(UIColor *)color
{
    self = [super init];
    if (self) {
        // arc
        self.backgroundColor = [[UIColor clearColor] CGColor];
        self.arcLayer = [CAShapeLayer layer];
        self.arcLayer.backgroundColor = [[UIColor clearColor] CGColor];
        self.arcLayer.fillColor = [[UIColor clearColor] CGColor];
        self.arcLayer.strokeColor = color ? color.CGColor : kSyncColor.CGColor;
        self.arcLayer.lineWidth = thickness;
        self.arcLayer.lineCap = kCALineCapRound;
        [self addSublayer:self.arcLayer];
        
        if (arrows) {
            // arrow
            self.arrowLayer = [CAShapeLayer layer];
            self.arrowLayer.fillColor = self.arcLayer.strokeColor;
            self.arrowLayer.strokeColor = [[UIColor clearColor] CGColor];
            
            [self addSublayer:self.arrowLayer];
        }
    }
    return self;
}

- (void)layoutSublayers
{
    [super layoutSublayers];
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        return;
    }
    CGSize size = self.bounds.size;
    //_arcLayer.lineWidth = size.width * 0.1;
    _arcLayer.frame = self.bounds;
    UIBezierPath *arcPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    _arcLayer.path = arcPath.CGPath;
    _arcLayer.strokeStart = 0.58;
    
    // arrow
    CGFloat arrowHeigth = _arcLayer.lineWidth * 1.5;
    CGFloat arrowWidth = arrowHeigth * 1.8;
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:CGPointMake(0, 0)];
    [arrowPath addLineToPoint:CGPointMake(arrowWidth, 0)];
    [arrowPath addLineToPoint:CGPointMake(arrowWidth * 0.5, arrowHeigth)];
    [arrowPath closePath];
    CGRect arrowFrame = CGRectMake(size.width - arrowWidth * 0.5, size.height * 0.5, arrowWidth, arrowHeigth);
    _arrowLayer.frame = arrowFrame;
    _arrowLayer.path = arrowPath.CGPath;
    
}

@end

@interface FSSyncSpinner ()

@property (strong, nonatomic) FSSyncSpinnerRing *topRing;
@property (strong, nonatomic) FSSyncSpinnerRing *bottomRing;
@property (strong, nonatomic) CALayer *containerLayer;
@property (strong, nonatomic) CAShapeLayer *checkmarkLayer;
@property (strong, nonatomic) CAShapeLayer *crossmarkLayer;

@property (assign, nonatomic) CGFloat finishSpeed;
@property (assign, nonatomic) BOOL needFinish;
@property (assign, nonatomic) BOOL isSuccessful;

- (void)initialize;
- (void)initLayers;
- (void)reset;
- (void)performCompletionAtProperTime;
- (void)performCompletion;
- (void)performInverseEclipse;
- (void)showCheckmark;
- (void)hideIfNecessary;

@end

@implementation FSSyncSpinner

#pragma mark - Life Cycle && initialize

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    [self initLayers];
    _hidesWhenFinished = YES;
    self.backgroundColor = [UIColor clearColor];
}

- (void)initLayers
{
    _containerLayer = [CALayer layer];
    _containerLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _containerLayer.frame = self.layer.bounds;
    [self.layer addSublayer:_containerLayer];
    
    _topRing = [[FSSyncSpinnerRing alloc] initWith:NO andThickness:3.0 andColor:self.colorOfProgress];
    _topRing.frame = _containerLayer.bounds;
    _topRing.transform = CATransform3DMakeRotation(-M_PI*0.2, 0, 0, 1.0);
    [_containerLayer addSublayer:_topRing];
    
    _bottomRing = [[FSSyncSpinnerRing alloc] initWith:NO andThickness:3.0 andColor:self.colorOfProgress];
    _bottomRing.frame = _containerLayer.bounds;
    _bottomRing.transform = CATransform3DMakeRotation(M_PI*0.8, 0, 0, 1.0);
    [_containerLayer addSublayer:_bottomRing];
}

- (void)reset
{
    [_topRing removeFromSuperlayer];
    [_bottomRing removeFromSuperlayer];
    [_checkmarkLayer removeFromSuperlayer];
    [_containerLayer removeFromSuperlayer];
    _needFinish = NO;
    _finishSpeed = 0;
    [self initLayers];
}

#pragma mark - Public

- (void)startAnimating
{
    [self reset];
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.duration = kRotationPeriod;
    rotation.fromValue = @0;
    rotation.toValue = @(2*M_PI);
    rotation.repeatCount = HUGE_VAL;
    rotation.autoreverses = NO;
    rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [_containerLayer addAnimation:rotation forKey:@"rotation"];
    
    CABasicAnimation *flex = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    flex.duration = kRotationPeriod * 0.5;
    flex.autoreverses = YES;
    flex.fromValue = @0.58;
    flex.toValue = @0.8;
    flex.repeatCount = HUGE_VAL;
    flex.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.topRing.arcLayer addAnimation:flex forKey:@"flex"];
    [self.bottomRing.arcLayer addAnimation:flex forKey:@"flex"];
}

- (void)finishWithSuccess:(BOOL)success
{
    if (!_needFinish) {
        _needFinish = YES;
        _isSuccessful = success;
        [self performCompletionAtProperTime];
    }
}

#pragma mark - Private

- (void)performCompletionAtProperTime
{
    if ([[self.topRing.arcLayer.presentationLayer valueForKeyPath:@"strokeStart"] compare:@0.6] == NSOrderedAscending) {
        [self performCompletion];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.005 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performCompletionAtProperTime];
        });
    }
}

- (void)performCompletion
{
    CGFloat currentStrokeStart = [[self.topRing.arcLayer.presentationLayer valueForKeyPath:@"strokeStart"] doubleValue];
    self.finishSpeed = [_containerLayer.presentationLayer speed];
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        UIColor *color = [UIColor clearColor];
        
        if (_isSuccessful) {
            if (self.colorOfSuccess) {
                color = self.colorOfSuccess;
            }
            else{
                color = kSuccessColor;
            }
        }
        else{
            if (self.colorOfFailure) {
                color = self.colorOfFailure;
            }
            else{
                color = kFailureColor;
            }
        }
        
        self.topRing.arcLayer.strokeColor = color.CGColor;
        self.bottomRing.arcLayer.strokeColor = color.CGColor;
        self.topRing.arrowLayer.fillColor = color.CGColor;
        self.bottomRing.arrowLayer.fillColor = color.CGColor;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performInverseEclipse];
        });
    }];
    
    CGFloat currentSpeed = [self.topRing.arcLayer.presentationLayer speed];
    [self.topRing.arcLayer removeAllAnimations];
    [self.bottomRing.arcLayer removeAllAnimations];
    CABasicAnimation *recoverAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    recoverAnimation.fromValue = @(currentStrokeStart);
    recoverAnimation.toValue = @0.5;
    recoverAnimation.speed = currentSpeed;
    recoverAnimation.removedOnCompletion = NO;
    recoverAnimation.fillMode = kCAFillModeForwards;
    [self.topRing.arcLayer addAnimation:recoverAnimation forKey:@"recover"];
    [self.bottomRing.arcLayer addAnimation:recoverAnimation forKey:@"recover"];
    
    [CATransaction commit];
}

- (void)performInverseEclipse
{
    // Add a white circle layer to perform invert eclipse
    CAShapeLayer *whiteLayer = [CAShapeLayer layer];
    whiteLayer.frame = self.bounds;
    whiteLayer.fillColor = [[UIColor whiteColor] CGColor];
    whiteLayer.strokeColor = [[UIColor clearColor] CGColor];
    whiteLayer.lineWidth = self.topRing.arcLayer.lineWidth;
    whiteLayer.fillColor = [[UIColor whiteColor] CGColor];
    whiteLayer.path = self.topRing.arcLayer.path;
    [_containerLayer addSublayer:whiteLayer];
    CAShapeLayer *arcLayer = self.topRing.arcLayer;
    arcLayer.fillColor  = arcLayer.strokeColor;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [whiteLayer removeFromSuperlayer];
    }];
    // Invert eclipse
    CABasicAnimation *zoomOut = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomOut.fromValue = @1.0;
    zoomOut.toValue = @0;
    zoomOut.duration = 0.2;
    zoomOut.removedOnCompletion = NO;
    zoomOut.fillMode = kCAFillModeForwards;
    [whiteLayer addAnimation:zoomOut forKey:@"zoomOut"];
    
    // Disappear arrow
    CGFloat duration = 0.12;
    CAAnimationGroup *arrowDisappear = [CAAnimationGroup animation];
    arrowDisappear.removedOnCompletion = NO;
    arrowDisappear.fillMode = kCAFillModeForwards;
    arrowDisappear.duration = duration;
    CABasicAnimation *arrowZoomOut = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    arrowZoomOut.duration = duration;
    arrowZoomOut.fromValue = @1;
    arrowZoomOut.toValue = @0;
    arrowZoomOut.removedOnCompletion = NO;
    arrowZoomOut.fillMode = kCAFillModeForwards;
    arrowZoomOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CABasicAnimation *arrowDissove = [CABasicAnimation animationWithKeyPath:@"opacity"];
    arrowDissove.duration = duration;
    arrowDissove.fromValue = @1;
    arrowDissove.toValue = @0;
    arrowDissove.removedOnCompletion = NO;
    arrowDissove.fillMode = kCAFillModeForwards;
    arrowDisappear.animations = @[arrowZoomOut,arrowDissove];
    [self.topRing.arrowLayer addAnimation:arrowDisappear forKey:@"arrowDisappear"];
    [self.bottomRing.arrowLayer addAnimation:arrowDisappear forKey:@"arrowDisappear"];
    [CATransaction commit];
    
    if (_isSuccessful) {
        [self showCheckmark];
    }
    else{
        [self showCheckmark];
    }
    
}

- (CAShapeLayer *)shapeLayerWithPath:(UIBezierPath *)path inFrame:(CGRect)frame{
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.backgroundColor = [[UIColor clearColor] CGColor];
    layer.fillColor = [[UIColor clearColor] CGColor];
    layer.strokeColor = [[UIColor whiteColor] CGColor];
    layer.lineWidth = frame.size.width * 0.125;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    layer.frame = frame;
    layer.path = path.CGPath;
    
    return layer;
}

- (UIBezierPath *)checkmarkPathWithSize:(CGSize)size{
    CGPoint startPoint = CGPointMake(size.width * 0.1, size.height/5.0+1);
    CGPoint midPoint = CGPointMake(size.width * 0.43, size.height - size.height * 0.1);
    CGPoint endPoint = CGPointMake(size.width - size.width * 0.1 * 2, 1);
    UIBezierPath *checkmarkPath = [UIBezierPath bezierPath];
    [checkmarkPath moveToPoint:startPoint];
    [checkmarkPath addLineToPoint:midPoint];
    [checkmarkPath addLineToPoint:endPoint];
    
    return checkmarkPath;
}

- (UIBezierPath *)crossmarkPathWithSize:(CGSize)size{
    CGPoint startPoint1 = CGPointMake(size.width * 0.18, size.height * 0.5);
    CGPoint endPoint1 = CGPointMake(size.width - size.width * 0.18, size.height * 0.5);
    
    CGFloat length = size.width - size.width * 0.18 * 2;
    
    CGPoint startPoint2 = CGPointMake(size.width * 0.5, size.height / 2 - length / 2);
    CGPoint endPoint2 = CGPointMake(size.width * 0.5, size.height/ 2 + length / 2);
    
    UIBezierPath *checkmarkPath = [UIBezierPath bezierPath];
    [checkmarkPath moveToPoint:startPoint1];
    [checkmarkPath addLineToPoint:endPoint1];
    [checkmarkPath moveToPoint:startPoint2];
    [checkmarkPath addLineToPoint:endPoint2];
    
    return checkmarkPath;
}

- (void)showCheckmark
{
    CGFloat bounce = 0.23;
    CGFloat rebounce = 0.03;
    CGFloat currentRotationg = [[_containerLayer.presentationLayer valueForKeyPath:@"transform.rotation.z"] doubleValue];
    [_containerLayer removeAllAnimations];
    _containerLayer.transform = CATransform3DMakeRotation(currentRotationg, 0, 0, 1);
    CGRect frame = CGRectMake(self.topRing.arcLayer.lineWidth * 2,
                              self.topRing.arcLayer.lineWidth * 3.2,
                              self.bounds.size.width - self.topRing.arcLayer.lineWidth * 4,
                              self.bounds.size.height - self.topRing.arcLayer.lineWidth * 6.4);
    
    CGSize size = frame.size;
    
    if (_isSuccessful) {
        UIBezierPath *checkmarkPath = [self checkmarkPathWithSize:size];
        CAShapeLayer *checkmarkLayer = [self shapeLayerWithPath:checkmarkPath inFrame:frame];
        checkmarkLayer.transform = CATransform3DMakeRotation(-currentRotationg-bounce*M_PI, 0, 0, 1);
        [_containerLayer addSublayer:checkmarkLayer];
        self.checkmarkLayer = checkmarkLayer;
    }
    else{
        UIBezierPath *crossmakrPath = [self crossmarkPathWithSize:size];
        CAShapeLayer *crossMarkLayer = [self shapeLayerWithPath:crossmakrPath inFrame:frame];
        crossMarkLayer.transform = CATransform3DMakeRotation(-currentRotationg-bounce*M_PI, 0, 0, 1);
        [_containerLayer addSublayer:crossMarkLayer];
        self.checkmarkLayer = crossMarkLayer;
    }
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [self hideIfNecessary];
        }];
        CABasicAnimation *rebound = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rebound.speed = self.finishSpeed;
        rebound.fromValue = @(currentRotationg+(bounce+rebounce)*M_PI);
        rebound.toValue = @(currentRotationg+bounce*M_PI);
        rebound.removedOnCompletion = NO;
        rebound.fillMode = kCAFillModeForwards;
        [_containerLayer addAnimation:rebound forKey:@"rebound"];
        [CATransaction commit];
    }];
    
    CABasicAnimation *inertia = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    inertia.beginTime = CACurrentMediaTime() + 0.12;
    inertia.speed = self.finishSpeed * 0.75;
    inertia.fromValue = @(currentRotationg);
    inertia.toValue = @(currentRotationg+(bounce+rebounce)*M_PI);
    inertia.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    inertia.removedOnCompletion = NO;
    inertia.fillMode = kCAFillModeForwards;
    [_containerLayer addAnimation:inertia forKey:@"inertia"];
    
    [CATransaction commit];
}

- (void)hideIfNecessary
{
    if (_hidesWhenFinished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CABasicAnimation *hideAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            hideAnimation.duration = 0.3;
            hideAnimation.fromValue = @1;
            hideAnimation.toValue = @0;
            hideAnimation.removedOnCompletion = NO;
            hideAnimation.fillMode = kCAFillModeForwards;
            [_containerLayer addAnimation:hideAnimation forKey:@"hideAnimation"];
        });
    }
}

@end
