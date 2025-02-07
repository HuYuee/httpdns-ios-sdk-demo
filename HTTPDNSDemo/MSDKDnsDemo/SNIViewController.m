/**
 * Copyright (c) Tencent. All rights reserved.
 */

#import "SNIViewController.h"
#import <MSDKDns_C11/MSDKDns.h>
#import <MSDKDns_C11/MSDKDnsHttpMessageTools.h>
#import <AFNetworking/AFNetworking.h>

#define SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@interface SNIViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic) NSMutableData *connectionResponseData;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSURLSessionTask *task;

@property (weak, nonatomic) IBOutlet UITextView *logView;

@end

@implementation SNIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 注册拦截请求的NSURLProtocol
    [NSURLProtocol registerClass:[MSDKDnsHttpMessageTools class]];
    
    DnsConfig config = {
        .dnsId = dns授权id,
        .dnsKey = @"DesKey加密密钥",
          .encryptType = HttpDnsEncryptTypeDES,
    };
    [[MSDKDns sharedInstance] initConfig: &config];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)usingAFNetworking:(id)sender {
    _logView.text = nil;
    // 需要设置SNI的URL
    NSString *originalUrl = @"https://www.qq.com/";    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSArray *protocolArray = @[[MSDKDnsHttpMessageTools class]];
    config.protocolClasses = protocolArray;
    AFHTTPSessionManager* sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSURLSessionDataTask* task = [sessionManager GET:originalUrl parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"request complete ==== response: %@ ===== error: nil", responseString);
       _logView.text = responseString; // 将响应字符串显示在_logView中
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"request complete ==== response: nil ===== error: %@", error);
       _logView.text = [error localizedDescription];  // 将错误信息显示在_logView中
    }];
    [task resume];

}

- (IBAction)usingConnection:(id)sender {
    _logView.text = nil;
    // 需要设置SNI的URL
    NSString *originalUrl = @"https://www.qq.com/";
    NSURL* url = [NSURL URLWithString:originalUrl];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.connection start];
}

- (IBAction)usingSession:(id)sender {
    _logView.text = nil;
    // 需要设置SNI的URL
    NSString *originalUrl = @"https://www.qq.com/";
    NSURL* url = [NSURL URLWithString:originalUrl];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSArray *protocolArray = @[[MSDKDnsHttpMessageTools class]];
    configuration.protocolClasses = protocolArray;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [session dataTaskWithRequest:request];
    [self.task resume];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    // 取消注册CFHttpMessageURLProtocol，避免拦截其他场景的请求
    [NSURLProtocol unregisterClass:[MSDKDnsHttpMessageTools class]];
}

- (void)dealloc
{
    [self setConnectionResponseData:nil];
    [self.connection cancel];
    [self setConnection:nil];
    [self.task cancel];
    [self setTask:nil];
}


#pragma mark NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    return request;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSString* errorString = error.userInfo[@"NSLocalizedDescription"];
    NSLog(@"connectionDidFailWithError:%@", errorString);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_logView insertText:[NSString  stringWithFormat:@"请求失败，错误为：%@\n", errorString]];
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"HttpsResolver didReceiveResponse!");
    self.connectionResponseData = nil;
    _connectionResponseData = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"HttpsResolver didReceiveData!");
    if (data && data.length > 0)
    {
        [self.connectionResponseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString* responeString = [[NSString alloc] initWithData:self.connectionResponseData encoding:NSUTF8StringEncoding];
    NSLog(@"connectionDidFinishLoading: %@",responeString);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_logView insertText:[NSString  stringWithFormat:@"请求成功，请求到的数据为：%@\n", responeString]];
    });
}


#pragma mark NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSString* responeString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveData: %@", responeString);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_logView insertText:[NSString  stringWithFormat:@"请求成功，请求到的数据为：%@\n", responeString]];
    });
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"response: %@", response);
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSString* errorString = error.userInfo[@"NSLocalizedDescription"];
        NSLog(@"connectionDidFailWithError:%@", errorString);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_logView insertText:[NSString  stringWithFormat:@"请求失败，错误为：%@\n", errorString]];
        });
    }
    else
    NSLog(@"complete");
}

@end
