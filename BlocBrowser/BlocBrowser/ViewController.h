//
//  ViewController.h
//  BlocBrowser
//
//  Created by Chad Clayton on 7/21/15.
//  Copyright (c) 2015 Chad Clayton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

/**
 Replaces the web view with a fresh one, erasing all history. Also updates the URL field and toolbar buttons appropriately
 */
- (void)resetWebView;
- (void) welcomeMessageSplash ;

@end

