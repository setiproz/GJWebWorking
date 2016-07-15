//
//  GJWebView.m
//  GJWebViewController
//
//  Created by 张旭东 on 16/7/14.
//  Copyright © 2016年 Alien. All rights reserved.
//

#import "GJWebView.h"
#import <WebKit/WebKit.h>
#import "GJWebViewViewModel.h"
#import "GJWKWebViewViewModel.h"
@interface GJWebView(){
    UIView * _webView;
    id<GJWebViewViewModelPortocol> _gjWebViewModel;
}



@end

@implementation GJWebView
@synthesize webView = _webView;
@synthesize gjWebViewModel = _gjWebViewModel;

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        if (gj_webView_isWKWebAvailable) {
            _gjWebViewModel = [[GJWKWebViewViewModel alloc]init];
            _webView = _gjWebViewModel.webView;
           
        }else{
            _gjWebViewModel = [[GJWebViewViewModel alloc]init];
            _webView = _gjWebViewModel.webView;
        }
         [self addSubview:_webView];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraint:[NSLayoutConstraint  constraintWithItem:_webView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint  constraintWithItem:_webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint  constraintWithItem:_webView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint  constraintWithItem:_webView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    }
    return self;
}

- (void)gj_webViewLoadRequest:(NSURLRequest * _Nonnull)request
                   shouldSart:(_Nullable GJWebShouldStartLoadBlock)shouldStart
                     progress:(_Nullable GJWebViewProgressBlock)progress
                      didFinshLoad:(_Nullable GJWebViewDidFinishLoadBlock)didFinshLoad{
    _gjWebViewModel.shouldStartBlock = shouldStart;
    _gjWebViewModel.progressBlock = progress;
    _gjWebViewModel.didFinshLoadBlock = didFinshLoad;
    if (gj_webView_isWKWebAvailable) {
        [(WKWebView *)_webView loadRequest:request];
    }else{
        [(UIWebView *)_webView loadRequest:request];
    }
    
}


- (void)gj_webViewCanGoBack:(void (^)(BOOL isCanBack))isCanBack{
    [_gjWebViewModel gj_webViewCanGoBack:isCanBack];
}
- (void)dealloc{
    GJ_WebView_DLog(@"dealoc");
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end