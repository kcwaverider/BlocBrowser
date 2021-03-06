//
//  ViewController.m
//  BlocBrowser
//
//  Created by Chad Clayton on 7/21/15.
//  Copyright (c) 2015 Chad Clayton. All rights reserved.
//

#import "ViewController.h"
#import "AwesomeFloatingToolbar.h"
#import <WebKit/WebKit.h>

#define kWebBrowserBackString NSLocalizedString(@"Back", @"Back Command")
#define kWebBrowserForwardString NSLocalizedString(@"Forward", @"Forward Command")
#define kWebBrowserStopString NSLocalizedString(@"Stop", @"Stop Command")
#define kWebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload Command")


@interface ViewController () <WKNavigationDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) AwesomeFloatingToolbar *awesomeToolbar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation ViewController

CGFloat toolbarWidth = 280;
CGFloat toolbarHeight = 60;
CGFloat toolbarXLocation = 20;
CGFloat toolbarYLocation = 100;
CGFloat toolbarXRatio;
CGFloat toolbarYRatio;
BOOL flag = YES;




#pragma mark - UIViewController

- (void)loadView {
    UIView *mainView = [UIView new];
    self.webView = [WKWebView new];
    self.webView.navigationDelegate = self;
    
    [self welcomeMessageSplash];
    
    self.textField = [UITextField new];
    self.textField.keyboardType = UIKeyboardTypeWebSearch;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL or Search Term", @"Placeholder text for web browser URL field or a search term");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;
    
    self.awesomeToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[kWebBrowserBackString, kWebBrowserForwardString, kWebBrowserStopString, kWebBrowserRefreshString]];
    self.awesomeToolbar.delegate = self;
    
    
    
    
    for (UIView *viewToAdd in @[self.webView, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.view = mainView;
    //[self calculateToolbarRatios];
    
    // Set the starting point for the toolbar
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];

    
}

-(void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // First calculate some dimensions
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) -  itemHeight;
    

    
    
    
    // Now assign the frames
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    if (flag) {
        toolbarXRatio = toolbarXLocation / CGRectGetWidth(self.webView.frame);
        toolbarYRatio = toolbarYLocation / CGRectGetHeight(self.webView.frame);
        flag = NO;
    }
    
    self.awesomeToolbar.frame = CGRectMake(toolbarXRatio * CGRectGetWidth(self.webView.frame), toolbarYRatio * CGRectGetHeight(self.webView.frame), toolbarWidth, toolbarHeight);
    // NSLog(@"Frame Height: %f", CGRectGetHeight(self.webView.frame));
    // NSLog(@"Y ratio: %f", toolbarYRatio);
    // NSLog(@"Y location: %f", self.awesomeToolbar.frame.origin.y);

}

#pragma mark - UITextFieldDelegate

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSMutableString *URLString = [textField.text mutableCopy];
    
    // Check to see if there are spaces
    NSRange firstSpaceCharacterRange = [URLString rangeOfString:@" "];
    NSRange dotCharacterRange = [URLString rangeOfString:@"."];
    
    if (firstSpaceCharacterRange.location != NSNotFound) {
        
        [URLString replaceOccurrencesOfString:@" " withString:@"+" options:NSLiteralSearch range:NSMakeRange(0,URLString.length)];
        NSMutableString *googleSearchURL = [@"http://www.google.com/search?q=" mutableCopy];
        [googleSearchURL appendString:[NSString stringWithString:URLString]];
        URLString = googleSearchURL;
    } else if (dotCharacterRange.location == NSNotFound) {
        NSMutableString *googleSearchURL = [@"http://www.google.com/search?q=" mutableCopy];
        [googleSearchURL appendString:[NSString stringWithString:URLString]];
        URLString = googleSearchURL;
    }
    
    NSURL *URL = [NSURL URLWithString:URLString];
    
    if (!URL.scheme) {
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
    }
    
    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webView loadRequest:request];
    }
    
    return NO;
}

#pragma mark - WKNavigationDelegate


- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self updateButtonsAndTitle];
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self updateButtonsAndTitle];
}

- (void) webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *) navigation withError:(NSError *)error {
    
    [self webView:webView didFailNavigation:navigation withError:error];
}

- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    
    if (error.code != NSURLErrorCancelled) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:okAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [self updateButtonsAndTitle];
}

#pragma mark - Miscelaneous

- (void) updateButtonsAndTitle {
    NSString *webpageTitle = [self.webView.title copy];
    if ([webpageTitle length]) {
        self.title = webpageTitle;
    } else {
        self.title = self.webView.URL.absoluteString;
    }
    
    if (self.webView.isLoading) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webView canGoBack] forButtonWithTitle:kWebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webView canGoForward] forButtonWithTitle:kWebBrowserForwardString];
    [self.awesomeToolbar setEnabled:[self.webView isLoading] forButtonWithTitle:kWebBrowserStopString];
    [self.awesomeToolbar setEnabled:![self.webView isLoading] forButtonWithTitle:kWebBrowserRefreshString];
    
}

- (void) resetWebView {
    [self.webView removeFromSuperview];
    
    WKWebView *newWebView = [WKWebView new];
    newWebView.navigationDelegate = self;
    [self.view addSubview:newWebView];
    
    self.webView = newWebView;
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}


- (void) welcomeMessageSplash {
    UIAlertController *welcomeMessage = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Welcome to BlocBrowser!", @"Welcome message") message:NSLocalizedString(@"The most PRIVATE browser on your phone", @"App description") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *messageAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Got It", nil) style:UIAlertActionStyleCancel handler:nil];
    
    [welcomeMessage addAction:messageAction];
    
    [self presentViewController:welcomeMessage animated:YES completion:nil];
}


#pragma mark - AwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(AwesomeFloatingToolbar *) toolbar didSelectButtonWithTitle:(NSString *)label {
    NSLog(@"Label: %@", label);
    if ([label isEqual: kWebBrowserBackString]) {
        [self.webView goBack];
    } else if ([label isEqual:kWebBrowserForwardString]) {
        [self.webView goForward];
    } else if ([label isEqual:kWebBrowserStopString]) {
        [self.webView stopLoading];
    } else if ([label isEqual:kWebBrowserRefreshString]) {
        [self.webView reload];
    }
}

 

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
        toolbarXLocation = potentialNewFrame.origin.x;
        toolbarYLocation = potentialNewFrame.origin.y;
        [self calculateToolbarRatios];
    }
}

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPinchWithScale:(CGFloat)scale {
    
    CGPoint pinchStartingPoint = toolbar.frame.origin;
    
    
    CGFloat startWidth = CGRectGetWidth(toolbar.frame);
    CGFloat startHeight = CGRectGetHeight(toolbar.frame);
   
    CGFloat newWidth = startWidth * scale;
    CGFloat newHeight = startHeight * scale;
    CGPoint newStartingPoint = CGPointMake(pinchStartingPoint.x + (startWidth - newWidth) /2 , pinchStartingPoint.y + (startHeight - newHeight) / 2);
    
    

    CGRect potentialNewFrame = CGRectMake(newStartingPoint.x , newStartingPoint.y, newWidth, newHeight);
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame) && newWidth >= (280 / 2) && newHeight >= (60 / 2)) {
        toolbar.frame = potentialNewFrame;
        toolbarXLocation = potentialNewFrame.origin.x;
        toolbarYLocation = potentialNewFrame.origin.y;
        toolbarWidth = potentialNewFrame.size.width;
        toolbarHeight = potentialNewFrame.size.height;
        [self calculateToolbarRatios];
    }
    NSLog(@"Toolbar origin - X: %f Y: %f", pinchStartingPoint.x, pinchStartingPoint.y);
    NSLog(@"Start width: %f", startWidth);
    NSLog(@"Scale: %f", scale);
    NSLog(@"New width: %f", newWidth);
}

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryLongPress:(CGPoint)location {
    
}

- (void) calculateToolbarRatios {
    toolbarXRatio = toolbarXLocation / CGRectGetWidth(self.webView.frame);
    toolbarYRatio = toolbarYLocation / CGRectGetHeight(self.webView.frame);
}



@end


















