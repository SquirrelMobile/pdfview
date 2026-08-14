/**
 * pdfview
 *
 * Created by Michael Gangolf
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "TiUIView.h"
#import <PDFKit/PDFKit.h>

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
}

- (void)clear;

@end
