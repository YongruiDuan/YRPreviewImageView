//
//  YRPreviewImageView.m
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import "YRPreviewImageView.h"
#import "YRPreviewCell.h"
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface YRPreviewImageView () {
	NSInteger _animate;
}

@property (nullable, nonatomic, strong) YRPreviewDataSource *source;

// 历史缩放
@property (nonnull,nonatomic, strong) NSMutableArray <NSNumber *> *scales;

// 历史位置
@property (nonnull,nonatomic, strong) NSMutableArray <NSValue *> *origins;

@property (nonatomic, weak) UIViewController *viewController;

/**
 分页控制器
 */
@property (nonatomic, strong) UIPageControl *pageControl;

/**
 Tap手势信号
 */
@property (nonatomic, strong) RACReplaySubject *tap;

/**
 Longpress手势信号
 */
@property (nonatomic, strong) RACReplaySubject *longpress;

@end

NS_ASSUME_NONNULL_END

@implementation YRPreviewImageView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
#pragma mark - 懒加载

- (YRPreviewDataSource *)source {
	if (!_source) {
		_source = [[YRPreviewDataSource alloc]init];;
	}
	return _source;
}

- (UIPageControl *)pageControl {
	if (!_pageControl) {
		_pageControl = [[UIPageControl alloc] init];
		_pageControl.backgroundColor = [UIColor clearColor];
		_pageControl.tintColor = [UIColor whiteColor];
		_pageControl.userInteractionEnabled = NO;
	}
	return _pageControl;
}

- (RACReplaySubject *)tap {
	if (!_tap) {
		_tap = [RACReplaySubject subject];
		@weakify(self);
		[_tap subscribeNext:^(UITapGestureRecognizer * _Nullable x) {
			@strongify(self);
			if (x.numberOfTouches == 1) {
				[self hide];
			}
		}];
	}
	return _tap;
}

- (RACReplaySubject *)longpress {
	if (!_longpress) {
		_longpress = [RACReplaySubject subject];
	}
	return _longpress;
}

- (RACReplaySubject *)saveComplete {
	if (!_saveComplete) {
		_saveComplete = [RACReplaySubject subject];
	}
	return _saveComplete;
}

- (RACReplaySubject *)shareAction {
	if (!_shareAction) {
		_shareAction = [RACReplaySubject subject];
	}
	return _shareAction;
}

- (BOOL)showAnimation {
	return _animate;
}

/**
 对网络图片进行url编码

 @param images 图片地址数组
 */
- (void)setImages:(NSArray<NSString *> *)images
{
	[images.rac_sequence map:^id _Nullable(NSString * _Nullable value) {
		if ([value.lowercaseString containsString:@"http"]) {
			if (@available(iOS 10.0, *)) {
				return [value stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet];
			}
			return [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}
		return value;
	}];
	_images = images;
	self.pageControl.numberOfPages = images.count;
}

/**
 设置当前索引

 @param currentIndex 索引
 */
- (void)setCurrentIndex:(NSInteger)currentIndex {
	_currentIndex = currentIndex;
	self.pageControl.currentPage = currentIndex;
}

/**
 展示预览视图

 @param animation 是否有动画
 @param viewController 父视图的控制器
 @param rects 每个图片在预览视图中的位置(CGRect转NSValue)
 */
- (void)show:(BOOL)animation to:(UIViewController *)viewController withRects:(NSArray<NSValue *> *_Nullable)rects
{
	// 取消父视图键盘响应
	if (viewController.view.isFirstResponder) {
		[viewController.view endEditing:YES];
	}
	if ([viewController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
		((UINavigationController *)viewController).interactivePopGestureRecognizer.enabled = NO;
	}
	NSAssert(!CGRectEqualToRect(self.frame, CGRectZero), @"ERROR : 预览视图frame为CGRectZero");
	self.viewController = viewController;
	CGFloat height = 30.0;
	self.pageControl.frame = CGRectMake(0, self.frame.size.height - height, self.frame.size.width, height);
	self.alpha = 0;
	self.source.rects = rects;
	[viewController.view addSubview:self];
	[viewController.view addSubview:self.pageControl];
	self.showAnimation = animation;
	_animate = animation;
	self.backgroundColor = [UIColor clearColor];
	self.alpha = 1.0;
	[self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
}


/**
 移除预览视图方法
 */
- (void)hide
{
	if ([self.viewController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
		((UINavigationController *)self.viewController).interactivePopGestureRecognizer.enabled = YES;
	}
	[self.pageControl removeFromSuperview];
	[self removeFromSuperview];
}

/**
 变量初始化
 */
- (void)initVariable {
	if (@available(iOS 11.0, *)) {
		self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
	}
	[self setPagingEnabled:YES];
	self.dataSource = self.source;
	self.delegate = self.source;
	self.scales = self.source.scales;
	self.origins = self.source.origins;
	// 设置变量默认值
	self.maxScale = 3.0;
	self.minScale = 1.0;
	self.showAnimation = YES;
	_animate = YES;
	self.hideAnimation = YES;
	self.showDuration = 0.3;
	self.hideDuration = 0.3;
	self.showsHorizontalScrollIndicator = NO;
	self.showsVerticalScrollIndicator = NO;
	self.backgroundColor = [UIColor blackColor];
	[self registerClass:[YRPreviewCell classForCoder] forCellWithReuseIdentifier:kPreviewCell];
	self.currentIndex = 0;
	@weakify(self);
	[self.tap subscribeNext:^(UITapGestureRecognizer * _Nullable x) {
		@strongify(self);
		[self hide];
	}];
	// 长按回调
	[self.longpress subscribeNext:^(UILongPressGestureRecognizer * _Nullable x) {
		@strongify(self);
		switch (x.state) {
			case UIGestureRecognizerStateBegan:
			{
				// 弹出alertsheet进行保存和分享操作
				UIAlertController *actionSheetController = [UIAlertController alertControllerWithTitle:nil
																					message:nil
																			 preferredStyle:UIAlertControllerStyleActionSheet];
				UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
																	 style:UIAlertActionStyleCancel
																   handler:^(UIAlertAction * _Nonnull action) {
																	   
																   }];
				UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存"
																	 style:UIAlertActionStyleDefault
																   handler:^(UIAlertAction * _Nonnull action) {
																	   dispatch_async(dispatch_get_main_queue(), ^{
																		   // 保存图片
																		   [self savePhoto];
																	   });
																	   
																   }];
				UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"分享"
																	 style:UIAlertActionStyleDefault
																   handler:^(UIAlertAction * _Nonnull action) {
																	   // 分享操作
																	   dispatch_async(dispatch_get_main_queue(), ^{
																		   [self share];
																	   });
																   }];
				[actionSheetController addAction:cancelAction];
				[actionSheetController addAction:saveAction];
				[actionSheetController addAction:shareAction];
				[self.viewController presentViewController:actionSheetController animated:YES completion:^{
					
				}];
			}
				break;
				
			default:
				break;
		}
	}];
}

/**
 分享
 */
- (void)share {
	YRPreviewCell *cell = (YRPreviewCell *)[self cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
	
	UIImage *image = cell.imageView.image;
	
	if (!image) {
//		[MBProgressHUD y_showMsg:@"获取图片失败"];
		return ;
	}
	
}

/**
 保存图片
 */
- (void)savePhoto {
	YRPreviewCell *cell = (YRPreviewCell *)[self cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
	
	UIImage *image = cell.imageView.image;
	
	if (!image) {
//		[MBProgressHUD y_showMsg:@"获取图片失败"];
		return ;
	}
	switch ([TZImageManager authorizationStatus]) {
		case 0:
		{
			[[TZImageManager manager] requestAuthorizationWithCompletion:^{
				
				[[TZImageManager manager] savePhotoWithImage:image completion:^(NSError *error) {
					
					if (error) {
//						[MBProgressHUD y_showMsg:@"保存失败"];
						NSError *error = [NSError errorWithDomain:@"jinyiao" code:-400 userInfo:nil];
						[self.saveComplete sendNext:@{@"error":error}];
					} else {
//						[MBProgressHUD y_showMsg:@"保存成功"];
						[self.saveComplete sendNext:@{@"image":image, @"error":error}];
					}
				}];
			}];
		}
			break;
			
		case 3:
		{
			[[TZImageManager manager] savePhotoWithImage:image completion:^(NSError *error) {
				
				if (error) {
//					[MBProgressHUD y_showMsg:@"保存失败"];
					NSError *error = [NSError errorWithDomain:@"jinyiao" code:-400 userInfo:nil];
					[self.saveComplete sendNext:@{@"error":error}];
				} else {
//					[MBProgressHUD y_showMsg:@"保存成功"];
					NSError *error = [NSError errorWithDomain:@"jinyiao" code:-400 userInfo:nil];
					[self.saveComplete sendNext:@{@"image":image,@"error":error}];
				}
			}];
		}
			break;
			
		default:
//			[MBProgressHUD y_showMsg:@"请打开访问相册权限"];
			break;
	}
}

/**
 保存图片至相册(废弃)

 @param image 图片
 @param completion 保存完成回调
 */
- (void)saveImageToPhotosAlbum:(UIImage *)image completed:(void (^)(BOOL finished, PHAsset *asset, NSError *error))completion {
	/*
	CGImageSourceRef source1 = CGImageSourceCreateWithData((__bridge CFDataRef)UIImagePNGRepresentation(image), NULL);
	if (NULL != source1) {
		NSDictionary * metadataDic = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source1, 0, NULL));
		NSLog(@"metada11111:%@",metadataDic);
		NSLog(@"imageOrientation : %ld", image.imageOrientation);
	}*/
	__block PHObjectPlaceholder *placeholderAsset = nil;
	[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
		PHAssetChangeRequest *newAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
		newAssetRequest.creationDate = [NSDate date];
		placeholderAsset = newAssetRequest.placeholderForCreatedAsset;
	} completionHandler:^(BOOL success, NSError *error) {
		if(success){
			PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
			options.networkAccessAllowed = YES;
			options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
			options.synchronous = YES;
			options.resizeMode = PHImageRequestOptionsResizeModeNone;
			PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[placeholderAsset.localIdentifier] options:nil];
			[result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				completion(YES, obj, nil);
				/*
				[[PHImageManager defaultManager] requestImageDataForAsset:obj options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
					CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
					if (NULL != source) {
						NSDictionary * metadataDic = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
						NSLog(@"metada:%@",metadataDic);
						NSLog(@"imageOrientation : %ld", [[UIImage alloc] initWithData:imageData].imageOrientation);
					}
				}];
				 */
			}];
		} else {
			completion(NO, nil, error);
		}
	}];
}

- (instancetype)init
{
	// 创建布局对象
	UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
	layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	layout.itemSize = CGSizeZero;
	layout.minimumLineSpacing = 20.0;
	layout.minimumInteritemSpacing = 0;
	self = [super initWithFrame:CGRectZero];
	// 切换调用的初始化方法
	if (self = [super initWithFrame:CGRectZero collectionViewLayout:layout]) {
		[self initVariable];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	// 创建布局对象
	frame.size.width = frame.size.width + 20.0;
	UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
	layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	layout.itemSize = frame.size;
	layout.minimumLineSpacing = 0;
	layout.minimumInteritemSpacing = 0;
	
	// 切换调用的初始化方法
	if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
		[self initVariable];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
	// 创建布局对象
	frame.size.width = frame.size.width + 20.0;
	UICollectionViewFlowLayout *newLayout = [[UICollectionViewFlowLayout alloc]init];
	newLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	newLayout.itemSize = frame.size;
	newLayout.minimumLineSpacing = 0;
	newLayout.minimumInteritemSpacing = 0;
	
	// 切换调用的初始化方法
	if (self = [super initWithFrame:frame collectionViewLayout:newLayout]) {
		[self initVariable];
	}
	return self;
}

@end
