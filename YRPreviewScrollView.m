//
//  YRPreviewScrollView.m
//  initalize
//
//  Created by YR on 2017/12/19.
//  Copyright © 2017年 jinyiao. All rights reserved.
//

#import "YRPreviewScrollView.h"

@implementation YRPreviewScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)layoutSubviews {
	[super layoutSubviews];
	if (!self.isPinch) {
		return;
	}
	CGRect rect = self.imageView.frame;
	CGRect scrollRect = self.frame;
	if (rect.size.width < scrollRect.size.width) {
		rect.origin.x = floorf((scrollRect.size.width - rect.size.width) / 2.0);
	} else {
		rect.origin.x = 0;
	}
	if (rect.size.height < scrollRect.size.height) {
		rect.origin.y = floorf((scrollRect.size.height - rect.size.height) / 2.0);
	} else {
		rect.origin.y = 0;
	}
	self.imageView.frame = rect;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	[self setNeedsLayout];
	[self layoutIfNeeded];
}

//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//
//}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {

}
//
//- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
//
//}

@end
