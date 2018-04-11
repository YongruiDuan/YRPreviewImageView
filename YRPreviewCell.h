//
//  YRPreviewCell.h
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YRPreviewImageView.h"
#import "YRPreviewScrollView.h"

static NSString *_Nonnull kPreviewCell = @"preview_cell";

@interface YRPreviewCell : UICollectionViewCell

@property (nonnull, nonatomic, strong, readonly) YRPreviewScrollView *scrollView;

@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, assign) CGPoint origin;

/**
 用于缩放的图片视图
 */
@property (nonnull, nonatomic, strong) UIImageView *imageView;

/**
 预览视图
 */
@property (nullable, nonatomic, weak) YRPreviewImageView *previewView;

/**
 Tap手势信号
 */
@property (nullable, nonatomic, weak) RACReplaySubject *tap;

/**
 Longpress手势信号
 */
@property (nullable, nonatomic, weak) RACReplaySubject *longpress;

/**
 原图路径
 */
@property (nonnull, nonatomic, copy) NSString *imagePath;

/**
 缩略图
 */
@property (nullable, nonatomic, weak) UIImage *thumbnail;

/**
 原图片视图在YRPreviewImageView的父视图中位置
 */
@property (nonatomic, assign) CGRect rect;

@end
