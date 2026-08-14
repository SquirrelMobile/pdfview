/**
 * pdfview
 *
 * Created by Michael Gangolf
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "FrSquirrelPdfviewViewProxy.h"
#import "FrSquirrelPdfviewView.h"
#import "TiBase.h"
#import "TiUtils.h"

@implementation FrSquirrelPdfviewViewProxy

- (TiDimension)defaultAutoWidthBehavior:(id)unused
{
  return TiDimensionAutoFill;
}

- (TiDimension)defaultAutoHeightBehavior:(id)unused
{
  return TiDimensionAutoFill;
}

- (void)clear:(id)unused
{
  [self replaceValue:nil forKey:@"url" notification:NO];
  [self replaceValue:nil forKey:@"file" notification:NO];
  TiThreadPerformOnMainThread(
      ^{
        if ([self viewAttached]) {
          [(FrSquirrelPdfviewView *)[self view] clear];
        }
      },
      NO);
}

@end
