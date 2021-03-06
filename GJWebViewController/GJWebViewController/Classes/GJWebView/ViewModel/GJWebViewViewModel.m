//
//  GJWebViewDelegate.m
//  GJWebViewController
//
//  Created by Alien on 16/7/13.
//  Copyright © 2016年 Alien. All rights reserved.
//

#import "GJWebViewViewModel.h"
#import "GJWebViewWorking.h"
#import "GJNJKWebViewProgress.h"
#import "GJWebViewBackListItem.h"


@interface GJWebViewViewModel()
<
UIWebViewDelegate,
GJ_NJKWebViewProgressDelegate,
GJ_NJK_UIWebViewDelegate,
UIGestureRecognizerDelegate
> {
    NSString *_gj_title;
}

@property (nonnull , nonatomic, readwrite, strong)UIWebView *webView;
@property (nonnull , nonatomic, readwrite, strong) GJNJKWebViewProgress *progressProxy;
@property (assign ,nonatomic ,readwrite)BOOL gj_webViewCanGoBack;
/**
 *  array that hold snapshots
 */
@property (nonnull , nonatomic, readwrite, strong)NSMutableArray <GJWebViewBackListItem *>* snapShotsArray;

/**
 *  current snapshotview displaying on screen when start swiping
 */
@property (nonnull , nonatomic, readwrite, strong)UIView* currentSnapShotView;

/**
 *  previous view
 */
@property (nonnull , nonatomic, readwrite, strong)UIView* prevSnapShotView;

/**
 *  background alpha black view
 */
@property (nonnull , nonatomic, readwrite, strong)UIView* swipingBackgoundView;
/**
 *  left pan ges
 */
@property (nonnull , nonatomic, readwrite, strong)UIPanGestureRecognizer* swipePanGesture;
/**
 *  if is swiping now
 */
@property (nonatomic, readwrite, assign)BOOL isSwipingBack;

@end

@implementation GJWebViewViewModel
@synthesize gj_title = _gj_title;
@synthesize gj_webViewCanGoBack = _gj_webViewCanGoBack;

- (instancetype)init {
    if (self = [super init]) {
        _webView = [[UIWebView alloc]initWithFrame:CGRectZero];
        [_webView addGestureRecognizer:self.swipePanGesture];
        //自动对页面进行缩放以适应屏幕
        _webView.scalesPageToFit = YES;
        //webview 不识别任何 电话 链接 等 详见 UIDataDetectorTypes
        _webView.dataDetectorTypes = UIDataDetectorTypeNone;
        
        _progressProxy = [[GJNJKWebViewProgress alloc]init];
        _webView.delegate = _progressProxy;
        _progressProxy.progressDelegate = self;
        _progressProxy.webViewProxyDelegate = self;
        
    }
    return self;
}



#pragma mark - NJKWebViewProgressDelegate
-(void)webViewProgress:(GJNJKWebViewProgress *)webViewProgress updateProgress:(float)progress {
    NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self setGj_title:title];
    !_progressBlock?:_progressBlock(_webView,progress);
}
#pragma mark - GJWebViewViewModelPortocol

- (void)setGj_title:(NSString *)title {
    
    if ([_gj_title isEqualToString:title]) {
        return;
    }
    [self willChangeValueForKey:@"gj_title"];
    _gj_title = [title copy];
    [self didChangeValueForKey:@"gj_title"];
    
}
- (void)gj_goBack {
    [self.webView stopLoading];
    [self.webView goBack];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self gj_webViewCanGoBack];
    });
}

/**
 *  webView是否可以回退到上一个页面
 */
- (BOOL)gj_webViewCanGoBack {
    BOOL hasURLStack = [self.webView canGoBack];
    if (hasURLStack  != _gj_webViewCanGoBack) {
        [self setGj_webViewCanGoBack:hasURLStack];
    }
    return _gj_webViewCanGoBack;
}

- (void)setGj_webViewCanGoBack:(BOOL)gj_webViewCanGoBack {
    if (_gj_webViewCanGoBack == gj_webViewCanGoBack) {
        return;
    }
    [self willChangeValueForKey:@"gj_webViewCanGoBack"];
    _gj_webViewCanGoBack = gj_webViewCanGoBack;
    [self didChangeValueForKey:@"gj_webViewCanGoBack"];
}

- (void)gj_loadRequest:(NSURLRequest *)request {
    [self.webView loadRequest:request];
}

- (void)gj_loadHTMLString:(NSString * _Nullable )string baseURL:(nullable NSURL *)baseURL {
    [self.webView loadHTMLString:string baseURL:baseURL];
}

- (void)gj_reload {
    [self.webView reload];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return !_shouldStartBlock? YES:_shouldStartBlock(webView,request ,gj_webViewnavigationTypeToGJNavigation(navigationType));;
    
}
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self setGj_webViewCanGoBack:[webView canGoBack]];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (self.prevSnapShotView.superview) {
        [self.prevSnapShotView removeFromSuperview];
    }
    !_didFinshLoadBlock?:_didFinshLoadBlock(webView , nil);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self setGj_webViewCanGoBack:[webView canGoBack]];
    !_didFinshLoadBlock?:_didFinshLoadBlock(webView , error);
    
}

- (void)webviewWillStartNewPageRequest:(NSURLRequest *)request navigationType:(GJWebNavigationType)navigationType {
    if (GJWKNavigationTypeOther == navigationType || GJWKNavigationTypeLinkActivated == navigationType) {
        [self pushCurrentSnapshotViewWithRequest:request];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self gj_webViewCanGoBack];
        });
    }
}
#pragma mark- popGestures
-(NSMutableArray*)snapShotsArray {
    if (!_snapShotsArray) {
        _snapShotsArray = [[NSMutableArray alloc]initWithCapacity:9];
    }
    return _snapShotsArray;
}
-(UIPanGestureRecognizer*)swipePanGesture {
    if (!_swipePanGesture) {
        _swipePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipePanGestureHandler:)];
        _swipePanGesture.maximumNumberOfTouches = 1;
        _swipePanGesture.delegate = self;
    }
    return _swipePanGesture;
}

-(void)swipePanGestureHandler:(UIPanGestureRecognizer*)panGesture {
    CGPoint translation = [panGesture translationInView:self.webView];
    if (panGesture.state == UIGestureRecognizerStateBegan) {//location.x <= 50 &&
        if ( translation.x >= 0) {  //开始动画
            [self startPopSnapshotView];
        }
    }else if (panGesture.state == UIGestureRecognizerStateCancelled || panGesture.state == UIGestureRecognizerStateEnded) {
        [self endPopSnapShotView];
        
    }else if (panGesture.state == UIGestureRecognizerStateChanged) {
        [self popSnapShotViewWithPanGestureDistance:translation.x];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    return [self gj_webViewCanGoBack];
}

#pragma mark - logic of push and pop snap shot views

-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest*)request {
    // NSLog(@"push with request %@",request);
    NSURLRequest* lastRequest = (NSURLRequest*)[[self.snapShotsArray lastObject]request];
    //如果url是很奇怪的就不push
    if (![request.URL.absoluteString hasPrefix:@"http"]) {
        return;
    }
    //如果url一样就不进行push
    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    
    UIView* currentSnapShotView = [self.webView snapshotViewAfterScreenUpdates:YES];
    
    GJWebViewBackListItem *item = [[GJWebViewBackListItem alloc]initWtihURL:request.URL
                                                                      title:nil
                                                               snapShotView:currentSnapShotView
                                                                    request:request];
    [self.snapShotsArray addObject:item];
    [self setGj_webViewCanGoBack:YES];
}

- (NSArray <GJWebViewBackListItemProtocol>*)gjBackList {
    return [_snapShotsArray copy];
}

-(UIView*)swipingBackgoundView {
    if (!_swipingBackgoundView) {
        _swipingBackgoundView = [[UIView alloc] initWithFrame:self.webView.bounds];
        _swipingBackgoundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    return _swipingBackgoundView;
}

-(void)startPopSnapshotView {
    if (self.isSwipingBack) {
        return;
    }
    if (!self.webView.canGoBack) {
        return;
    }
    self.isSwipingBack = YES;
    //create a center of scrren
    CGPoint center = CGPointMake(self.webView.bounds.size.width/2, self.webView.bounds.size.height/2);
    
    self.currentSnapShotView = [self.webView snapshotViewAfterScreenUpdates:YES];
    
    //add shadows just like UINavigationController
    self.currentSnapShotView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.currentSnapShotView.layer.shadowOffset = CGSizeMake(3, 3);
    self.currentSnapShotView.layer.shadowRadius = 5;
    self.currentSnapShotView.layer.shadowOpacity = 0.75;
    
    //move to center of screen
    self.currentSnapShotView.center = center;
    
    self.prevSnapShotView = (UIView*)[[self.snapShotsArray lastObject] snapShotView];
    center.x -= 60;
    self.prevSnapShotView.center = center;
    self.prevSnapShotView.alpha = 1;
    self.webView.backgroundColor = [UIColor blackColor];
    
    [self.webView addSubview:self.prevSnapShotView];
    [self.webView addSubview:self.swipingBackgoundView];
    [self.webView addSubview:self.currentSnapShotView];
}

-(void)popSnapShotViewWithPanGestureDistance:(CGFloat)distance {
    if (!self.isSwipingBack || distance <= 0) {
        return;
    }
    
    CGPoint currentSnapshotViewCenter = CGPointMake(_webView.bounds.size.width/2, _webView.bounds.size.height/2);
    currentSnapshotViewCenter.x += distance;
    CGPoint prevSnapshotViewCenter = CGPointMake(_webView.bounds.size.width/2, _webView.bounds.size.height/2);
    prevSnapshotViewCenter.x -= (_webView.bounds.size.width - distance)*60/_webView.bounds.size.width;
    self.currentSnapShotView.center = currentSnapshotViewCenter;
    self.prevSnapShotView.center = prevSnapshotViewCenter;
    self.swipingBackgoundView.alpha = (_webView.bounds.size.width - distance)/_webView.bounds.size.width;
}

-(void)endPopSnapShotView {
    if (!self.isSwipingBack) {
        return;
    }
    if (self.currentSnapShotView.center.x >= _webView.bounds.size.width) {
        // pop success
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            
            self.currentSnapShotView.center = CGPointMake(_webView.bounds.size.width*3/2, _webView.bounds.size.height/2);
            self.prevSnapShotView.center = CGPointMake(_webView.bounds.size.width/2, _webView.bounds.size.height/2);
            self.swipingBackgoundView.alpha = 0;
        }completion:^(BOOL finished) {
            [self gj_goBack];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setGj_webViewCanGoBack:[self.webView canGoBack]];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.prevSnapShotView removeFromSuperview];
            });
            
            
            [self.snapShotsArray removeLastObject];
            [self.currentSnapShotView removeFromSuperview];
            [self.swipingBackgoundView removeFromSuperview];
            self.isSwipingBack = NO;
        }];
        return;
    }
    //pop fail
    [UIView animateWithDuration:0.2 animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        self.currentSnapShotView.center = CGPointMake(_webView.bounds.size.width/2, _webView.bounds.size.height/2);
        self.prevSnapShotView.center = CGPointMake(_webView.bounds.size.width/2-60, _webView.bounds.size.height/2);
        self.prevSnapShotView.alpha = 1;
    }completion:^(BOOL finished) {
        [self setGj_webViewCanGoBack:[self.webView canGoBack]];
        [self.prevSnapShotView removeFromSuperview];
        [self.swipingBackgoundView removeFromSuperview];
        [self.currentSnapShotView removeFromSuperview];
        self.isSwipingBack = NO;
    }];
    
}

- (void)dealloc{
    [_webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    GJ_WebView_DLog(@"dealoc");
}

@end
