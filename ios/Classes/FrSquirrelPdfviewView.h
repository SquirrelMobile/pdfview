/**
 * pdfview
 *
 * Created by Michael Gangolf
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "TiUIView.h"
#import <PDFKit/PDFKit.h>

@interface FrSquirrelPdfviewView : TiUIView <PDFViewDelegate> {
  @private
  PDFView *pdfView;
  NSURLSessionDataTask *downloadTask;
  NSInteger pageNumber;
  NSInteger lastReportedPage;
  NSInteger loadGeneration;
  CGFloat minZoom;
  CGFloat maxZoom;
  CGFloat midZoom;
  BOOL pageSnap;
  BOOL pageFling;
}

- (void)clear;

@end
