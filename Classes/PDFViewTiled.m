//
//	PDFViewTiled.m
//	Reader
//
//	Created by Julius Oklamcak on 2010-09-01.
//	Copyright © 2010 Julius Oklamcak. All rights reserved.
//
//	This work is being made available under a Creative Commons Attribution license:
//		«http://creativecommons.org/licenses/by/3.0/»
//	You are free to use this work and any derivatives of this work in personal and/or
//	commercial products and projects as long as the above copyright is maintained and
//	the original author is attributed.
//

#import "PDFViewTiled.h"
#import "PDFTiledLayer.h"
#import "CGPDFDocument.h"
#import "PDFContainer.h"

@implementation PDFViewTiled

#pragma mark Properties

@synthesize page;

#pragma mark Constants

#define ZOOM_AMOUNT 0.25f
#define NO_ZOOM_SCALE 1.0f
#define MINIMUM_ZOOM_SCALE 1.0f
#define MAXIMUM_ZOOM_SCALE 5.0f

#define NAV_AREA_SIZE 48.0f


#pragma mark PDFViewTiled Class methods

+ (Class)layerClass
{
	return [PDFTiledLayer class];
}

#pragma mark PDFViewTiled Instance methods

- (id)initWithPage:(NSInteger)onPage frame:(CGRect)frame {
    if (self = [self initWithFrame:frame])
    {
        page = onPage;
        _PDFPageRef = [[PDFContainer sharedPDF] getPage:onPage];

        if (_PDFPageRef != NULL) // Check for non-NULL CGPDFPageRef
        {
            CGPDFPageRetain(_PDFPageRef); // Retain the PDF page
        }
        else // Error out with a diagnostic
        {
            NSAssert(NO, @"CGPDFPageRef == NULL");
        }

    }

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    return self;
}

- (void)willRotate
{
	self.layer.hidden = YES;

	self.layer.contents = nil;
}

- (void)didRotate
{
	[self.layer setNeedsDisplay];

	self.layer.hidden = NO;
}

- (void)dealloc
{
	CGPDFPageRelease(_PDFPageRef);

	[super dealloc];
}

#pragma mark CATiledLayer Delegate methods

- (void)drawLayer:(CATiledLayer *)layer inContext:(CGContextRef)context
{
	CGPDFPageRef drawPDFPageRef = NULL;

	@synchronized(self) // Briefly block main thread
	{
		drawPDFPageRef = CGPDFPageRetain(_PDFPageRef);
	}

	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextFillRect(context, CGContextGetClipBoundingBox(context));

	if (drawPDFPageRef != NULL) // Render the page into the context
	{
		CGFloat boundsHeight = self.bounds.size.height;

		if (CGPDFPageGetRotationAngle(drawPDFPageRef) == 0)
		{
			CGFloat boundsWidth = self.bounds.size.width;

			CGRect cropBoxRect = CGPDFPageGetBoxRect(drawPDFPageRef, kCGPDFCropBox);
			CGRect mediaBoxRect = CGPDFPageGetBoxRect(drawPDFPageRef, kCGPDFMediaBox);
			CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);

			CGFloat effectiveWidth = effectiveRect.size.width;
			CGFloat effectiveHeight = effectiveRect.size.height;

			CGFloat widthScale = (boundsWidth / effectiveWidth);
			CGFloat heightScale = (boundsHeight / effectiveHeight);

			CGFloat scale = (widthScale < heightScale) ? widthScale : heightScale;

			CGFloat x_offset = ((boundsWidth - (effectiveWidth * scale)) / 2.0f);
			CGFloat y_offset = ((boundsHeight - (effectiveHeight * scale)) / 2.0f);

			y_offset = (boundsHeight - y_offset); // Co-ordinate system adjust

			CGFloat x_translate = (x_offset - effectiveRect.origin.x);
			CGFloat y_translate = (y_offset + effectiveRect.origin.y);

			CGContextTranslateCTM(context, x_translate, y_translate);

			CGContextScaleCTM(context, scale, -scale); // Mirror Y
		}
		else // Use CGPDFPageGetDrawingTransform for pages with rotation (AKA kludge)
		{
			CGContextTranslateCTM(context, 0.0f, boundsHeight); CGContextScaleCTM(context, 1.0f, -1.0f);

			CGContextConcatCTM(context, CGPDFPageGetDrawingTransform(drawPDFPageRef, kCGPDFCropBox, self.bounds, 0, true));
		}

		CGContextDrawPDFPage(context, drawPDFPageRef);
	}

	CGPDFPageRelease(drawPDFPageRef); // Cleanup
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self;
}



@end
