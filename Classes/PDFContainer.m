//
//  PDFContainer.m
//  Reader
//
//  Created by Integrum User on 11/15/10.
//  Copyright 2010 example.com. All rights reserved.
//

#import "PDFContainer.h"
#import "CGPDFDocument.h"

@implementation PDFContainer

@synthesize pages;

static PDFContainer *sharedPDF;

+(PDFContainer *)sharedPDF {
	@synchronized(self){
		if(!sharedPDF){
			[[PDFContainer alloc] init];
		}
	}
	return sharedPDF;
}

+(id) alloc {
	@synchronized(self) {
		NSAssert(sharedPDF == nil, @"Attempt to allocate second instance");
		sharedPDF = [super alloc];
	}
	return sharedPDF;
}

- (void)dealloc {
    CGPDFDocumentRelease(_PDFDocRef);
    [_fileURL release];
    [_password release];
    
    [super dealloc];
}

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

- (CGPDFPageRef)getPage:(NSInteger)pageNumber {
    if (pageNumber < 1) pageNumber = 1; // Check the lower page bounds
    if (pageNumber > pages) pageNumber = pages; // Check the upper page bounds

    CGPDFPageRef newPDFPageRef = CGPDFDocumentGetPage(_PDFDocRef, pageNumber);
    
    if (newPDFPageRef == NULL) // Check for non-NULL CGPDFPageRef
    {
        NSAssert(NO, @"CGPDFPageRef == NULL");
    }

    return newPDFPageRef;
}

@end
