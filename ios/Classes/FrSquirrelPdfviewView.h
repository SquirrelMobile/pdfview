/**
 * pdfview
 *
 * Created by Michael Gangolf
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "TiUIView.h"
#import <PDFKit/PDFKit.h>

typedef NS_ENUM(NSInteger, FrSquirrelPdfviewFitPolicy) {
  FrSquirrelPdfviewFitPolicyWidth = 0,
  FrSquirrelPdfviewFitPolicyHeight,
  FrSquirrelPdfviewFitPolicyBoth
};

@interface FrSquirrelPdfviewView : TiUIView <PDFViewDelegate, UIGestureRecognizerDelegate> {
  @private
  PDFView *pdfView;
  UILongPressGestureRecognizer *pdfLongPressRecognizer;
  NSURLSessionDataTask *downloadTask;
  NSInteger pageNumber;
  NSInteger lastReportedPage;
  NSInteger loadGeneration;
  CGFloat minZoom;
  CGFloat maxZoom;
  CGFloat midZoom;
  BOOL pageSnap;
  BOOL pageFling;
  BOOL textSelection;
  FrSquirrelPdfviewFitPolicy fitPolicy;
  // scale that the current fitPolicy resolved to for the current view size,
  // 0 while PDFKit's own autoScales (fitPolicy "width") is in charge
  CGFloat currentFitScale;
  // largest page size of the loaded document, used by the height/both fits
  CGSize largestPageSize;
}

- (void)clear;
- (NSUInteger)pageCount;

@end
