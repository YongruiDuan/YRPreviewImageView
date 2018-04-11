//
//  YRPreviewCell.m
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import "YRPreviewCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YRPanDirectionState) {
	YRPanDirectionUnknown, // 滑动无效或滑动方向未知
	YRPanDirectionTop, // 向上滑动
	YRPanDirectionRight, // 向右滑动
	YRPanDirectionBottom, // 向下滑动
	YRPanDirectionLeft // 向左滑动
};

@interface YRPreviewCell ()<UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGRect originalFrame;

@property (nonatomic, assign) CGPoint touchPoint;

@property (nonatomic, assign) CGPoint touchBeganPoint;

@property (nonatomic, weak) RACDisposable *offsetDisposable;

@property (nonatomic, weak) RACDisposable *tapDisposable;

@property (nonatomic, weak) RACDisposable *doubleTapDisposable;

@property (nonatomic, weak) RACDisposable *panCollectionDisposable;

@property (nonatomic, weak) RACDisposable *panDisposable;

@property (nonatomic, weak) RACDisposable *customPanDisposable;

@property (nonatomic, weak) RACDisposable *longPressDisposable;

@property (nonatomic, weak) RACDisposable *loadImageDisposable;

/**
 滚动视图
 */
@property (nonatomic, strong) YRPreviewScrollView *scrollView;

/**
 Tap 单击手势
 */
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

/**
 Tap 双击手势
 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;

/**
 longPress手势
 */
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;

/**
 滑动手势
 */
//@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

NS_ASSUME_NONNULL_END

@implementation YRPreviewCell

#pragma mark - 懒加载

- (YRPreviewScrollView *)scrollView {
	if (!_scrollView) {
		_scrollView = [[YRPreviewScrollView alloc] init];
		if (@available(iOS 11.0, *)) {
			_scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
		}
		_scrollView.delegate = _scrollView;
		_scrollView.scrollEnabled = YES;
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.alwaysBounceHorizontal = NO;
		_scrollView.alwaysBounceVertical = YES;
		_scrollView.backgroundColor = [UIColor clearColor];
	}
	return _scrollView;
}

- (UITapGestureRecognizer *)tapGesture {
	if (!_tapGesture) {
		_tapGesture = [[UITapGestureRecognizer alloc] init];
	}
	return _tapGesture;
}

- (UITapGestureRecognizer *)doubleTapGesture {
	if (!_doubleTapGesture) {
		_doubleTapGesture = [[UITapGestureRecognizer alloc] init];
		_doubleTapGesture.numberOfTapsRequired = 2;
		_doubleTapGesture.numberOfTouchesRequired = 1;
	}
	return _doubleTapGesture;
}

- (UILongPressGestureRecognizer *)longPressGesture {
	if (!_longPressGesture) {
		_longPressGesture = [[UILongPressGestureRecognizer alloc] init];
	}
	return _longPressGesture;
}

//- (UIPanGestureRecognizer *)panGesture {
//	if (!_panGesture) {
//		_panGesture = [[UIPanGestureRecognizer alloc] init];
//		_panGesture.delegate = self;
//		_panGesture.maximumNumberOfTouches = 1;
//	}
//	return _panGesture;
//}

/**
 *   判断手势方向
 *
 *  @param translation translation description
 *  作者链接: http://blog.csdn.net/u010990519/article/details/38300629
 */
- (YRPanDirectionState)commitTranslation:(CGPoint)translation
{
	
	CGFloat absX = fabs(translation.x);
	CGFloat absY = fabs(translation.y);
	// 设置滑动有效距离
//	if (MAX(absX, absY) < 10)
//		return YRPanDirectionUnknown;
	if (absX > absY ) {
		if (translation.x<0) {
			//向左滑动
			return YRPanDirectionLeft;
		}else{
			//向右滑动
			return YRPanDirectionRight;
		}
		
	} else if (absY > absX) {
		if (translation.y<0) {
			//向上滑动
			return YRPanDirectionTop;
		}else{
			//向下滑动
			return YRPanDirectionBottom;
		}
	}
	return YRPanDirectionUnknown;
}

- (UIImageView *)imageView {
	if (!_imageView) {
		_imageView = [[UIImageView alloc] init];
		_imageView.userInteractionEnabled = NO;
		_imageView.clipsToBounds = YES;
		_imageView.contentMode = UIViewContentModeScaleAspectFill;
	}
	return _imageView;
}

- (void)setPreviewView:(YRPreviewImageView *)previewView
{
	_previewView = previewView;
	self.scrollView.frame = CGRectMake(0, 0, _previewView.bounds.size.width-20.0, _previewView.bounds.size.height);
	self.scrollView.maximumZoomScale = _previewView.maxScale;
	self.scrollView.minimumZoomScale = _previewView.minScale;
	// 设置tap单击和双击优先级
	[self.tapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
	// 设置滑动手势优先级
//	[self.panGesture requireGestureRecognizerToFail:self.scrollView.panGestureRecognizer];
//	[self.panGesture requireGestureRecognizerToFail:self.previewView.panGestureRecognizer];
	[self.offsetDisposable dispose];
	@weakify(self);
	self.offsetDisposable = [RACObserve(self, scrollView.contentOffset) subscribeNext:^(id _Nullable x) {
		@strongify(self);
		if (x != nil) {
			if (self.scrollView.isZoomBouncing
				&& (self.scrollView.zoomScale <= self.previewView.minScale || self.scrollView.zoomScale >= self.previewView.maxScale)) {
				[UIView animateWithDuration:0.29 animations:^{
					self.imageView.center = self.scrollView.center;
					[self setNeedsLayout];
					[self layoutIfNeeded];
				}];
			}
		}
	}];
	// 单击
	[self.tapDisposable dispose];
	self.tapDisposable = [[self.tapGesture rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
		self.contentView.userInteractionEnabled = NO;
		@strongify(self);
		if (self.previewView.hideAnimation) {
			// 开启移除动画
			self.previewView.backgroundColor = [UIColor clearColor];
			self.previewView.pageControl.alpha = 0;
			self.scrollView.isPinch = NO;
			self.scrollView.userInteractionEnabled = NO;
//			self.panGesture.enabled = NO;
			self.previewView.scrollEnabled = NO;
			[UIView animateWithDuration:self.previewView.hideDuration animations:^{
				CGPoint offset = self.scrollView.contentOffset;
				self.imageView.frame = CGRectMake(self.rect.origin.x + (offset.x > 0 ? offset.x:0), self.rect.origin.y + (offset.y > 0 ? offset.y:0), self.rect.size.width, self.rect.size.height);
			} completion:^(BOOL finished) {
//				self.panGesture.enabled = YES;
				self.scrollView.isPinch = YES;
				self.scrollView.userInteractionEnabled = YES;
				self.contentView.userInteractionEnabled = YES;
				self.previewView.scrollEnabled = YES;
				[self.tap sendNext:x];
				[self.tap sendCompleted];
			}];
			return;
		} else {
			// 通知预览视图点击事件
			[self.tap sendNext:x];
			[self.tap sendCompleted];
			self.contentView.userInteractionEnabled = YES;
		}
	}];
	// 双击
	[self.doubleTapDisposable dispose];
	self.doubleTapDisposable = [self.doubleTapGesture.rac_gestureSignal subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
		@strongify(self);
		if (self.scrollView.zoomScale != self.scrollView.minimumZoomScale) {
			// 缩小
			[self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
		} else {
			self.scrollView.isPinch = YES;
			// 计算放大到什么区域
			CGPoint touch = [x locationInView:self.imageView];
			BOOL needOffset = YES;
			CGPoint offset = [self calcuteContentOffsetWithSize:self.imageView.frame.size touchPoint:touch needReset:&needOffset];
			[UIView animateWithDuration:0.2 animations:^{
				self.scrollView.zoomScale = 2.0;
				if (needOffset) {
					self.scrollView.contentOffset = offset;
				}
			}];
		}
	}];
	
	[self bindLoadImage];
	[self.panCollectionDisposable dispose];
	self.panCollectionDisposable = [self.previewView.panGestureRecognizer.rac_gestureSignal subscribeNext:^(__kindof UIPanGestureRecognizer * _Nullable x) {
		@strongify(self);
		if (self.scrollView.zooming) {
			return;
		}
		switch (x.state) {
			case UIGestureRecognizerStateChanged:
				if ([self commitTranslation:[x translationInView:self.scrollView]] == YRPanDirectionBottom && self.scrollView.contentOffset.y <= 0) {
					self.previewView.panGestureRecognizer.enabled = NO;
//					self.panGesture.enabled = YES;
				} else {
//					self.panGesture.enabled = NO;
				}
				break;
			case UIGestureRecognizerStateEnded:
//				self.panGesture.enabled = YES;
				break;
			case UIGestureRecognizerStateFailed:
//				self.panGesture.enabled = YES;
				break;
			default:
				break;
		}
	}];
	// 给scrollView自带滑动手势添加响应事件
	/*
	[self.panDisposable dispose];
	self.panDisposable = [self.scrollView.panGestureRecognizer.rac_gestureSignal subscribeNext:^(__kindof UIPanGestureRecognizer * _Nullable x) {
		@strongify(self);
		if (self.scrollView.zooming) {
			return;
		}
		switch (x.state) {
			case UIGestureRecognizerStateChanged:
				if ([self commitTranslation:[x translationInView:self.scrollView]] == YRPanDirectionBottom && self.scrollView.contentOffset.y <= 0) {
					self.scrollView.panGestureRecognizer.enabled = NO;
//					self.panGesture.enabled = YES;
					self.scrollView.panGestureRecognizer.enabled = YES;
				} else {
//					self.panGesture.enabled = NO;
				}
				break;
			case UIGestureRecognizerStateEnded:
//				self.panGesture.enabled = YES;
				break;
			case UIGestureRecognizerStateFailed:
//				self.panGesture.enabled = YES;
				break;
			default:
				break;
		}
	}];
*/
	// 给自定义滑动手势添加响应事件
	[self bindPanAction];
	[self.longPressDisposable dispose];
	self.longPressDisposable = [self.longPressGesture.rac_gestureSignal subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
		@strongify(self);
		if (x.state == UIGestureRecognizerStateEnded || x.state == UIGestureRecognizerStateFailed) {
			self.scrollView.panGestureRecognizer.enabled = YES;
		}
		 [self.longpress sendNext:x];
	}];
}

- (void)bindLoadImage {
	CGSize previewSize = self.scrollView.frame.size;
	@weakify(self);
	[self.loadImageDisposable dispose];
	self.loadImageDisposable = [[RACSignal combineLatest:@[RACObserve(self, thumbnail), RACObserve(self, imagePath)] reduce:^id _Nullable(UIImage *thumb, NSString *imgPath){
		if (imgPath.length > 0 && thumb != nil) {
			return @[thumb,imgPath];
		}
		return nil;
	}] subscribeNext:^(RACTuple *_Nullable x) {
		@strongify(self);
		if (x != nil) {
			RACTupleUnpack(UIImage *thumb, NSString *imgPath) = x;
			SDWebImageOptions options = SDWebImageRefreshCached;
			CGSize size = CGSizeZero;
			if ([imgPath.lowercaseString containsString:@"http"]) {
				// 原图是网络请求的，缩略图是本地的
				size = thumb.size;
				NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:imgPath]];
				UIImage * image = [[SDImageCache sharedImageCache] imageFromCacheForKey:key];
				if (self.previewView.showAnimation && self.tag == self.previewView.currentIndex) {
					self.previewView.showAnimation = NO;
					self.scrollView.isPinch = NO;
					if (image) {
						self.imageView.image = image;
						size = image.size;
					} else {
						self.imageView.image = thumb;
					}
					self.imageView.frame = self.rect;
					self.scrollView.userInteractionEnabled = NO;
					[UIView animateWithDuration:self.previewView.showDuration animations:^{
						self.imageView.frame = [self calculateImageFrame:size previewSize:previewSize];
					} completion:^(BOOL finished) {
						self.scrollView.userInteractionEnabled = YES;
						self.previewView.backgroundColor = [UIColor blackColor];
						self.scrollView.isPinch = YES;
						if (!image) {
							@weakify(self);
							[self.imageView sd_setImageWithURL:[NSURL URLWithString:imgPath] placeholderImage:self.imageView.image options:options progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
								
							} completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
								@strongify(self);
								if (image != nil) {
									self.imageView.frame = [self calculateImageFrame:image.size previewSize:previewSize];
								}
							}];
						} else {
							self.scrollView.userInteractionEnabled = YES;
						}
						[self.scrollView setNeedsLayout];
						[self.scrollView layoutIfNeeded];
					}];
				} else {
					if (image) {
						size = image.size;
					}
					self.previewView.backgroundColor = [UIColor blackColor];
					self.imageView.frame = [self calculateImageFrame:size previewSize:previewSize];
					self.scrollView.userInteractionEnabled = NO;
					@weakify(self);
					[self.imageView sd_setImageWithURL:[NSURL URLWithString:imgPath] placeholderImage:thumb options:options progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
						
					} completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
						@strongify(self);
						self.scrollView.userInteractionEnabled = YES;
						if (image != nil) {
							self.imageView.frame = [self calculateImageFrame:image.size previewSize:previewSize];
						}
						[self.scrollView setNeedsLayout];
						[self.scrollView layoutIfNeeded];
					}];
				}
			} else {
				// 原图和缩略图都是本地的
				size = [UIImage imageNamed:imgPath].size;
				self.imageView.image = [UIImage imageNamed:imgPath];
				if (self.previewView.showAnimation && self.tag == self.previewView.currentIndex) {
					self.previewView.showAnimation = NO;
					self.scrollView.isPinch = NO;
					self.imageView.frame = self.rect;
					[UIView animateWithDuration:self.previewView.showDuration animations:^{
						self.imageView.frame = [self calculateImageFrame:size previewSize:previewSize];
					} completion:^(BOOL finished) {
						self.previewView.backgroundColor = [UIColor blackColor];
						self.scrollView.isPinch = YES;
						self.scrollView.userInteractionEnabled = YES;
						self.scrollView.maximumZoomScale = self.previewView.maxScale;
						[self setNeedsLayout];
						[self layoutIfNeeded];
					}];
				} else {
					self.imageView.frame = [self calculateImageFrame:size previewSize:previewSize];
					[self setNeedsLayout];
					[self layoutIfNeeded];
					self.scrollView.userInteractionEnabled = YES;
					self.previewView.backgroundColor = [UIColor blackColor];
				}
			}
		}
	}];
}

- (void)bindPanAction {
	/*
	// 给自定义滑动手势添加响应事件
	@weakify(self);
	[self.customPanDisposable dispose];
	self.customPanDisposable = [self.panGesture.rac_gestureSignal subscribeNext:^(__kindof UIPanGestureRecognizer * _Nullable x) {
		@strongify(self);
		if (self.scrollView.zooming) {
			return;
		}
		switch (x.state) {
			case UIGestureRecognizerStateBegan:
			{
				self.originalFrame = self.imageView.frame;
				self.touchPoint = [x locationInView:self.imageView];
				self.touchBeganPoint = [x locationInView:self.scrollView];
				self.scrollView.isPinch = NO;
			}
				break;
			case UIGestureRecognizerStateChanged:
			{
				YRPanDirectionState state = [self commitTranslation:[x translationInView:self.scrollView]];
				if ((state == YRPanDirectionBottom || state == YRPanDirectionTop)) {
					CGPoint currentPoint = [x locationInView:self.scrollView];
					CGSize scrollSize = self.scrollView.frame.size;
					// 为防止缩放过小，添加一段高度进行比例计算
					CGFloat ratio = 1 - (scrollSize.height - currentPoint.y + scrollSize.height)/(scrollSize.height - self.touchBeganPoint.y + scrollSize.height);
					self.imageView.frame = CGRectMake(self.originalFrame.origin.x + currentPoint.x - self.touchBeganPoint.x + self.touchBeganPoint.x*ratio, self.originalFrame.origin.y + currentPoint.y - self.touchBeganPoint.y, self.originalFrame.size.width*(1-ratio), self.originalFrame.size.height*(1-ratio));
					self.previewView.backgroundColor = [UIColor colorWithWhite:0 alpha:(1-ratio)];
					[self.scrollView setNeedsLayout];
					[self.scrollView layoutIfNeeded];
				}
				break;
			}
			case UIGestureRecognizerStateEnded:
			{
				self.scrollView.panGestureRecognizer.enabled = YES;
				self.previewView.panGestureRecognizer.enabled = YES;
				self.panGesture.enabled = YES;
				self.scrollView.isPinch = YES;
				if (CGColorGetAlpha(self.previewView.backgroundColor.CGColor) < 0.75) {
					self.contentView.userInteractionEnabled = NO;
					self.scrollView.panGestureRecognizer.enabled = YES;
					if (CGRectEqualToRect(self.rect, CGRectZero)) {
						[self.previewView hide];
						self.contentView.userInteractionEnabled = YES;
					} else {
						if (self.previewView.hideAnimation) {
							// 开启移除动画
							self.previewView.backgroundColor = [UIColor clearColor];
							self.previewView.pageControl.alpha = 0;
							self.scrollView.isPinch = NO;
							self.scrollView.userInteractionEnabled = NO;
							self.previewView.scrollEnabled = NO;
							[UIView animateWithDuration:self.previewView.hideDuration animations:^{
								CGPoint offset = self.scrollView.contentOffset;
								self.imageView.frame = CGRectMake(self.rect.origin.x + (offset.x > 0 ? offset.x:0), self.rect.origin.y + (offset.y > 0 ? offset.y:0), self.rect.size.width, self.rect.size.height);
							} completion:^(BOOL finished) {
								self.contentView.userInteractionEnabled = YES;
								self.scrollView.userInteractionEnabled = YES;
								self.previewView.scrollEnabled = YES;
								self.scrollView.isPinch = YES;
								[self.previewView hide];
							}];
							return;
						}
						[self.previewView hide];
						self.contentView.userInteractionEnabled = YES;
					}
					return;
				}
				if (!CGRectEqualToRect(self.imageView.frame, self.originalFrame) && !CGRectEqualToRect(self.originalFrame, CGRectZero)) {
					[UIView animateWithDuration:0.3 animations:^{
						self.imageView.frame = self.originalFrame;
						self.previewView.backgroundColor = [UIColor blackColor];
					}];
				}
				break;
			}
			case UIGestureRecognizerStateFailed:
			{
				self.scrollView.panGestureRecognizer.enabled = YES;
				self.previewView.panGestureRecognizer.enabled = YES;
				self.scrollView.isPinch = YES;
				self.panGesture.enabled = YES;
				break;
			}
				
			default:
				break;
		}
	}];
	 */
}

/**
 计算图片初始尺寸

 @param imageSize 图片尺寸
 @param previewSize 预览视图尺寸
 @return 结果
 */
- (CGRect)calculateImageFrame:(CGSize)imageSize previewSize:(CGSize)previewSize {
	CGFloat width = 0;
	CGFloat height = 0;
	CGFloat x = 0;
	CGFloat y = 0;
	if (imageSize.height/imageSize.width > previewSize.height/previewSize.width) {
		height = previewSize.height;
		width = height * imageSize.width / imageSize.height;
	} else if (imageSize.height/imageSize.width < previewSize.height/previewSize.width) {
		width = previewSize.width;
		height = width * imageSize.height/imageSize.width;
	} else {
		width = previewSize.width;
		height = previewSize.height;
	}
	width *= self.scale;
	height *= self.scale;
	x = (previewSize.width - width)/2;
	y = (previewSize.height - height)/2;
	[self.scrollView setContentOffset:self.origin];
	return CGRectMake(x, y, width, height);
}

- (CGPoint)calcuteContentOffsetWithSize:(CGSize)imgViewSize touchPoint:(CGPoint)touch needReset:(BOOL *)need {
	CGPoint offset = CGPointZero;
	CGFloat numberOfPart = 9.0;
	CGRect rect = CGRectMake(0, 0, imgViewSize.width*2, imgViewSize.height*2);
	CGSize tempSize = self.scrollView.frame.size;
	NSInteger numberOfComponent = sqrt(numberOfPart);
	CGFloat increaseWidth = imgViewSize.width / numberOfComponent;
	CGFloat increaseHeight = imgViewSize.height / numberOfComponent;
	for (int i=0; i<numberOfPart; ++i) {
		CGFloat minX = increaseWidth * (i%numberOfComponent);
		CGFloat minY = increaseHeight * (i/numberOfComponent);
		CGFloat maxX = minX + increaseWidth;
		CGFloat maxY = minY + increaseHeight;
		switch (i) {
			case 0:
				minX = minY = -CGFLOAT_MAX;
				break;
			case 8:
				maxX = maxY = CGFLOAT_MAX;
				break;
			case 2:
			{
				maxX = CGFLOAT_MAX;
				minY = -CGFLOAT_MAX;
			}
				break;
			case 6:
			{
				minX = -CGFLOAT_MAX;
				maxY = CGFLOAT_MAX;
			}
				break;
			case 1:
				minY = -CGFLOAT_MAX;
				break;
			case 3:
				minX = -CGFLOAT_MAX;
				break;
			case 5:
				maxX = CGFLOAT_MAX;
				break;
			case 7:
				maxY = CGFLOAT_MAX;
				break;
				
			default:
				break;
		}
		if (minX <= touch.x && minY <= touch.y && maxX >= touch.x && maxY >= touch.y) {
			switch (i) {
				case 2:
				{
					if (rect.size.width > tempSize.width && rect.size.height > tempSize.height) {
						offset.x = rect.size.width - tempSize.width;
						offset.y = 0;
					} else if (rect.size.width < tempSize.width && rect.size.height > tempSize.height) {
						offset.x = (rect.size.width - tempSize.width)/2;
						offset.y = 0;
					} else if (rect.size.width > tempSize.width && rect.size.height < tempSize.height) {
						offset.x = rect.size.width - tempSize.width;
						offset.y = 0;
					} else {
						*need = NO;
					}
					break;
				}
				case 6:
				{
					if (rect.size.width > tempSize.width && rect.size.height > tempSize.height) {
						offset.x = 0;
						offset.y = rect.size.height - tempSize.height;
					} else if (rect.size.width < tempSize.width && rect.size.height > tempSize.height) {
						offset.x = (rect.size.width - tempSize.width)/2;
						offset.y = rect.size.height - tempSize.height;
					} else if (rect.size.width > tempSize.width && rect.size.height < tempSize.height) {
						offset.x = 0;
						offset.y = 0;
					} else {
						*need = NO;
					}
					break;
				}
				case 8:
				{
					if (rect.size.width > tempSize.width && rect.size.height > tempSize.height) {
						offset.x = rect.size.width - tempSize.width;
						offset.y = rect.size.height - tempSize.height;
					} else if (rect.size.width < tempSize.width && rect.size.height > tempSize.height) {
						offset.x = (rect.size.width - tempSize.width)/2;
						offset.y = rect.size.height - tempSize.height;
					} else if (rect.size.width > tempSize.width && rect.size.height < tempSize.height) {
						offset.x = rect.size.width - tempSize.width;
						offset.y = 0;
					} else {
						*need = NO;
					}
					break;
				}
				case 1: {
					if (rect.size.width > tempSize.width && rect.size.height > tempSize.height) {
						offset.x = (rect.size.width - tempSize.width)/2;
						offset.y = 0;
					} else if (rect.size.width < tempSize.width && rect.size.height > tempSize.height) {
						offset.x = (rect.size.width - tempSize.width)/2;
						offset.y = 0;
					} else if (rect.size.width > tempSize.width && rect.size.height < tempSize.height) {
						*need = NO;
					} else {
						*need = NO;
					}
					break;
				}
				case 3: {
					if (rect.size.width > tempSize.width && rect.size.height > tempSize.height) {
						offset.x = 0;
						offset.y = (rect.size.height - tempSize.height)/2;
					} else if (rect.size.width < tempSize.width && rect.size.height > tempSize.height) {
						*need = NO;
					} else if (rect.size.width > tempSize.width && rect.size.height < tempSize.height) {
						offset.x = 0;
						offset.y = 0;
					} else {
						*need = NO;
					}
					break;
				}
				case 5: {
					if (rect.size.width > tempSize.width && rect.size.height > tempSize.height) {
						offset.x = rect.size.width - tempSize.width;
						offset.y = (rect.size.height - tempSize.height)/2;
					} else if (rect.size.width < tempSize.width && rect.size.height > tempSize.height) {
						*need = NO;
					} else if (rect.size.width > tempSize.width && rect.size.height < tempSize.height) {
						offset.x = rect.size.width - tempSize.width;
						offset.y = 0;
					} else {
						*need = NO;
					}
					break;
				}
				case 7: {
					if (rect.size.width > tempSize.width && rect.size.height > tempSize.height) {
						offset.x = (rect.size.width - tempSize.width)/2;
						offset.y = rect.size.height - tempSize.height;
					} else if (rect.size.width < tempSize.width && rect.size.height > tempSize.height) {
						offset.x = (rect.size.width - tempSize.width)/2;
						offset.y = rect.size.height - tempSize.height;
					} else if (rect.size.width > tempSize.width && rect.size.height < tempSize.height) {
						*need = NO;
					} else {
						*need = NO;
					}
					break;
				}
				case 4:
					*need = NO; // 中心位置不处理
					break;
					
				default:
				{
					offset.x = 0;
					offset.y = 0;
					break;
				}
			}
			break;
		}
	}
	
	return offset;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.scrollView.isPinch = YES;
		self.contentView.backgroundColor = [UIColor clearColor];
		[self.scrollView addGestureRecognizer:self.tapGesture];
//		[self.scrollView addGestureRecognizer:self.panGesture];
		[self.scrollView addGestureRecognizer:self.doubleTapGesture];
		[self.scrollView addGestureRecognizer:self.longPressGesture];
		
		self.scrollView.imageView = self.imageView;
		[self.contentView addSubview:self.scrollView];
		[self.scrollView addSubview:self.imageView];
	}
	return self;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	return YES;
}

@end
