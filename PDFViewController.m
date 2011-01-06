    //
//  PDFViewController.m
//  Reader
//
//  Created by Jade Meskill on 11/15/10.
//  Copyright 2010 example.com. All rights reserved.
//

#import "PDFViewController.h"
#import "PDFViewTiled.h"
#import "PDFScrollView.h"
#import "PDFContainer.h"

@implementation PDFViewController

@synthesize pagingScrollView;

#define ZOOM_AMOUNT 0.25f
#define NO_ZOOM_SCALE 1.0f
#define MINIMUM_ZOOM_SCALE 1.0f
#define MAXIMUM_ZOOM_SCALE 5.0f

#define NAV_AREA_SIZE 48.0f


 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)initPDFScroll {
    
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    pagingScrollView.pagingEnabled = YES;
    pagingScrollView.backgroundColor = [UIColor grayColor];
    pagingScrollView.showsVerticalScrollIndicator = NO;
    pagingScrollView.showsHorizontalScrollIndicator = NO;
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pagingScrollView.delegate = self;
    
    [self.view addSubview:self.pagingScrollView];
    
    // Step 2: prepare to tile content
    recycledPages = [[NSMutableSet alloc] init];
    visiblePages  = [[NSMutableSet alloc] init];
    [self tilePages];
}

- (PDFScrollView *)dequeueRecycledPage
{
    PDFScrollView *page = [recycledPages anyObject];
    if (page) {
        [[page retain] autorelease];
        [recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(size_t)index
{
    BOOL foundPage = NO;
    for (PDFScrollView *page in visiblePages) {
        if (page.index - 1 == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (PDFScrollView *)currentlyDisplayedPage {
    for (PDFScrollView *page in visiblePages) {
        return page;
        break;
    }
    return nil;
}

#pragma mark -
#pragma mark ScrollView delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tilePages];
}


#pragma mark -
#pragma mark View controller rotation methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
    // place to calculate the content offset that we will need in the new orientation
//    CGFloat offset = pagingScrollView.contentOffset.x;
//    CGFloat pageWidth = pagingScrollView.bounds.size.width;
//    
//    if (offset >= 0) {
//        firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
//        percentScrolledIntoFirstVisiblePage = (offset - (firstVisiblePageIndexBeforeRotation * pageWidth)) / pageWidth;
//    } else {
//        firstVisiblePageIndexBeforeRotation = 0;
//        percentScrolledIntoFirstVisiblePage = offset / pageWidth;
//    }    
    
	self.pagingScrollView.zoomScale = NO_ZOOM_SCALE;
    
	[[self currentlyDisplayedPage] willRotate];    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // recalculate contentSize based on current orientation
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
//    // adjust frames and configuration of each visible page
    for (PDFScrollView *page in visiblePages) {
//        CGPoint restorePoint = [page pointToCenterAfterRotation];
//        CGFloat restoreScale = [page scaleToRestoreAfterRotation];
        page.frame = [self frameForPageAtIndex:page.index - 1];
//        page.zoomScale = 1.0;
//        [page restoreCenterPoint:restorePoint scale:restoreScale];
    }

    for (PDFScrollView *page in recycledPages) {
        page.frame = [self frameForPageAtIndex:page.index - 1];
    }

    //    
//    // adjust contentOffset to preserve page location based on values collected prior to location
//    CGFloat pageWidth = pagingScrollView.bounds.size.width;
//    CGFloat newOffset = (firstVisiblePageIndexBeforeRotation * pageWidth) + (percentScrolledIntoFirstVisiblePage * pageWidth);
//    pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#ifdef DEBUG
	NSLog(@"ReaderViewController.m -didRotateFromInterfaceOrientation: [%d] to [%d]", fromInterfaceOrientation, self.interfaceOrientation);
	NSLog(@" -> self.view.bounds = %@", NSStringFromCGRect(self.view.bounds));
#endif
    // recalculate contentSize based on current orientation
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
	[[self currentlyDisplayedPage] didRotate];
}



- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [pagingScrollView release]; pagingScrollView = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Tiling and page configuration

- (void)tilePages 
{
    // Calculate which pages are visible
    CGRect visibleBounds = pagingScrollView.bounds;
    size_t firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    size_t lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self pageCount] - 1);
    
    // Recycle no-longer-visible pages 
    for (PDFScrollView *page in visiblePages) {
        if (page.index - 1 < firstNeededPageIndex || page.index - 1 > lastNeededPageIndex) {
#ifdef DEBUG
			NSLog(@"firstNeededPageIndex: %u, lastNeededPageIndex: %u, recycling: %u", firstNeededPageIndex, lastNeededPageIndex, page.index-1);
#endif
			[page willRecycle];
            [recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [visiblePages minusSet:recycledPages];
    
    // add missing pages
    for (size_t index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            PDFScrollView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[[PDFScrollView alloc] initWithPage:index + 1 frame:[self frameForPageAtIndex:index]] autorelease];
            } else {
				// We've a recycled page, so lets point it at page index+1 and update its frame ...
				[page recycleForPage:index + 1 frame:[self frameForPageAtIndex:index]];
			}

            page.zoomScale = 1.0;
            [pagingScrollView addSubview:page];
            //[self setMaxMinZoomScalesForCurrentBounds];
            [visiblePages addObject:page];
        }
    }    
}

#pragma mark -
#pragma mark  Frame calculations
#define PADDING  10

- (CGRect)frameForPagingScrollView {
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(size_t)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
#ifdef DEBUG
	NSLog(@"frameForPageAtIndex: %u", index);
#endif
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self pageCount], bounds.size.height);
}

- (size_t)pageCount {
   return [[PDFContainer sharedPDF] pages];
}


@end
