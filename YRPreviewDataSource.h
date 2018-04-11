//
//  YRPreviewDataSource.h
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YRPreviewDataSource : NSObject<UICollectionViewDataSource, UICollectionViewDelegate>

// 历史缩放
@property (nonnull,nonatomic, strong) NSMutableArray <NSNumber *> *scales;

// 历史偏移量
@property (nonnull,nonatomic, strong) NSMutableArray <NSValue *> *origins;

@property (nullable,nonatomic, copy) NSArray *rects; // 原图片视图在YRPreviewImageView父视图中的位置

@end
