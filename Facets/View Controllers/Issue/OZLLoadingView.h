//
//  OZLLoadingView.h
//  Facets
//
//  Created by Justin Hill on 11/10/15.
//  Copyright © 2015 Justin Hill. All rights reserved.
//

#import "OZLView.h"
#import <DRPLoadingSpinner/DRPLoadingSpinner.h>

@interface OZLLoadingView : OZLView

- (void)startLoading;
- (void)endLoading;
- (void)endLoadingWithErrorMessage:(NSString *)errorMessage;

@end
