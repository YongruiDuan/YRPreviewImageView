//
//  YRPreviewDataSource.m
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import "YRPreviewDataSource.h"
#import "YRPreviewImageView.h"
#import "YRPreviewCell.h"
#import <objc/runtime.h>

@interface YRPreviewDataSource ()

@end

@implementation YRPreviewDataSource

- (instancetype)init
{
	self = [super init];
	if (self) {
		self.scales = [NSMutableArray array];
		self.origins = [NSMutableArray array];
	}
	return self;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
	YRPreviewImageView *preview = (YRPreviewImageView *)collectionView;
	YRPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPreviewCell forIndexPath:indexPath];
	cell.scale = self.scales[indexPath.item].floatValue;
	cell.origin = self.origins[indexPath.item].CGPointValue;
	cell.tap = preview.tap;
	cell.tag = indexPath.item;
	cell.longpress = preview.longpress;
	cell.rect = [self.rects[indexPath.row] CGRectValue];
	cell.thumbnail = preview.thumbnails[indexPath.row];
	cell.imagePath = preview.images[indexPath.row];
	cell.previewView = preview;
	return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	YRPreviewImageView *preview = (YRPreviewImageView *)collectionView;
	[self.scales removeAllObjects];
	[self.origins removeAllObjects];
	for (int i = 0; i < preview.images.count; ++i) {
		[self.scales addObject:[NSNumber numberWithFloat:preview.minScale]];
		[self.origins addObject:[NSValue valueWithCGPoint:CGPointZero]];
	}
	return preview.images.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
	YRPreviewCell *preCell = (YRPreviewCell *)cell;
	[preCell.scrollView setZoomScale:self.scales[indexPath.item].floatValue];
	[preCell.scrollView setNeedsLayout];
	[preCell.scrollView layoutIfNeeded];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
	YRPreviewCell *preCell = (YRPreviewCell *)cell;
	self.scales[indexPath.item] = [NSNumber numberWithFloat:preCell.scrollView.zoomScale];
	self.origins[indexPath.item] = [NSValue valueWithCGPoint:preCell.scrollView.contentOffset];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	YRPreviewImageView *preview = (YRPreviewImageView *)scrollView;
	CGSize previewSize = preview.bounds.size;
	preview.currentIndex = (scrollView.contentOffset.x+previewSize.width/2.0)/previewSize.width;
}

@end
