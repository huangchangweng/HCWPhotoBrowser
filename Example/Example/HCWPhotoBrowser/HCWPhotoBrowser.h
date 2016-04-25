//
//  HCWPhotoBrowser.h
//  Example
//
//  Created by HCW on 16/4/25.
//  Copyright © 2016年 HCW. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCWPhotoModel : NSObject
@property (nonatomic, strong) UIView *thumbView;    ///< 装载小图的视图
@property (nonatomic, strong) NSURL *largeImageURL; ///< 大图的URL
@end

@interface HCWPhotoBrowser : UIView
@property (nonatomic, readonly) NSArray <HCWPhotoModel *> *photoModels;
@property (nonatomic, readonly) NSInteger currentPage;
@property (nonatomic, assign) BOOL blurEffectBackground;    ///< Default is YES

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithPhotoModels:(NSArray <HCWPhotoModel *> *)photoModels;

- (void)presentFromImageView:(UIView *)fromView
                 toContainer:(UIView *)container
                    animated:(BOOL)animated
                  completion:(void (^)(void))completion;

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)dismiss;
@end
