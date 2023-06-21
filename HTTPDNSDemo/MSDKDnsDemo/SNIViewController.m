/**
 * Copyright (c) Tencent. All rights reserved.
 */

#import "SNIViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MSDKDns_C11/MSDKDns.h>
//#import <MSDKDns_C11_intl/MSDKDns.h>
#import <MSDKDns_C11/MSDKDnsHttpMessageTools.h>

#define SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@interface SNIViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, AVAssetResourceLoaderDelegate>

@property (strong, nonatomic) NSMutableData *connectionResponseData;
@property (strong, nonatomic) NSMutableData *sessionResponseData;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSURLSessionTask *task;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVAssetResourceLoadingRequest *loadrequest;


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
        .dnsIp = @"",
        .appId = @"xxxxx",
        .dnsId = 000000,
        .dnsKey = @"xxxxxxx",
        .debug = YES,
        .encryptType = HttpDnsEncryptTypeDES,
        .addressType = HttpDnsAddressTypeIPv4,
        .httpOnly = YES,
        .enableReport = YES,
    };
    [[MSDKDns sharedInstance] initConfig: &config];
   
}

//监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    NSLog(@"load status: %ld ====== error: %@", (long)playerItem.status, playerItem.error.description);
    
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            [self.player play];
        } 
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)usingConnection:(id)sender {
    _logView.text = nil;
    // 需要设置SNI的URL
    NSString *originalUrl = @"https://media.w3.org/2010/05/sintel/trailer.mp4";
    NSURL* url = [NSURL URLWithString:originalUrl];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSArray* result = [[MSDKDns sharedInstance] WGGetHostByName:url.host];
    NSString* ip = nil;
    NSLog(@"===result : %@==",result);
    if (result && result.count > 1) {
        if (![result[1] isEqualToString:@"0"]) {
            ip = result[1];
        } else {
            ip = result[0];
        }
    }
    // 通过HTTPDNS获取IP成功，进行URL替换和HOST头设置
    if (ip) {
        NSRange hostFirstRange = [originalUrl rangeOfString:url.host];
        if (NSNotFound != hostFirstRange.location) {
            NSString *newUrl = [originalUrl stringByReplacingCharactersInRange:hostFirstRange withString:ip];
            NSLog(@"===newUrl : %@==",newUrl);
            request.URL = [NSURL URLWithString:newUrl];
            [request setValue:url.host forHTTPHeaderField:@"host"];
        }
    }
//    request.timeoutInterval = 0.000001;
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.connection start];
    
//    NSString *urlStr = @"xxx://media.w3.org/2010/05/sintel/trailer.mp4";
//    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:urlStr]];
//
//    //设置代理之后AVPlayerItem的加载资源和组织资源的步骤就会被我们拦截到
//    [asset.resourceLoader setDelegate:self queue:dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
//
//    self.playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
//
//    //添加监听
//    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//
//    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
//    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
//
//    playerLayer.frame = self.view.bounds;
//    [self.view.layer addSublayer:playerLayer];
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURLRequest *request = loadingRequest.request;
    self.loadrequest = loadingRequest;
    NSLog(@"===shouldWaitForLoadingOfRequestedResource : == %@", request.URL.scheme);
//    if ([request.URL.scheme isEqualToString:@"https"]) {
//        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
//        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
//        [dataTask resume];
//        return YES;
//    }
//    return NO;
    NSURLSessionConfiguration *configuration1 = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration1 delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURL* url = loadingRequest.request.URL;
    NSURLComponents *components = [NSURLComponents new];
    components.host = url.host;
    components.scheme = @"https";
    components.path = url.path;
    NSURL *initialUrl = [components URL];
    NSLog(@"===shouldWaitForLoadingOfRequestedResource : == %@", initialUrl);

    
    if (!initialUrl) {
        [NSException raise:@"Internal Inconsistency" format:@"Failed to replace URL scheme"];
    }
    
   
    
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        configuration.networkServiceType = NSURLNetworkServiceTypeVideo;
        configuration.allowsCellularAccess = YES;
        NSMutableURLRequest* urlRequst = [NSMutableURLRequest requestWithURL:initialUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
        [urlRequst setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
        [urlRequst setHTTPMethod:@"GET"];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        [[session dataTaskWithRequest:urlRequst] resume];
//    [self.pendingRequests addObject:loadingRequest];
//    [self processPendingRequests];
    return YES;
}

- (IBAction)usingSession:(id)sender {
    _logView.text = nil;
    // 需要设置SNI的URL
    NSString *originalUrl = @"https://encrypt-k-vod.xet.tech/9764a7a5vodtransgzp1252524126/4c6cd546243791580576849496/drm/v.f421220.m3u8?sign=85e1c12de2dbed37c0991f19454735ec&t=648b2d90&us=wdDxrhCAZc";
    NSURL* url = [NSURL URLWithString:originalUrl];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSArray* result = [[MSDKDns sharedInstance] WGGetHostByName:url.host];
    NSLog(@"===result : %@==",result);
    NSString* ip = nil;
    if (result && result.count > 1) {
        if (![result[1] isEqualToString:@"0"]) {
            ip = result[1];
        } else {
            ip = result[0];
        }
    }
    // 通过HTTPDNS获取IP成功，进行URL替换和HOST头设置
    if (ip) {
        NSRange hostFirstRange = [originalUrl rangeOfString:url.host];
        if (NSNotFound != hostFirstRange.location) {
            NSString *newUrl = [originalUrl stringByReplacingCharactersInRange:hostFirstRange withString:ip];
            NSLog(@"===newUrl : %@==",newUrl);
            request.URL = [NSURL URLWithString:newUrl];
            [request setValue:url.host forHTTPHeaderField:@"host"];
        }
    }
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSArray *protocolArray = @[[MSDKDnsHttpMessageTools class]];
    configuration.protocolClasses = protocolArray;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [session dataTaskWithRequest:request];
    [self.task resume];
    
    // 注*：使用NSURLProtocol拦截NSURLSession发起的POST请求时，HTTPBody为空。
    // 解决方案有两个：1. 使用NSURLConnection发POST请求。
    // 2. 先将HTTPBody放入HTTP Header field中，然后在NSURLProtocol中再取出来。
    // 下面主要演示第二种解决方案
    // NSString *postStr = [NSString stringWithFormat:@"param1=%@&param2=%@", @"val1", @"val2"];
    // [_request addValue:postStr forHTTPHeaderField:@"originalBody"];
    // _request.HTTPMethod = @"POST";
    // NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    // NSArray *protocolArray = @[ [CFHttpMessageURLProtocol class] ];
    // configuration.protocolClasses = protocolArray;
    // NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    // NSURLSessionTask *task = [session dataTaskWithRequest:_request];
    // [task resume];
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
//    NSLog(@"HttpsResolver didReceiveData! ==== %@", data);
    if (data && data.length > 0)
    {
        [self.connectionResponseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    // 创建AVPlayerItem
    NSString* responeString = [[NSString alloc] initWithData:self.connectionResponseData encoding:NSUTF8StringEncoding];
    NSLog(@"connectionDidFinishLoading: %@ == data: %@",responeString, self.connectionResponseData);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithDataRepresentation:self.connectionResponseData relativeToURL:nil];
        
        
        // 将NSData写入本地文件
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"video.mp4"];
        [self.connectionResponseData writeToFile:filePath atomically:YES];
        // 使用本地文件路径创建AVURLAsset对象
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
        
        self.playerItem = [[AVPlayerItem alloc] initWithAsset:asset];

        //添加监听
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

        self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];

        playerLayer.frame = self.view.bounds;
        [self.view.layer addSublayer:playerLayer];
        
        [_logView insertText:[NSString  stringWithFormat:@"请求成功，请求到的数据为：%@\n", responeString]];
    });
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"response: %@", response);
    self.sessionResponseData = nil;
    _sessionResponseData = [NSMutableData new];
    completionHandler(NSURLSessionResponseAllow);
}

#pragma mark NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (data && data.length > 0)
    {
        NSLog(@"didReceiveData: %@", data);
        [self.sessionResponseData appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSString* errorString = error.userInfo[@"NSLocalizedDescription"];
        NSLog(@"connectionDidFailWithError:%@", errorString);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_logView insertText:[NSString  stringWithFormat:@"请求失败，错误为：%@\n", errorString]];
        });
    }
    NSLog(@"connectionDidFinishLoading: %@", self.sessionResponseData);
//    [self.loadrequest.dataRequest respondWithData:self.sessionResponseData];
//    [self.loadrequest finishLoading];
    NSLog(@"complete");
            NSData *videoData = [NSData dataWithContentsOfFile:@"video.mp4"];
//             将NSData写入本地文件
            NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"video.mp4"];
            [self.sessionResponseData writeToFile:filePath atomically:YES];
            // 使用本地文件路径创建AVURLAsset对象
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
    
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    
            //添加监听
            [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//            [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
   
            self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
            AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];

            playerLayer.frame = self.view.bounds;
            [self.view.layer addSublayer:playerLayer];
//    [self.player play];
}

@end
