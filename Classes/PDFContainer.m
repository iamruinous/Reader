//
//  PDFContainer.m
//  Reader
//
//  Created by Integrum User on 11/15/10.
//  Copyright 2010 example.com. All rights reserved.
//

#import "PDFContainer.h"
#import "CGPDFDocument.h"


// Updated singleton based on
// rev. 3 at http://stackoverflow.com/questions/145154/what-does-your-objective-c-singleton-look-like/145403#145403

static PDFContainer *sharedPDF = nil;

@implementation PDFContainer

@synthesize pages;

#pragma mark -
#pragma mark class instance methods

- (BOOL)changeFileURL:(NSURL *)fileURL password:(NSString *)password
{
	BOOL status = NO;
    
	if (fileURL != nil) // Check for non-nil file URL
	{        
        if (_fileURL)
            [_fileURL release]; 
        
        if (_password)
            [_password release]; 
        
        _fileURL = [fileURL copy]; // Keep a copy
        _password = [password copy]; // Ditto
		
        CGPDFDocumentRelease(_PDFDocRef);
        
		_PDFDocRef = CGPDFDocumentCreateX((CFURLRef)fileURL, password);
        
		if (_PDFDocRef != NULL) // Check for non-NULL CGPDFDocRef
		{
			pages = CGPDFDocumentGetNumberOfPages(_PDFDocRef); // Set the total page count
#ifdef DEBUG
			NSLog(@"CGPDFDocumentGetNumberOfPages: %u", pages);
#endif
		}
		else // Error out with a diagnostic
		{
			NSAssert(NO, @"CGPDFDocRef == NULL");
		}
	}
	else // Error out with a diagnostic
	{
		NSAssert(NO, @"fileURL == nil");
	}
    
	return status;
}

- (CGPDFPageRef)getPage:(size_t)pageNumber {
#ifdef DEBUG
	NSLog(@"getPage: %u", pageNumber);
#endif
    if (pageNumber < 1) pageNumber = 1; // Check the lower page bounds
    if (pageNumber > pages) pageNumber = pages; // Check the upper page bounds
	
    CGPDFPageRef newPDFPageRef = CGPDFDocumentGetPage(_PDFDocRef, pageNumber);
    
    if (newPDFPageRef == NULL) // Check for non-NULL CGPDFPageRef
    {
        NSAssert(NO, @"CGPDFPageRef == NULL");
    }
	
    return newPDFPageRef;
}

#pragma mark -
#pragma mark Singleton methods

+ (PDFContainer*)sharedPDF
{
    @synchronized(self)
    {
        if (sharedPDF == nil)
            sharedPDF = [[PDFContainer alloc] init];
    }
    return sharedPDF;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedPDF == nil) {
            sharedPDF = [super allocWithZone:zone];
            return sharedPDF;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

@end
