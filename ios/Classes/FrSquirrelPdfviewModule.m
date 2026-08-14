/**
 * pdfview
 *
 * Created by Michael Gangolf
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "FrSquirrelPdfviewModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation FrSquirrelPdfviewModule

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"1705937f-0095-415f-a473-8c8b9a95651c";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"fr.squirrel.pdfview";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
  DebugLog(@"[DEBUG] %@ loaded", self);
}

@end
