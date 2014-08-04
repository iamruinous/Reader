//
//  PDFViewController.h
//  Reader
//
//  Created by Jade Meskill on 11/15/10.
//  Copyright 2010 example.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PDFScrollView;

@interface PDFViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    UIScrollView *pagingScrollView;

    NSMutableSet *recycledPages;
    NSMutableSet *visiblePages;

    // these values are stored off before we start rotation so we adjust our content offset appropriately during rotation
    int           firstVisiblePageIndexBeforeRotation;
    CGFloat       percentScrolledIntoFirstVisiblePage;
}

@property (nonatomic, retain) UIScrollView *pagingScrollView;

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;

- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;

- (void)tilePages;
- (PDFScrollView *)dequeueRecycledPage;

- (NSInteger)pageCount;

- (PDFScrollView *)currentlyDisplayedPage;

- (void)initPDFScroll;

@end
