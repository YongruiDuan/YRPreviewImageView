//
//  YRPreviewImageView.h
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YRPreviewDataSource.h"
NS_ASSUME_NONNULL_BEGIN

@interface YRPreviewImageView : UICollectionView

@property (nonnull, nonatomic, strong, readonly) NSArray<NSNumber *> *scales;

@property (nonnull, nonatomic, strong, readonly) NSArray<NSValue *> *offsets;

/**
 分页控制器
 */
@property (nonatomic, strong, readonly) UIPageControl *pageControl;

/**
 保存图片完成回调
 参数：@{@"image":image, @"error":error}（image为UIImage, error为NSError）
 @discussion: error为空时 image不为空，当error存在时 image为空
 */
@property (nonatomic, strong) RACReplaySubject *saveComplete;

/**
 分享操作
 @discussion: 参数为UIImage类型
 */
@property (nonatomic, strong) RACReplaySubject *shareAction;

/**
 是否开启视图出现动画
 默认 YES
 */
@property (nonatomic, assign) BOOL showAnimation;

/**
 视图出现动画持续时间
 默认 0.5s
 */
@property (nonatomic, assign) NSTimeInterval showDuration;

/**
 是否开启视图移除动画
 默认 0.5s
 */
@property (nonatomic, assign) BOOL hideAnimation;

/**
 视图隐藏动画持续时间
 默认 YES
 */
@property (nonatomic, assign) NSTimeInterval hideDuration;

/**
 预览的图片数组(必填)
 */
@property (nonatomic, copy) NSArray<NSString *> *images;

/**
 缩略图数组(必填)
 */
@property (nonatomic, copy) NSArray<UIImage *> *thumbnails;

/**
 图片缩放的最大比例，默认 3.0
 */
@property (nonatomic, assign) CGFloat maxScale;

/**
 图片缩放的最小比例，默认 1.0
 */
@property (nonatomic, assign) CGFloat minScale;

/**
 当前显示的图片索引，默认 第一张 0
 */
@property (nonatomic, assign) NSInteger currentIndex;

/**
 Tap手势信号
 */
@property (nonatomic, strong, readonly) RACReplaySubject *tap;

/**
 Longpress手势信号
 */
@property (nonatomic, strong, readonly) RACReplaySubject *longpress;

/**
 初始化方法

 @param frame 视图位置
 @return 实例
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 视图展示（若视图frame未设置，或为zero，则视图不会添加到父视图）

 @param animation 是否有动画
 @param viewController 父视图的控制器
 @param rects 每个图片在预览视图中的位置(CGRect转NSValue)
 */
- (void)show:(BOOL)animation
		  to:(UIViewController *)viewController
   withRects:(NSArray<NSValue *> *_Nullable)rects;


/**
 带布局的初始化方法

 @param frame 视图位置
 @param layout 视图布局（不支持自定义布局，此参数无效）
 @return 实例
 */
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *_Nonnull)layout;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
