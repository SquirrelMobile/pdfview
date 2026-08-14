/**
 * pdfview
 *
 * Created by Michael Gangolf
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "FrSquirrelPdfviewView.h"
#import "TiBase.h"
#import "TiBlob.h"
#import "TiFile.h"
#import "TiUtils.h"

@implementation FrSquirrelPdfviewView

#pragma mark Internal

- (instancetype)init
{
  if (self = [super init]) {
    pageNumber = 0;
    lastReportedPage = -1;
    minZoom = 1.0;
    maxZoom = 3.0;
    midZoom = 1.75;
    pageSnap = NO;
    pageFling = NO;
    textSelection = NO;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [downloadTask cancel];
}

- (PDFView *)pdfView
{
  if (pdfView == nil) {
    pdfView = [[PDFView alloc] initWithFrame:[self bounds]];
    pdfView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pdfView.autoScales = YES;
    pdfView.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pageChangedNotification:)
                                                 name:PDFViewPageChangedNotification
                                               object:pdfView];
    // the PDFView is recreated per document, so the recognizer is re-attached here
    pdfLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
    pdfLongPressRecognizer.cancelsTouchesInView = NO;
    pdfLongPressRecognizer.delegate = self;
    [pdfView addGestureRecognizer:pdfLongPressRecognizer];
    [self addSubview:pdfView];
    // the PDFView is recreated for every document (see showDocument:), so the
    // configuration has to be re-applied from the proxy properties each time
    id spacing = [[self proxy] valueForKey:@"spacing"];
    if (spacing != nil && ![spacing isKindOfClass:[NSNull class]]) {
      [self setSpacing_:spacing];
    }
    id swipeHorizontal = [[self proxy] valueForKey:@"swipeHorizontal"];
    if (swipeHorizontal != nil && ![swipeHorizontal isKindOfClass:[NSNull class]]) {
      [self setSwipeHorizontal_:swipeHorizontal];
    }
    id nightMode = [[self proxy] valueForKey:@"nightMode"];
    if (nightMode != nil && ![nightMode isKindOfClass:[NSNull class]]) {
      [self setNightMode_:nightMode];
    }
    if (pageSnap || pageFling) {
      [self updatePageViewController];
    }
  }
  return pdfView;
}

- (void)removeLayerAnimations:(CALayer *)layer
{
  [layer removeAllAnimations];
  for (CALayer *sublayer in layer.sublayers) {
    [self removeLayerAnimations:sublayer];
  }
}

- (void)updateInteractions:(UIView *)view
{
  // PDFKit adds UIDragInteractions that start a drag-and-drop lift on
  // long-press; its preview code crashes with a NaN layer position when the
  // pressed page has not finished rendering (CALayerInvalidGeometry). Drag
  // out of the PDF is not a module feature, so turn the interactions off.
  for (id<UIInteraction> interaction in view.interactions) {
    if ([interaction isKindOfClass:[UIDragInteraction class]]) {
      ((UIDragInteraction *)interaction).enabled = NO;
    }
  }
  // PDFKit selects text through its own long-press (and "tap and a half")
  // recognizers, which swallow the touch before the module's longpress
  // recognizer sees it. Keep them in the state the textSelection property asks
  // for; the module's own recognizer must stay untouched.
  for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
    if (recognizer == pdfLongPressRecognizer) {
      continue;
    }
    if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]
        || [NSStringFromClass([recognizer class]) containsString:@"TapAndAHalf"]) {
      recognizer.enabled = textSelection;
    }
  }
  for (UIView *subview in view.subviews) {
    [self updateInteractions:subview];
  }
}

- (void)destroyPdfView
{
  if (pdfView == nil) {
    return;
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFViewPageChangedNotification object:pdfView];
  pdfView.delegate = nil;
  pdfView.document = nil;
  [pdfView removeFromSuperview];
  pdfView = nil;
  pdfLongPressRecognizer = nil;
}

- (void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
  [super frameSizeChanged:frame bounds:bounds];
  if (pdfView != nil) {
    [TiUtils setView:pdfView positionRect:bounds];
    [self applyZoomLimits];
  }
}

#pragma mark Document loading

- (void)fireErrorWithMessage:(NSString *)message passwordError:(BOOL)passwordError
{
  NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObject:(message ?: @"Unknown error") forKey:@"message"];
  if (passwordError) {
    [event setObject:NUMBOOL(YES) forKey:@"passwordError"];
  }
  [self.proxy fireEvent:@"error" withObject:event];
}

- (void)setUrl_:(id)value
{
  NSString *url = [TiUtils stringValue:value];
  if (url == nil || url.length == 0) {
    return;
  }
  NSURL *fullUrl = [TiUtils toURL:url proxy:self.proxy];
  if (fullUrl == nil) {
    [self fireErrorWithMessage:[NSString stringWithFormat:@"Invalid url \"%@\"", url] passwordError:NO];
    return;
  }
  if ([fullUrl isFileURL]) {
    [self loadDocumentWithData:[NSData dataWithContentsOfURL:fullUrl]];
    return;
  }
  [downloadTask cancel];
  __weak FrSquirrelPdfviewView *weakSelf = self;
  downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:fullUrl
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 FrSquirrelPdfviewView *strongSelf = weakSelf;
                                                 if (strongSelf == nil) {
                                                   return;
                                                 }
                                                 if (error != nil) {
                                                   if (error.code != NSURLErrorCancelled) {
                                                     [strongSelf fireErrorWithMessage:error.localizedDescription passwordError:NO];
                                                   }
                                                   return;
                                                 }
                                                 if ([response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse *)response statusCode] >= 400) {
                                                   [strongSelf fireErrorWithMessage:[NSString stringWithFormat:@"Received HTTP status %li", (long)[(NSHTTPURLResponse *)response statusCode]]
                                                                      passwordError:NO];
                                                   return;
                                                 }
                                                 [strongSelf loadDocumentWithData:data];
                                               });
                                             }];
  [downloadTask resume];
}

- (void)setFile_:(id)value
{
  if (value == nil || value == [NSNull null]) {
    return;
  }
  if ([value isKindOfClass:[TiBlob class]]) {
    [self loadDocumentWithData:[(TiBlob *)value data]];
  } else if ([value isKindOfClass:[TiFile class]]) {
    [self loadDocumentWithData:[NSData dataWithContentsOfFile:[(TiFile *)value path]]];
  } else if ([value isKindOfClass:[NSString class]]) {
    NSURL *fileUrl = [TiUtils toURL:value proxy:self.proxy];
    [self loadDocumentWithData:(fileUrl != nil ? [NSData dataWithContentsOfURL:fileUrl] : nil)];
  } else {
    [self fireErrorWithMessage:@"Unsupported \"file\" value: pass a Ti.Filesystem.File or a Ti.Blob" passwordError:NO];
  }
}

- (void)loadDocumentWithData:(NSData *)data
{
  if (data == nil) {
    [self fireErrorWithMessage:@"Could not read PDF data" passwordError:NO];
    return;
  }
  [self showDocument:[[PDFDocument alloc] initWithData:data]];
}

- (void)showDocument:(PDFDocument *)document
{
  if (document == nil) {
    [self fireErrorWithMessage:@"Could not open PDF document" passwordError:NO];
    return;
  }
  if (document.isLocked || document.isEncrypted) {
    // like on Android, the password is read at load time so property order does not matter
    NSString *password = [TiUtils stringValue:[self.proxy valueForKey:@"password"]];
    if (![document unlockWithPassword:(password ?: @"")]) {
      [self fireErrorWithMessage:@"The document is password protected" passwordError:YES];
      return;
    }
  }
  lastReportedPage = -1;
  NSInteger generation = ++loadGeneration;
  // PDFKit caches rendered pages (especially in page-view-controller mode used
  // for pageSnap/pageFling) and animates document swaps. Rebuilding the PDFView
  // for every document - like recycle() in the Android library - avoids stale
  // pages when switching documents.
  [self destroyPdfView];
  PDFView *view = [self pdfView];
  // In page-view-controller mode PDFKit lays out and animates the first page
  // into place asynchronously and offers no way to turn that off. Keep the
  // view invisible until that has settled, then reveal it in its final state.
  view.alpha = 0.0;
  view.document = document;
  [view layoutDocumentView];
  [self updateInteractions:view];
  [self applyZoomLimits];
  [self goToPage:pageNumber];
  [self reportPageChange];
  dispatch_async(dispatch_get_main_queue(), ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      if (generation != self->loadGeneration || self->pdfView == nil) {
        // a newer load or clear() took over in the meantime
        return;
      }
      // layout is final now: re-apply fit and page position without animation,
      // kill any animation PDFKit has still in flight and only then reveal
      [self applyZoomLimits];
      [self goToPage:self->pageNumber];
      [self removeLayerAnimations:self->pdfView.layer];
      [self updateInteractions:self->pdfView];
      self->pdfView.alpha = 1.0;
    });
  });
}

- (void)clear
{
  [downloadTask cancel];
  downloadTask = nil;
  lastReportedPage = -1;
  // destroy the PDFView instead of only removing the document: in
  // page-view-controller mode PDFKit would keep showing the cached page
  [self destroyPdfView];
}

#pragma mark Zoom / paging helpers

- (void)applyZoomLimits
{
  if (pdfView == nil || pdfView.document == nil) {
    return;
  }
  // minZoom/maxZoom are relative to the "fit to view" scale, like on Android
  CGFloat fitScale = [pdfView scaleFactorForSizeToFit];
  if (fitScale <= 0) {
    return;
  }
  pdfView.minScaleFactor = fitScale * minZoom;
  pdfView.maxScaleFactor = fitScale * maxZoom;
  if (pdfView.scaleFactor < pdfView.minScaleFactor) {
    pdfView.scaleFactor = pdfView.minScaleFactor;
  } else if (pdfView.scaleFactor > pdfView.maxScaleFactor) {
    pdfView.scaleFactor = pdfView.maxScaleFactor;
  }
}

- (void)goToPage:(NSInteger)page
{
  PDFDocument *document = pdfView.document;
  if (document == nil || document.pageCount == 0) {
    return;
  }
  NSInteger index = MAX(0, MIN(page, (NSInteger)document.pageCount - 1));
  PDFPage *pdfPage = [document pageAtIndex:index];
  if (pdfPage == nil) {
    return;
  }
  // no animation, like jumpTo(page, false) on Android
  [UIView performWithoutAnimation:^{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self->pdfView goToPage:pdfPage];
    [CATransaction commit];
  }];
}

- (void)updatePageViewController
{
  [[self pdfView] usePageViewController:(pageSnap || pageFling) withViewOptions:nil];
}

#pragma mark Public properties

- (void)setPageNumber_:(id)value
{
  pageNumber = [TiUtils intValue:value def:0];
  [self goToPage:pageNumber];
}

- (void)setSpacing_:(id)value
{
  CGFloat spacing = [TiUtils floatValue:value def:0];
  PDFView *view = [self pdfView];
  view.pageBreakMargins = UIEdgeInsetsMake(spacing / 2.0, 0, spacing / 2.0, 0);
  [view layoutDocumentView];
}

- (void)setMinZoom_:(id)value
{
  minZoom = [TiUtils floatValue:value def:1.0];
  [self applyZoomLimits];
}

- (void)setMaxZoom_:(id)value
{
  maxZoom = [TiUtils floatValue:value def:3.0];
  [self applyZoomLimits];
}

- (void)setMidZoom_:(id)value
{
  // Android double-tap zoom step; PDFKit has no equivalent, accepted for parity
  midZoom = [TiUtils floatValue:value def:1.75];
}

- (void)setPassword_:(id)value
{
  // read at load time, see showDocument:
}

- (void)setNightMode_:(id)value
{
  // PDFKit cannot invert page content; darken the background as an approximation
  [self pdfView].backgroundColor = [TiUtils boolValue:value def:NO] ? [UIColor blackColor] : [UIColor systemGray5Color];
}

- (void)setPageSnap_:(id)value
{
  pageSnap = [TiUtils boolValue:value def:NO];
  [self updatePageViewController];
}

- (void)setPageFling_:(id)value
{
  pageFling = [TiUtils boolValue:value def:NO];
  [self updatePageViewController];
}

- (void)setSwipeHorizontal_:(id)value
{
  PDFView *view = [self pdfView];
  view.displayDirection = [TiUtils boolValue:value def:NO] ? kPDFDisplayDirectionHorizontal : kPDFDisplayDirectionVertical;
  [view layoutDocumentView];
}

- (void)setNestedScrolling_:(id)value
{
  // Android-only property, accepted for parity
}

- (void)setTextSelection_:(id)value
{
  textSelection = [TiUtils boolValue:value def:NO];
  if (pdfView != nil) {
    [self updateInteractions:pdfView];
  }
}

#pragma mark Events

- (void)pageChangedNotification:(NSNotification *)notification
{
  // in page-view-controller mode PDFKit creates new page views (with their
  // own drag interactions and selection recognizers) while paging, so sweep
  // again on every page change
  [self updateInteractions:pdfView];
  [self reportPageChange];
}

- (void)reportPageChange
{
  PDFDocument *document = pdfView.document;
  PDFPage *currentPage = pdfView.currentPage;
  if (document == nil || currentPage == nil) {
    return;
  }
  NSUInteger index = [document indexForPage:currentPage];
  if (index == NSNotFound || (NSInteger)index == lastReportedPage) {
    return;
  }
  lastReportedPage = (NSInteger)index;
  pageNumber = (NSInteger)index;
  [self.proxy replaceValue:NUMUINTEGER(index) forKey:@"pageNumber" notification:NO];
  if ([self.proxy _hasListeners:@"pageChanged"]) {
    [self.proxy fireEvent:@"pageChanged"
               withObject:@{
                 @"currentPage" : NUMUINTEGER(index),
                 @"pageCount" : NUMUINTEGER(document.pageCount)
               }];
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithOtherGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  // PDFKit installs its own recognizers (text selection etc.); ours must not block them
  return YES;
}

- (void)longPressDetected:(UILongPressGestureRecognizer *)recognizer
{
  if (recognizer.state != UIGestureRecognizerStateBegan) {
    return;
  }
  if ([self.proxy _hasListeners:@"longpress"]) {
    CGPoint point = [recognizer locationInView:self];
    NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
      @"x" : NUMFLOAT(point.x),
      @"y" : NUMFLOAT(point.y)
    }];
    NSString *url = [self linkAtPoint:[recognizer locationInView:pdfView]];
    if (url != nil) {
      [event setObject:url forKey:@"url"];
    }
    [self.proxy fireEvent:@"longpress" withObject:event];
  }
}

- (NSString *)linkAtPoint:(CGPoint)point
{
  PDFPage *page = [pdfView pageForPoint:point nearest:NO];
  if (page == nil) {
    return nil;
  }
  CGPoint pagePoint = [pdfView convertPoint:point toPage:page];
  PDFAnnotation *annotation = [page annotationAtPoint:pagePoint];
  if (annotation == nil) {
    return nil;
  }
  NSURL *url = annotation.URL;
  if (url == nil && [annotation.action isKindOfClass:[PDFActionURL class]]) {
    url = [(PDFActionURL *)annotation.action URL];
  }
  return [url absoluteString];
}

- (void)PDFViewWillClickOnLink:(PDFView *)sender withURL:(NSURL *)url
{
  // like on Android the link is reported but not opened automatically
  if ([self.proxy _hasListeners:@"link"]) {
    [self.proxy fireEvent:@"link" withObject:@{ @"url" : [url absoluteString] }];
  }
}

@end
