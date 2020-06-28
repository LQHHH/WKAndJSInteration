//
//  WebViewController.m
//  WKWebViewTest
//
//  Created by hhh on 2020/6/25.
//  Copyright © 2020 hzq. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

@interface WebViewController () <WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic,strong) UIProgressView *progress;

@end

@implementation WebViewController

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:@"test.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
    [self.webView loadRequest:request];
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
       [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    [self showWithMessage:message];
    completionHandler();
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"OCHandler"]) {
        [self showWithMessage:[NSString stringWithFormat:@"js传了参数：%@",message.body]];
    } else if ([message.name isEqualToString:@"OCHandler1"]) {
        NSDictionary *dic = message.body;
        int a = [dic[@"a"] intValue];
        int b = [dic[@"b"] intValue];
        [self.webView evaluateJavaScript:[NSString stringWithFormat:@"show(%d)",a+b] completionHandler:nil];
    }
}

- (void)showWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *userController = [[WKUserContentController alloc] init];
        configuration.userContentController = userController;
        //添加一个方法给js
        [userController addScriptMessageHandler:self name:@"OCHandler"];
        [userController addScriptMessageHandler:self name:@"OCHandler1"];
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        _webView.UIDelegate = self;
        [self.view addSubview:_webView];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_webView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
            [_webView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
            [_webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [_webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
        
    }
    
    return _webView;
}

- (UIProgressView *)progress
{
    if (_progress == nil)
    {
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [self getStatusBarHight] + 44;
        _progress = [[UIProgressView alloc]initWithFrame:CGRectMake(0, height, width, 2)];
        _progress.tintColor = [UIColor blueColor];
        _progress.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:_progress];
    }
    return _progress;
}

-(CGFloat)getStatusBarHight {
    float statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager;
        statusBarHeight = statusBarManager.statusBarFrame.size.height;
    }
    else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    return statusBarHeight;
}

#pragma mark KVO的监听代理
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    //加载进度值
    if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        if (object == self.webView)
        {
            [self.progress setAlpha:1.0f];
            [self.progress setProgress:self.webView.estimatedProgress animated:YES];
            if(self.webView.estimatedProgress >= 1.0f)
            {
                [UIView animateWithDuration:0.5f
                                      delay:0.3f
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                    [self.progress setAlpha:0.0f];
                }
                                 completion:^(BOOL finished) {
                    [self.progress setProgress:0.0f animated:NO];
                }];
            }
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    //网页title
    else if ([keyPath isEqualToString:@"title"])
    {
        if (object == self.webView)
        {
            self.title = self.webView.title;
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
