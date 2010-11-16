//
//  ReaderPDFContainer.h
//  Reader
//
//  Created by Integrum User on 11/15/10.
//  Copyright 2010 example.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ReaderPDFContainer : NSObject {
	NSURL *_fileURL;
	NSString *_password;
	CGPDFDocumentRef _PDFDocRef;
}

@property (nonatomic, readonly) NSInteger pages;

- (BOOL)changeFileURL:(NSURL *)fileURL password:(NSString *)password;


@end
