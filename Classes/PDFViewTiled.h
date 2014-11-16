//
//	PDFViewTiled.h
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

#import <UIKit/UIKit.h>

@interface PDFViewTiled : UIView
{
@private // Instance variables
	CGPDFPageRef _PDFPageRef;
}

@property (nonatomic, assign) size_t page;

- (id)initWithPage:(size_t)onPage frame:(CGRect)frame;
- (void)recycleForPage:(size_t)onPage frame:(CGRect)frame;

- (void)willRotate;
- (void)didRotate;
- (void)willRecycle;

@end
