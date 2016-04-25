//
//  HCWPhotoBrowser.m
//  Example
//
//  Created by HCW on 16/4/25.
//  Copyright © 2016年 HCW. All rights reserved.
//

#define kPadding 20

#import "HCWPhotoBrowser.h"
#import "HCWCircleProgressView.h"
#import "UIImageView+WebCache.h"

@interface HCWPhotoModel () <NSCopying>
@property (nonatomic, readonly) UIImage *thumbImage;
@property (nonatomic, readonly) BOOL thumbClippedToTop;
@end

@implementation HCWPhotoModel

- (UIImage *)thumbImage {
    if ([_thumbView respondsToSelector:@selector(image)]) {
        return ((UIImageView *)_thumbView).image;
    }
    return nil;
}

- (BOOL)thumbClippedToTop {
    if (_thumbView) {
        if (_thumbView.layer.contentsRect.size.height < 1) {
            return YES;
        }
    }
    return NO;
}

- (id)copyWithZone:(NSZone *)zone {
    HCWPhotoModel *model = [self.class new];
    return model;
}

@end


@interface HCWPhotoCell : UIScrollView <UIScrollViewDelegate>
@property (nonatomic, strong) UIView *imageContainerView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, assign) BOOL showProgress;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) HCWCircleProgressView *progressView;
@property (nonatomic, strong) HCWPhotoModel *photoModel;
@property (nonatomic, assign) BOOL itemDidLoad;
- (void)resizeSubviewSize;
@end

@implementation HCWPhotoCell

- (instancetype)init {
    self = super.init;
    if (!self) return nil;
    self.delegate = self;
    self.bouncesZoom = YES;
    self.maximumZoomScale = 3;
    self.multipleTouchEnabled = YES;
    self.alwaysBounceVertical = NO;
    self.showsVerticalScrollIndicator = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.frame = [UIScreen mainScreen].bounds;
    
    _imageContainerView = [UIView new];
    _imageContainerView.clipsToBounds = YES;
    [self addSubview:_imageContainerView];
    
    _imageView = [UIImageView new];
    _imageView.clipsToBounds = YES;
    _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
    [_imageContainerView addSubview:_imageView];
    
    _progressView = [[HCWCircleProgressView alloc] initWithFrame:(CGRect){0, 0, 40,40}];
    _progressView.isCircle = YES;
    [self addSubview:_progressView];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _progressView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (void)setPhotoModel:(HCWPhotoModel *)photoModel
{
    if (_photoModel == photoModel) return;
    _photoModel = photoModel;
    _itemDidLoad = NO;
    
    [self setZoomScale:1.0 animated:NO];
    self.maximumZoomScale = 1;
    
    if (!_photoModel) {
        _imageView.image = nil;
        return;
    }
    
    _progressView.hidden = NO;
    [_imageView sd_setImageWithURL:photoModel.largeImageURL placeholderImage:photoModel.thumbImage options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
        CGFloat progress = receivedSize / (float)expectedSize;
        progress = progress < 0.01 ? 0.01 : progress > 1 ? 1 : progress;
        if (isnan(progress)) progress = 0;
        
        _progressView.hidden = NO;
        _progressView.progressValue = progress;
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        _progressView.hidden = YES;
        
        self.maximumZoomScale = 3;
        self.itemDidLoad = YES;
        self.imageView.image = image;
        [self resizeSubviewSize];
    }];
    
    [self resizeSubviewSize];
}

- (void)resizeSubviewSize
{
    _imageContainerView.frame = (CGRect){0, 0, self.bounds.size.width, _imageContainerView.bounds.size.height};
    
    UIImage *image = _imageView.image;
    
    // 图片比例大于cell比例
    if (image.size.height / image.size.width > self.bounds.size.height / self.bounds.size.width) {
        _imageContainerView.frame = (CGRect){0, 0, self.bounds.size.width, floor(image.size.height / (image.size.width / self.bounds.size.width))};
    }
    // 图片比例小于cell比例
    else {
        CGFloat height = image.size.height / image.size.width * self.bounds.size.width;
        if (height < 1 || isnan(height)) height = self.bounds.size.height;
        height = floor(height);
        _imageContainerView.frame = (CGRect){_imageContainerView.frame.origin.x, (self.bounds.size.height - height)/2.0, _imageContainerView.bounds.size.width, height};
    }
    if (_imageContainerView.bounds.size.height > self.bounds.size.height && _imageContainerView.bounds.size.height - self.bounds.size.height <= 1) {
        _imageContainerView.frame = (CGRect){_imageContainerView.frame.origin.x, _imageContainerView.frame.origin.y, _imageContainerView.bounds.size.width, self.bounds.size.height};
    }
    
    self.contentSize = CGSizeMake(self.bounds.size.width, MAX(_imageContainerView.bounds.size.height, self.bounds.size.height));
    [self scrollRectToVisible:self.bounds animated:NO];
    
    if (_imageContainerView.bounds.size.height <= self.bounds.size.height) {
        self.alwaysBounceVertical = NO;
    } else {
        self.alwaysBounceVertical = YES;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageView.frame = _imageContainerView.bounds;
    [CATransaction commit];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _imageContainerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    UIView *subView = _imageContainerView;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

@end


@interface HCWPhotoBrowser () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView *fromView;
@property (nonatomic, weak) UIView *toContainerView;

@property (nonatomic, strong) UIImage *snapshotImage;
@property (nonatomic, strong) UIImage *snapshorImageHideFromView;

@property (nonatomic, strong) UIImageView *background;
@property (nonatomic, strong) UIImageView *blurBackground;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *cells;
@property (nonatomic, strong) UIPageControl *pager;
@property (nonatomic, assign) CGFloat pagerCurrentPage;
@property (nonatomic, assign) BOOL fromNavigationBarHidden;

@property (nonatomic, assign) NSInteger fromItemIndex;
@property (nonatomic, assign) BOOL isPresented;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint panGestureBeginPoint;

@end

@implementation HCWPhotoBrowser

- (instancetype)initWithPhotoModels:(NSArray <HCWPhotoModel *> *)photoModels {
    self = [super init];
    if (photoModels.count == 0) return nil;
    _photoModels = photoModels.copy;
    _blurEffectBackground = YES;
    
    self.backgroundColor = [UIColor clearColor];
    self.frame = [UIScreen mainScreen].bounds;
    self.clipsToBounds = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tap2.delegate = self;
    tap2.numberOfTapsRequired = 2;
    [tap requireGestureRecognizerToFail: tap2];
    [self addGestureRecognizer:tap2];
    
    _cells = @[].mutableCopy;
    
    _background = UIImageView.new;
    _background.frame = self.bounds;
    _background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _blurBackground = UIImageView.new;
    _blurBackground.frame = self.bounds;
    _blurBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _contentView = UIView.new;
    _contentView.frame = self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _scrollView = UIScrollView.new;
    _scrollView.frame = CGRectMake(-kPadding / 2, 0, self.bounds.size.width + kPadding, self.bounds.size.height);
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.alwaysBounceHorizontal = _photoModels.count > 1;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.delaysContentTouches = NO;
    _scrollView.canCancelContentTouches = YES;
    
    _pager = [[UIPageControl alloc] init];
    _pager.hidesForSinglePage = YES;
    _pager.userInteractionEnabled = NO;
    _pager.frame = (CGRect){0, 0, self.bounds.size.width - 36, 10};
    _pager.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height - 18);
    _pager.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    [self addSubview:_background];
    [self addSubview:_blurBackground];
    [self addSubview:_contentView];
    [_contentView addSubview:_scrollView];
    [_contentView addSubview:_pager];
    
    return self;
}

- (void)presentFromImageView:(UIView *)fromView
                 toContainer:(UIView *)toContainer
                    animated:(BOOL)animated
                  completion:(void (^)(void))completion {
    if (!toContainer) return;
    
    _fromView = fromView;
    _toContainerView = toContainer;
    
    NSInteger page = -1;
    for (NSUInteger i = 0; i < self.photoModels.count; i++) {
        if (fromView == ((HCWPhotoModel *)self.photoModels[i]).thumbView) {
            page = (int)i;
            break;
        }
    }
    if (page == -1) page = 0;
    _fromItemIndex = page;
    
    _snapshotImage = [self snapshotImageAfterScreenUpdates:NO];
    BOOL fromViewHidden = fromView.hidden;
    fromView.hidden = YES;
    _snapshorImageHideFromView = [self snapshotImage];
    fromView.hidden = fromViewHidden;
    
    _background.image = _snapshorImageHideFromView;
    if (_blurEffectBackground) {
//        _blurBackground.image = [_snapshorImageHideFromView imageByBlurDark]; //Same to UIBlurEffectStyleDark
//        _blurBackground.image = [self imageWithColor:[UIColor colorWithWhite:0 alpha:.5] size:CGSizeMake(1, 1)];
        _blurBackground.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    } else {
        _blurBackground.image = [self imageWithColor:[UIColor colorWithWhite:0 alpha:.5] size:CGSizeMake(1, 1)];
    }
    
    self.frame = _toContainerView.bounds;
    self.blurBackground.alpha = 0;
    self.pager.alpha = 0;
    self.pager.numberOfPages = self.photoModels.count;
    self.pager.currentPage = page;
    [_toContainerView addSubview:self];
    
    _scrollView.contentSize = CGSizeMake(_scrollView.bounds.size.width * self.photoModels.count, _scrollView.bounds.size.height);
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.bounds.size.width * _pager.currentPage, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height) animated:NO];
    [self scrollViewDidScroll:_scrollView];
    
    [UIView setAnimationsEnabled:YES];
    _fromNavigationBarHidden = [UIApplication sharedApplication].statusBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
    
    
    HCWPhotoCell *cell = [self cellForPage:self.currentPage];
    HCWPhotoModel *model = _photoModels[self.currentPage];
    
    cell.photoModel = model;
    if (!cell.photoModel) {
        cell.imageView.image = model.thumbImage;
        [cell resizeSubviewSize];
    }
    
    if (model.thumbClippedToTop) {
        CGRect fromFrame = [_fromView convertRect:_fromView.bounds toView:cell];
        CGRect originFrame = cell.imageContainerView.frame;
        CGFloat scale = fromFrame.size.width / cell.imageContainerView.bounds.size.width;
        
        cell.imageContainerView.frame = (CGRect){0, 0, cell.imageContainerView.frame.size.width,fromFrame.size.height / scale};
        cell.imageContainerView.center = (CGPoint){CGRectGetMidX(fromFrame), CGRectGetMidY(fromFrame)};
        [cell.imageContainerView.layer setValue:@(scale) forKey:@"transform.scale"];
        
        float oneTime = animated ? 0.25 : 0;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            _blurBackground.alpha = 1;
        }completion:NULL];
        
        _scrollView.userInteractionEnabled = NO;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [cell.imageContainerView.layer setValue:@(1) forKey:@"transform.scale"];
            cell.imageContainerView.frame = originFrame;
            _pager.alpha = 1;
        }completion:^(BOOL finished) {
            _isPresented = YES;
            [self scrollViewDidScroll:_scrollView];
            _scrollView.userInteractionEnabled = YES;
            [self hidePager];
            if (completion) completion();
        }];
        
    } else {
        CGRect fromFrame = [_fromView convertRect:_fromView.bounds toView:cell.imageContainerView];
        
        cell.imageContainerView.clipsToBounds = NO;
        cell.imageView.frame = fromFrame;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        float oneTime = animated ? 0.18 : 0;
        [UIView animateWithDuration:oneTime*2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            _blurBackground.alpha = 1;
        }completion:NULL];
        
        _scrollView.userInteractionEnabled = NO;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.imageView.frame = cell.imageContainerView.bounds;
            [cell.imageView.layer setValue:@(1.01) forKey:@"transform.scale"];
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
                [cell.imageView.layer setValue:@(1.0) forKey:@"transform.scale"];
                _pager.alpha = 1;
            }completion:^(BOOL finished) {
                cell.imageContainerView.clipsToBounds = YES;
                _isPresented = YES;
                [self scrollViewDidScroll:_scrollView];
                _scrollView.userInteractionEnabled = YES;
                [self hidePager];
                if (completion) completion();
            }];
        }];
    }
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [UIView setAnimationsEnabled:YES];
    
    [[UIApplication sharedApplication] setStatusBarHidden:_fromNavigationBarHidden withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
    NSInteger currentPage = self.currentPage;
    HCWPhotoCell *cell = [self cellForPage:currentPage];
    HCWPhotoModel *model = _photoModels[currentPage];
    
    UIView *fromView = nil;
    if (_fromItemIndex == currentPage) {
        fromView = _fromView;
    } else {
        fromView = model.thumbView;
    }
    
//    [[SDWebImageManager sharedManager] cancelAll];
    
    _isPresented = NO;
    BOOL isFromImageClipped = fromView.layer.contentsRect.size.height < 1;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (isFromImageClipped) {
        CGRect frame = cell.imageContainerView.frame;
        cell.imageContainerView.layer.anchorPoint = CGPointMake(0.5, 0);
        cell.imageContainerView.frame = frame;
    }
    cell.progressView.hidden = YES;
    [CATransaction commit];
    
    if (fromView == nil) {
        self.background.image = _snapshotImage;
        [UIView animateWithDuration:animated ? 0.25 : 0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 0.0;
            [self.scrollView.layer setValue:@(0.95) forKey:@"transform.scale"];
            self.scrollView.alpha = 0;
            self.pager.alpha = 0;
            self.blurBackground.alpha = 0;
        }completion:^(BOOL finished) {
            [self.scrollView.layer setValue:@(1.0) forKey:@"transform.scale"];
            [self removeFromSuperview];
//    [[SDWebImageManager sharedManager] cancelAll];
            if (completion) completion();
        }];
        return;
    }
    
    if (_fromItemIndex != currentPage) {
        _background.image = _snapshotImage;
//        [_background.layer addFadeAnimationWithDuration:0.25 curve:UIViewAnimationCurveEaseOut];
    } else {
        _background.image = _snapshorImageHideFromView;
    }
    
    
    if (isFromImageClipped) {
        [self scrollToTopAnimated:NO scroll:cell];
    }
    
    [UIView animateWithDuration:animated ? 0.2 : 0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
        _pager.alpha = 0.0;
        _blurBackground.alpha = 0.0;
        if (isFromImageClipped) {
            
            CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell];
            CGFloat scale = fromFrame.size.width / cell.imageContainerView.bounds.size.width * cell.zoomScale;
            CGFloat height = fromFrame.size.height / fromFrame.size.width * cell.imageContainerView.bounds.size.width;
            if (isnan(height)) height = cell.imageContainerView.bounds.size.height;
            
            cell.imageContainerView.frame = (CGRect){cell.imageContainerView.frame.origin.x, cell.imageContainerView.frame.origin.y, cell.imageContainerView.frame.size.width, height};
            cell.imageContainerView.center = CGPointMake(CGRectGetMidX(fromFrame), CGRectGetMinY(fromFrame));
            [cell.imageContainerView.layer setValue:@(scale) forKey:@"transform.scale"];
            
        } else {
            CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell.imageContainerView];
            cell.imageContainerView.clipsToBounds = NO;
            cell.imageView.contentMode = fromView.contentMode;
            cell.imageView.frame = fromFrame;
        }
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:animated ? 0.15 : 0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            cell.imageContainerView.layer.anchorPoint = CGPointMake(0.5, 0.5);
            [self removeFromSuperview];
            if (completion) completion();
        }];
    }];
    
    
}

- (void)dismiss {
    [self dismissAnimated:YES completion:nil];
}

- (void)doubleTap:(UITapGestureRecognizer *)g {
    if (!_isPresented) return;
    HCWPhotoCell *tile = [self cellForPage:self.currentPage];
    if (tile) {
        if (tile.zoomScale > 1) {
            [tile setZoomScale:1 animated:YES];
        } else {
            CGPoint touchPoint = [g locationInView:tile.imageView];
            CGFloat newZoomScale = tile.maximumZoomScale;
            CGFloat xsize = self.bounds.size.width / newZoomScale;
            CGFloat ysize = self.bounds.size.height / newZoomScale;
            [tile zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        }
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCellsForReuse];
    
    CGFloat floatPage = _scrollView.contentOffset.x / _scrollView.bounds.size.width;
    NSInteger page = _scrollView.contentOffset.x / _scrollView.bounds.size.width + 0.5;
    
    for (NSInteger i = page - 1; i <= page + 1; i++) { // preload left and right cell
        if (i >= 0 && i < self.photoModels.count) {
            HCWPhotoCell *cell = [self cellForPage:i];
            if (!cell) {
                HCWPhotoCell *cell = [self dequeueReusableCell];
                cell.page = i;
                cell.frame = (CGRect){(self.bounds.size.width + kPadding) * i + kPadding / 2, cell.frame.origin.y, cell.bounds.size.width, cell.bounds.size.height};
                
                if (_isPresented) {
                    cell.photoModel = self.photoModels[i];
                }
                [self.scrollView addSubview:cell];
            } else {
                if (_isPresented && !cell.photoModel) {
                    cell.photoModel = self.photoModels[i];
                }
            }
        }
    }
    
    NSInteger intPage = floatPage + 0.5;
    intPage = intPage < 0 ? 0 : intPage >= _photoModels.count ? (int)_photoModels.count - 1 : intPage;
    _pager.currentPage = intPage;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        _pager.alpha = 1;
    }completion:^(BOOL finish) {
    }];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        [self hidePager];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self hidePager];
}

- (void)updateCellsForReuse {
    for (HCWPhotoCell *cell in _cells) {
        if (cell.superview) {
            if (cell.frame.origin.x > _scrollView.contentOffset.x + _scrollView.bounds.size.width * 2||
                cell.frame.origin.x+cell.bounds.size.width < _scrollView.contentOffset.x - _scrollView.bounds.size.width) {
                [cell removeFromSuperview];
                cell.page = -1;
                cell.photoModel = nil;
            }
        }
    }
}

- (HCWPhotoCell *)dequeueReusableCell {
    HCWPhotoCell *cell = nil;
    for (cell in _cells) {
        if (!cell.superview) {
            return cell;
        }
    }
    
    cell = [HCWPhotoCell new];
    cell.frame = self.bounds;
    cell.imageContainerView.frame = self.bounds;
    cell.imageView.frame = cell.bounds;
    cell.page = -1;
    cell.photoModel = nil;
    [_cells addObject:cell];
    return cell;
}

- (HCWPhotoCell *)cellForPage:(NSInteger)page {
    for (HCWPhotoCell *cell in _cells) {
        if (cell.page == page) {
            return cell;
        }
    }
    return nil;
}

- (void)hidePager {
    [UIView animateWithDuration:0.3 delay:0.8 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        _pager.alpha = 0;
    }completion:^(BOOL finish) {
    }];
}

- (UIImage *)snapshotImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

- (UIImage *)snapshotImageAfterScreenUpdates:(BOOL)afterUpdates {
    if (![self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        return [self snapshotImage];
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:afterUpdates];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)scrollToTopAnimated:(BOOL)animated scroll:(UIScrollView *)scroll
{
    CGPoint off = scroll.contentOffset;
    off.y = 0 - scroll.contentInset.top;
    [scroll setContentOffset:off animated:animated];
}

@end
