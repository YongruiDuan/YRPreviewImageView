//
//  YRPreviewScrollView.h
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YRPreviewScrollView : UIScrollView<UIScrollViewDelegate>

@property (nonatomic, assign) BOOL isPinch;

@property (nonatomic, weak) UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END
