//
//  ScanViewController.m
//  Scanner
//
//  Created by 流氓 on 16/6/29.
//  Copyright © 2016年 流氓. All rights reserved.
//

#import "ScanViewController.h"
#import "ImagePickerController.h"
#import "XHFriendlyLoadingView.h"
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

typedef void (^RecognizeFinishingBlock)(NSString *string);
@interface ScanViewController (){
    /**
     *  相机
     */
    AVCaptureDevice *_device;
    /**
     *  控制器
     */
    AVCaptureSession *_session;
    /**
     *  相机抓取预览图层
     */
    AVCaptureVideoPreviewLayer *_previewLayer;
    /**
     *  输出
     */
    AVCaptureMetadataOutput *_output;
    /**
     *  音频播放控制器(滴声)
     */
    AVAudioPlayer *_beepPlayer;
    /**
     *  扫描成功后回调
     */
    FinishingBlock _finishingBlock;
    /**
     *  友好加载View
     */
    XHFriendlyLoadingView *_loadingView;
    /**
     *  扫描区域View
     */
    UIView *_scanRectView;
    /**
     *  扫描动画图片
     */
    UIImageView *_scanNetImageView;
    /**
     *  闪光灯按钮
     */
    UIButton *_flashlightButton;
    /**
     *  定时器
     */
    NSTimer *_timer;
    /**
     *  扫描线
     */
    //    UIView *_scanLayer;
}

@end

@implementation ScanViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.titleString?:@"二维码/条形码";
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(applicationWillEnterForeground:)   name:UIApplicationWillEnterForegroundNotification  object:nil];
    
    [[NSNotificationCenter defaultCenter]  addObserver:self    selector:@selector(applicationDidEnterBackground:)  name:UIApplicationDidEnterBackgroundNotification  object:nil];
    
    [self initScanRectView];
    
    //扫描滴声
    NSString * wavPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    NSData* data = [[NSData alloc] initWithContentsOfFile:wavPath];
    _beepPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
    
    //菊花加载
    _loadingView = [XHFriendlyLoadingView shareFriendlyLoadingView];
    [self.view addSubview:_loadingView];
    [_loadingView showFriendlyLoadingViewWithText:self.loadingString?:@"正在加载..." loadingAnimated:YES];

    [self initCaptureDevice];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    [_session startRunning];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_timer invalidate];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - 设置ScanRectView
- (void)initScanRectView{
    _scanRectView = [[UIView alloc] init];
    _scanRectView.backgroundColor = [UIColor clearColor];
    _scanRectView.layer.shadowColor = [UIColor blackColor].CGColor;
    _scanRectView.frame = CGRectMake(0, 0,CGRectGetWidth([UIScreen mainScreen].bounds)/3*2, CGRectGetWidth([UIScreen mainScreen].bounds)/3*2);

    _scanRectView.center = CGPointMake(CGRectGetWidth([UIScreen mainScreen].bounds)/2, CGRectGetHeight([UIScreen mainScreen].bounds)/2);
    [self.view addSubview:_scanRectView];
//
//    //扫描线
//    _scanLayer = [[UIView alloc] init];
//    _scanLayer.frame = CGRectMake(0, 0, self.scanRectView.bounds.size.width, 1);
//    _scanLayer.backgroundColor = [UIColor greenColor];
//    
//    [self.scanRectView addSubview:_scanLayer];
    
    CGFloat scanWindowH = _scanRectView.frame.size.height;
    CGFloat scanWindowW = _scanRectView.frame.size.width;
    _scanRectView.clipsToBounds = YES;
    
    _scanNetImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_net"]];
    [_scanRectView addSubview:_scanNetImageView];
    CGFloat buttonWH = 18;
    
    UIButton *topLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWH, buttonWH)];
    [topLeft setImage:[UIImage imageNamed:@"scan_1"] forState:UIControlStateNormal];
    [_scanRectView addSubview:topLeft];
    
    UIButton *topRight = [[UIButton alloc] initWithFrame:CGRectMake(scanWindowW - buttonWH, 0, buttonWH, buttonWH)];
    [topRight setImage:[UIImage imageNamed:@"scan_2"] forState:UIControlStateNormal];
    [_scanRectView addSubview:topRight];
    
    UIButton *bottomLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, scanWindowH - buttonWH, buttonWH, buttonWH)];
    [bottomLeft setImage:[UIImage imageNamed:@"scan_3"] forState:UIControlStateNormal];
    [_scanRectView addSubview:bottomLeft];
    
    UIButton *bottomRight = [[UIButton alloc] initWithFrame:CGRectMake(topRight.frame.origin.x, bottomLeft.frame.origin.y, buttonWH, buttonWH)];
    [bottomRight setImage:[UIImage imageNamed:@"scan_4"] forState:UIControlStateNormal];
    [_scanRectView addSubview:bottomRight];
    
    UILabel *describeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight *0.75 - 40, kScreenWidth, 40)];
    describeLabel.textColor = [UIColor whiteColor];
    describeLabel.textAlignment = NSTextAlignmentCenter;
    describeLabel.font = [UIFont systemFontOfSize:15];
    describeLabel.text = self.describeLabelString?:@"将二维码/条码放入框内，即可自动扫描";
    [self.view addSubview:describeLabel];
}

- (void)moveScanLayer{
    CAAnimation *anim = [_scanNetImageView.layer animationForKey:@"translationAnimation"];
    if(anim){
        // 1. 将动画的时间偏移量作为暂停时的时间点
        CFTimeInterval pauseTime = _scanNetImageView.layer.timeOffset;
        // 2. 根据媒体时间计算出准确的启动动画时间，对之前暂停动画的时间进行修正
        CFTimeInterval beginTime = CACurrentMediaTime() - pauseTime;
        
        // 3. 要把偏移时间清零
        [_scanNetImageView.layer setTimeOffset:0.0];
        // 4. 设置图层的开始动画时间
        [_scanNetImageView.layer setBeginTime:beginTime];
        
        [_scanNetImageView.layer setSpeed:1.0];
        
    }else{
    
        CGFloat scanNetImageViewH = 241;
        CGFloat scanWindowH = self.view.frame.size.width - 30 * 2;
        CGFloat scanNetImageViewW = _scanRectView.frame.size.width;
        
        _scanNetImageView.frame = CGRectMake(0, -scanNetImageViewH, scanNetImageViewW, scanNetImageViewH);
        CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
        scanNetAnimation.keyPath = @"transform.translation.y";
        scanNetAnimation.byValue = @(scanWindowH);
        scanNetAnimation.duration = 1.7;
        scanNetAnimation.repeatCount = MAXFLOAT;
//        [_scanNetImageView.layer addAnimation:scanNetAnimation forKey:@"translationAnimation"];
        
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = [NSNumber numberWithFloat:0];
        opacityAnimation.toValue = [NSNumber numberWithFloat:1];
        opacityAnimation.duration = 1.7;
        opacityAnimation.repeatCount = MAXFLOAT;
        
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = 1.5f;
        animationGroup.autoreverses = NO;
        animationGroup.repeatCount = NSNotFound;
        [animationGroup setAnimations:@[scanNetAnimation,opacityAnimation]];
        
        [_scanNetImageView.layer addAnimation:animationGroup forKey:@"animationGroup"];
        
    }

}

#pragma mark - 设置输入输出
- (void)initCaptureDevice{
    // 1. 摄像头设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 2. 设置输入
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (error) {
        NSLog(@"没有摄像头-%@", error.localizedDescription);
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:@"开启摄像头失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    // 3. 设置输出(Metadata元数据)
    _output = [[AVCaptureMetadataOutput alloc] init];
    // 3.1 设置输出的代理
    // 说明：使用主线程队列，相应比较同步，使用其他队列，相应不同步，容易让用户产生不好的体验
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //    [output setMetadataObjectsDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    // 4. 拍摄会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    // 添加session的输入和输出
    [session addInput:input];
    [session addOutput:_output];
    //使用1080p的图像输出
    session.sessionPreset = AVCaptureSessionPresetHigh;
    // 4.1 设置输出的格式
    // 提示：一定要先设置会话的输出为output之后，再指定输出的元数据类型！这样是设置为全部编码格式
    [_output setMetadataObjectTypes:[_output availableMetadataObjectTypes]];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
//    _output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    // 5. 设置预览图层（用来让用户能够看到扫描情况）
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    // 5.1 设置preview图层的属性
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    // 5.2 设置preview图层的大小
    preview.frame = [UIScreen mainScreen].bounds;
 
    _previewLayer = preview;
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
  
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGRect cropRect = _scanRectView.frame;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 1920./1080.;  //使用1080p的图像输出
    if (p1 < p2) {
        CGFloat fixHeight = [UIScreen mainScreen].bounds.size.width * 1920. / 1080.;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                  cropRect.origin.x/size.width,
                                                  cropRect.size.height/fixHeight,
                                                  cropRect.size.width/size.width);
    } else {
        CGFloat fixWidth = [UIScreen mainScreen].bounds.size.height * 1080. / 1920.;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                  (cropRect.origin.x + fixPadding)/fixWidth,
                                                  cropRect.size.height/size.height,
                                                  cropRect.size.width/fixWidth);
    }

    _session = session;
    [_session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"running"])
    {
        NSLog(@"running==%d",_session.running);
        if (_session.running) {
            [_session removeObserver:self forKeyPath:@"running"];
            [_loadingView removeFromSuperview];
            [self moveScanLayer];
            [self setupButtons];
            _timer = [NSTimer scheduledTimerWithTimeInterval:self.autoFocusTime?:1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
        }
    }
}
#pragma mark - 定时器触发方法
- (void)timer{
    if (_device.isFocusPointOfInterestSupported &&[_device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error = nil;
        //对cameraDevice进行操作前，需要先锁定，防止其他线程访问，
        [_device lockForConfiguration:&error];
        [_device setFocusMode:AVCaptureFocusModeAutoFocus];
        [_device setFocusMode:AVCaptureFocusModeAutoFocus];
        //操作完成后，记得进行unlock。
        [_device unlockForConfiguration];
    }
}

#pragma mark - 扫描结果
//通过相册扫描
- (NSDictionary*)recognizeImage:(UIImage*)image{
    CIContext *content = [CIContext contextWithOptions:nil];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:content options:nil];
    CIImage *cimage = [CIImage imageWithCGImage:image.CGImage];
    NSArray *features = [detector featuresInImage:cimage];
    
    CIQRCodeFeature *f = [features firstObject];
    NSLog(@"f.messageString:%@",f.messageString);
    
    if (_finishingBlock && f.messageString) {
        _finishingBlock(f.messageString);
        [_beepPlayer play];
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [_session startRunning];
        [self moveScanLayer];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:self.scanPhotoLibraryFail?:@"啥都没扫到,换个姿势吧!" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
    return nil;
}

//通过摄像头实时扫描
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    NSLog(@"%@", metadataObjects);
    if (metadataObjects.count > 0) {
        [_beepPlayer play];
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        if(_finishingBlock &&[obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]){
            [_session stopRunning];
            _finishingBlock(obj.stringValue);
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }
}

#pragma mark - 设置Buttons
- (void)setupButtons{
    //闪光灯开关按钮
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!self.hiddenLighting && [device hasTorch]) {
        _flashlightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashlightButton setImage:[UIImage imageNamed:@"icon_light_normal.png"] forState:UIControlStateNormal];
        [_flashlightButton setImage:[UIImage imageNamed:@"icon_light.png"] forState:UIControlStateSelected];
        _flashlightButton.frame = CGRectMake(kScreenWidth/2 - 20, kScreenHeight*0.75, 40, 40);
        [_flashlightButton addTarget:self action:@selector(flashlightButtonButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_flashlightButton];
    }
    
    if(!self.hiddenPhotoLibrary){
        UIBarButtonItem *rightButtonItme = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonItmeClick)];
        self.navigationItem.rightBarButtonItem = rightButtonItme;
    }
    
}

#pragma mark - 按钮点击事件
- (void)flashlightButtonButtonClick:(UIButton *)sender{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (sender.selected) {
            [device setTorchMode:AVCaptureTorchModeOff];
        } else {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        [device unlockForConfiguration];
        sender.selected = !sender.selected;
    }else{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:@"该设备没有闪光灯" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    }
}

- (void)rightButtonItmeClick{
    ImagePickerController *picker = [[ImagePickerController alloc] init];
    [picker setAllowsEditing:YES];
    [picker cameraSourceType:UIImagePickerControllerSourceTypePhotoLibrary onFinishingBlock:^(UIImagePickerController *picker, NSDictionary *info, UIImage *originalImage, UIImage *editedImage) {
        [_session stopRunning];
        [self recognizeImage:editedImage?:originalImage];
    } onCancelingBlock:^() {
        
    }];
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - AppDelegate
- (void)applicationWillEnterForeground:(NSNotification*)note {
    [_session  startRunning];
}

- (void)applicationDidEnterBackground:(NSNotification*)note {
    [_session stopRunning];
}

#pragma mark - finishingBlock
- (void)finishingBlock:(FinishingBlock)finishingBlock{
    _finishingBlock = [finishingBlock copy];
}
@end