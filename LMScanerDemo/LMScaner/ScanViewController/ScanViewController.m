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
#import "LMScaner.h"
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

typedef void (^RecognizeFinishingBlock)(NSString *string);
@interface ScanViewController() <LMScanerDelegate> {
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
     *  描述
     */
    UILabel *_describeLabel;
    /**
     *  左下绿色图片
     */
    UIButton *_bottomLeft;
    /**
     *  左下绿色图片初始位置
     */
    CGRect _bottomLeftInitially;
    /**
     *  右下绿色按钮
     */
    UIButton *_bottomRight;
    /**
     *  右下绿色按钮初始位置
     */
    CGRect _bottomRightInitially;
    /**
     *  下方遮罩
     */
    UIView *_downShade;
    /**
     *  下方遮罩初始位置
     */
    CGRect _downShadeInitially;
    /**
     *  扫描动画图片
     */
    UIImageView *_scanNetImageView;
    /**
     *  闪光灯按钮
     */
    UIButton *_flashlightButton;
    /**
     *  下方相册按钮
     */
    UIButton *_photoLibraryBtn;
    /**
     *  输入框
     */
    UITextField *_inputBarCodeTextField;
    /**
     *  切换扫码按钮
     */
    UIButton *_inputBarCodeSwitchBtn;
    /**
     *  输入框时出现的 确定
     */
    UIButton *_inputBarCodeComplete;
    /**
     *  定时器
     */
    NSTimer *_timer;
    /**
     *  扫描线
     */
    LMScaner *_scaner;
}

@end

@implementation ScanViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.titleString?:@"二维码/条形码";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self initScanRectView];
    
    //扫描滴声
    NSString *wavPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    NSData *data      = [[NSData alloc] initWithContentsOfFile:wavPath];
    _beepPlayer       = [[AVAudioPlayer alloc] initWithData:data error:nil];
    
    //菊花加载
    _loadingView = [XHFriendlyLoadingView shareFriendlyLoadingView];
    [self.view addSubview:_loadingView];
    [_loadingView showFriendlyLoadingViewWithText:self.loadingString?:@"正在加载..." loadingAnimated:YES];

    _scaner = [[LMScaner alloc] init];
    [_scaner initCaptureDeviceWithRectOfInterest:_scanRectView.frame];
    [self.view.layer insertSublayer:_scaner.previewLayer atIndex:0];
    
    _scaner.delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    if (!_inputBarCodeTextField.hidden && _inputBarCodeTextField != nil) {
//        [_inputBarCodeTextField becomeFirstResponder];
    } else {
        [_scaner startRunning];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate];
    [_scaner stopRunning];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - 设置ScanRectView
- (void)initScanRectView {
    _scanRectView                   = [[UIView alloc] init];
    _scanRectView.backgroundColor   = [UIColor clearColor];
    _scanRectView.layer.shadowColor = [UIColor blackColor].CGColor;
    _scanRectView.frame             = CGRectMake(0, 0,CGRectGetWidth([UIScreen mainScreen].bounds) / 3 * 2, CGRectGetWidth([UIScreen mainScreen].bounds) / 3 * 2);
    _scanRectView.center            = CGPointMake(CGRectGetWidth([UIScreen mainScreen].bounds) / 2, CGRectGetHeight([UIScreen mainScreen].bounds) / 2);
    [self.view addSubview:_scanRectView];

    //扫描线
//    _scanLayer                  = [[UIView alloc] init];
//    _scanLayer.frame            = CGRectMake(0, 0, _scanRectView.bounds.size.width, 1);
//    _scanLayer.backgroundColor  = [UIColor greenColor];
//
//    [_scanRectView addSubview:_scanLayer];
    
    CGFloat scanWindowH = _scanRectView.frame.size.height;
    CGFloat scanWindowW = _scanRectView.frame.size.width;
    _scanRectView.clipsToBounds = YES;
    
    _scanNetImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_net"]];
    [_scanRectView addSubview:_scanNetImageView];
    
    //四个图片
    CGFloat buttonWH = 18;
    CGFloat offsetY  = 1.5;
    
    UIButton *topLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, offsetY, buttonWH, buttonWH)];
    [topLeft setImage:[UIImage imageNamed:@"scan_1"] forState:UIControlStateNormal];
    [_scanRectView addSubview:topLeft];
    
    UIButton *topRight = [[UIButton alloc] initWithFrame:CGRectMake(scanWindowW - buttonWH, offsetY, buttonWH, buttonWH)];
    [topRight setImage:[UIImage imageNamed:@"scan_2"] forState:UIControlStateNormal];
    [_scanRectView addSubview:topRight];
    
    _bottomLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, scanWindowH - buttonWH + offsetY, buttonWH, buttonWH)];
    [_bottomLeft setImage:[UIImage imageNamed:@"scan_3"] forState:UIControlStateNormal];
    [_scanRectView addSubview:_bottomLeft];
    _bottomLeftInitially = _bottomLeft.frame;
    
    _bottomRight = [[UIButton alloc] initWithFrame:CGRectMake(topRight.frame.origin.x, _bottomLeft.frame.origin.y, buttonWH, buttonWH)];
    [_bottomRight setImage:[UIImage imageNamed:@"scan_4"] forState:UIControlStateNormal];
    [_scanRectView addSubview:_bottomRight];
    _bottomRightInitially = _bottomRight.frame;
    
    _describeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight *0.75 - 40, kScreenWidth, 40)];
    _describeLabel.textColor = [UIColor whiteColor];
    _describeLabel.textAlignment = NSTextAlignmentCenter;
    _describeLabel.font = [UIFont systemFontOfSize:15];
    _describeLabel.text = self.describeLabelString?:@"将二维码/条码放入框内，即可自动扫描";
    [self.view addSubview:_describeLabel];
    
    CGFloat scanViewX = _scanRectView.frame.origin.x;
    CGFloat scanViewY = _scanRectView.frame.origin.y;
    CGFloat scanViewW = _scanRectView.frame.size.width;
    CGFloat scanViewH = _scanRectView.frame.size.height;
    
    //四个遮罩
    CGFloat alpha = 0.3;
    
    UIView *up = [[UIView alloc] init];
    up.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
    up.frame = CGRectMake(scanViewX, 0, scanViewW, scanViewY + offsetY);
    [self.view addSubview:up];
    
    UIView *left = [[UIView alloc] init];
    left.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
    left.frame = CGRectMake(0, 0, scanViewX, kScreenHeight);
    [self.view addSubview:left];
    
    UIView *right = [[UIView alloc] init];
    right.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
    right.frame = CGRectMake(scanViewX+scanViewW, 0, scanViewX, kScreenHeight);
    [self.view addSubview:right];
    
    _downShade                  = [[UIView alloc] init];
    _downShade.backgroundColor  = [UIColor colorWithWhite:0 alpha:alpha];
    _downShade.frame            = CGRectMake(scanViewX, scanViewY+scanViewH, scanViewW, kScreenHeight-scanViewY-scanViewH);
    _downShadeInitially         = _downShade.frame;
    [self.view addSubview:_downShade];

}

#pragma mark - 动画
- (void)moveScanLayer {
    CAAnimation *animation = [_scanNetImageView.layer animationForKey:@"translationAnimation"];
    if (animation) {
        // 1. 将动画的时间偏移量作为暂停时的时间点
        CFTimeInterval pauseTime = _scanNetImageView.layer.timeOffset;
        // 2. 根据媒体时间计算出准确的启动动画时间，对之前暂停动画的时间进行修正
        CFTimeInterval beginTime = CACurrentMediaTime() - pauseTime;
        
        // 3. 要把偏移时间清零
        [_scanNetImageView.layer setTimeOffset:0.0];
        // 4. 设置图层的开始动画时间
        [_scanNetImageView.layer setBeginTime:beginTime];
        
        [_scanNetImageView.layer setSpeed:1.0];
        
    } else {
    
        CGFloat scanNetImageViewH   = 241;
        CGFloat scanWindowH         = self.view.frame.size.width - 30 * 2;
        CGFloat scanNetImageViewW   = _scanRectView.frame.size.width;
        
        _scanNetImageView.frame = CGRectMake(0, -scanNetImageViewH, scanNetImageViewW, scanNetImageViewH);
        
        CABasicAnimation *scanNetAnimation  = [CABasicAnimation animation];
        scanNetAnimation.keyPath            = @"transform.translation.y";
        scanNetAnimation.byValue            = @(scanWindowH);
        scanNetAnimation.duration           = 1.7;
        scanNetAnimation.repeatCount        = MAXFLOAT;
//        [_scanNetImageView.layer addAnimation:scanNetAnimation forKey:@"translationAnimation"];
        
        CABasicAnimation *opacityAnimation  = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue          = [NSNumber numberWithFloat:0];
        opacityAnimation.toValue            = [NSNumber numberWithFloat:1];
        opacityAnimation.duration           = 1.7;
        opacityAnimation.repeatCount        = MAXFLOAT;
        
        CAAnimationGroup *animationGroup    = [CAAnimationGroup animation];
        animationGroup.duration             = 1.5f;
        animationGroup.autoreverses         = NO;
        animationGroup.repeatCount          = NSNotFound;
        [animationGroup setAnimations:@[scanNetAnimation,opacityAnimation]];
        
        [_scanNetImageView.layer addAnimation:animationGroup forKey:@"animationGroup"];
        
    }

}

#pragma mark - 扫描结果
//通过相册扫描
- (NSDictionary *)recognizeImage:(UIImage *)image {
    CIContext *content      = [CIContext contextWithOptions:nil];
    CIDetector *detector    = [CIDetector detectorOfType:CIDetectorTypeQRCode context:content options:nil];
    CIImage *cimage         = [CIImage imageWithCGImage:image.CGImage];
    NSArray *features       = [detector featuresInImage:cimage];
    
    CIQRCodeFeature *feature = [features firstObject];
    NSLog(@"feature.messageString:%@",feature.messageString);
    
    if (_finishingBlock && feature.messageString) {
        _finishingBlock(feature.messageString);
        [_beepPlayer play];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [_scaner startRunning];
        [self moveScanLayer];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:self.scanPhotoLibraryFail?:@"啥都没扫到,换个姿势吧!" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
    return nil;
}

#pragma mark - 设置Buttons
- (void)setupButtons {
    //闪光灯开关按钮
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!self.hiddenLighting && [device hasTorch]) {
        _flashlightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashlightButton setImage:[UIImage imageNamed:@"icon_light_normal.png"] forState:UIControlStateNormal];
        [_flashlightButton setImage:[UIImage imageNamed:@"icon_light.png"] forState:UIControlStateSelected];
        _flashlightButton.frame = CGRectMake(kScreenWidth/2 - 20, kScreenHeight * 0.75, 40, 40);
        [_flashlightButton addTarget:self action:@selector(flashlightButtonButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_flashlightButton];
    }
    
    if (!self.hiddenUpPhotoLibrary) {
        UIBarButtonItem *rightButtonItme = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonItmeClick)];
        self.navigationItem.rightBarButtonItem = rightButtonItme;
    }
    if (!self.hiddenDownPhotoLibrary) {
        _photoLibraryBtn = [[UIButton alloc] init];
        [_photoLibraryBtn setImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_nor"] forState:UIControlStateNormal];
        _photoLibraryBtn.frame = CGRectMake(kScreenWidth / 4 * 3, kScreenHeight * 0.75, 40, 40);
        [self.view addSubview:_photoLibraryBtn];
        [_photoLibraryBtn addTarget:self action:@selector(rightButtonItmeClick) forControlEvents:UIControlEventTouchUpInside];
        [_scaner showLastImage];
    }
    
    
    
    if (!self.hiddenInputBarCodeBtn) {
        UIButton *inputBarCodeBtn = [[UIButton alloc] init];
        inputBarCodeBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        CGFloat inputBarCodeBtnW = 100;
        CGFloat inputBarCodeBtnH = 40;
        inputBarCodeBtn.frame = CGRectMake(kScreenWidth/2 - inputBarCodeBtnW/2, _flashlightButton.frame.origin.y + 50, inputBarCodeBtnW, inputBarCodeBtnH);
        [inputBarCodeBtn setTitle:@"输入条码" forState:UIControlStateNormal];
        [inputBarCodeBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [inputBarCodeBtn.layer setCornerRadius:inputBarCodeBtnH/2];
        inputBarCodeBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [inputBarCodeBtn addTarget:self action:@selector(inputBarCodeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:inputBarCodeBtn];
    }
    
    
}

#pragma mark - 按钮点击事件
- (void)flashlightButtonButtonClick:(UIButton *)sender {
    if (sender.selected) {
        [LMScaner closeFlashlight];
    } else {
        [LMScaner openFlashlight];
    }
    sender.selected = !sender.selected;
}

- (void)rightButtonItmeClick {
    ImagePickerController *picker = [[ImagePickerController alloc] init];
    [picker setAllowsEditing:YES];
    [picker cameraSourceType:UIImagePickerControllerSourceTypePhotoLibrary onFinishingBlock:^(UIImagePickerController *picker, NSDictionary *info, UIImage *originalImage, UIImage *editedImage) {
        [_scaner stopRunning];
        [self recognizeImage:editedImage?:originalImage];
    } onCancelingBlock:^() {
        
    }];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)inputBarCodeBtnClick:(UIButton *)sender {
    if (!_inputBarCodeTextField) {
        
        CGFloat scanRectViewX = _scanRectView.frame.origin.x;
        CGFloat scanRectViewY = _scanRectView.frame.origin.y;
        CGFloat scanRectViewW = _scanRectView.frame.size.width;
        
        _inputBarCodeTextField = [[UITextField alloc] init];
        _inputBarCodeTextField.placeholder = @"请输入条码号";
        _inputBarCodeTextField.textAlignment = NSTextAlignmentLeft;
        _inputBarCodeTextField.backgroundColor = [UIColor whiteColor];
        CGRect frame = [_inputBarCodeTextField frame];
        frame.size.width = 7.0f;
        UIView *leftview = [[UIView alloc] initWithFrame:frame];
        _inputBarCodeTextField.leftViewMode = UITextFieldViewModeAlways;
        _inputBarCodeTextField.leftView = leftview;
        CGFloat offset = 2;
        CGFloat inputBarCodeTextFieldH = 40;
        _inputBarCodeTextField.frame = CGRectMake(scanRectViewX+offset, scanRectViewY+offset*2, scanRectViewW-offset*2, inputBarCodeTextFieldH);
        [self.view addSubview:_inputBarCodeTextField];
        
        _inputBarCodeSwitchBtn = [[UIButton alloc] init];
        CGFloat inputBarCodeSwitchBtnW = 70;
        _inputBarCodeSwitchBtn.frame = CGRectMake(scanRectViewX, _inputBarCodeTextField.frame.origin.y+inputBarCodeTextFieldH+20, inputBarCodeSwitchBtnW, inputBarCodeTextFieldH);
        _inputBarCodeSwitchBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _inputBarCodeSwitchBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_inputBarCodeSwitchBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_inputBarCodeSwitchBtn.layer setCornerRadius:inputBarCodeTextFieldH/2];
        [_inputBarCodeSwitchBtn setTitle:@"切换扫码" forState:UIControlStateNormal];
        [_inputBarCodeSwitchBtn addTarget:self action:@selector(inputBarCodeSwitchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _inputBarCodeSwitchBtn.hidden = YES;
        [self.view addSubview:_inputBarCodeSwitchBtn];
        
        _inputBarCodeComplete = [[UIButton alloc] init];
        _inputBarCodeComplete.frame = CGRectMake(scanRectViewX+scanRectViewW - inputBarCodeSwitchBtnW, _inputBarCodeSwitchBtn.frame.origin.y, inputBarCodeSwitchBtnW, inputBarCodeTextFieldH);
        _inputBarCodeComplete.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _inputBarCodeComplete.titleLabel.font = [UIFont systemFontOfSize:13];
        [_inputBarCodeComplete setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_inputBarCodeComplete.layer setCornerRadius:inputBarCodeTextFieldH/2];
        [_inputBarCodeComplete setTitle:@"确定" forState:UIControlStateNormal];
        [_inputBarCodeComplete addTarget:self action:@selector(inputBarCodeCompleteClick:) forControlEvents:UIControlEventTouchUpInside];
        _inputBarCodeComplete.hidden = YES;
        [self.view addSubview:_inputBarCodeComplete];
        
    }
    
    _inputBarCodeTextField.hidden = sender.selected;
    
    if (!_inputBarCodeTextField.hidden) {
        CGRect downShadeFrameTemp = _downShade.frame;
        downShadeFrameTemp.origin.y = _inputBarCodeTextField.frame.origin.y+_inputBarCodeTextField.frame.size.height +3;
        downShadeFrameTemp.size.height = kScreenHeight;
        CGRect bottomLeftFrameTemp = _bottomLeft.frame;
        bottomLeftFrameTemp.origin.y -= _downShadeInitially.origin.y - downShadeFrameTemp.origin.y;
        CGRect bottomRightFrameTemp = _bottomRight.frame;
        bottomRightFrameTemp.origin.y -= _downShadeInitially.origin.y - downShadeFrameTemp.origin.y;
        [UIView animateWithDuration:0.7 animations:^{
            _downShade.frame = downShadeFrameTemp;
            _bottomLeft.frame = bottomLeftFrameTemp;
            _bottomRight.frame = bottomRightFrameTemp;
        } completion:^(BOOL finished) {
            _inputBarCodeSwitchBtn.hidden = NO;
            _inputBarCodeComplete.hidden = NO;
            _describeLabel.hidden = YES;
            
        }];
        [_scanNetImageView.layer removeAllAnimations];
        [_scaner stopRunning];
        [_inputBarCodeTextField becomeFirstResponder];
    } else {
        [_scaner startRunning];
    }
    sender.selected = !sender.selected;
}

- (void)inputBarCodeSwitchBtnClick:(UIButton *)sender {
    [UIView animateWithDuration:0.7 animations:^{
        _downShade.frame = _downShadeInitially;
        _bottomLeft.frame = _bottomLeftInitially;
        _bottomRight.frame = _bottomRightInitially;
    } completion:^(BOOL finished) {
        [self moveScanLayer];
    }];
    sender.hidden = YES;
    _describeLabel.hidden = NO;
    [_inputBarCodeTextField endEditing:YES];
    _inputBarCodeTextField.hidden = YES;
    _inputBarCodeComplete.hidden = YES;
    [_scaner startRunning];
}

- (void)inputBarCodeCompleteClick:(UIButton *)sender {
    if (![_inputBarCodeTextField.text isEqualToString:@""]) {
        [_inputBarCodeTextField endEditing:YES];
        [_beepPlayer play];
        _finishingBlock(_inputBarCodeTextField.text);
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - AppDelegate
- (void)applicationWillEnterForeground:(NSNotification *)note {
    [_scaner startRunning];
}

- (void)applicationDidEnterBackground:(NSNotification *)note {
    [_scaner stopRunning];
}

#pragma mark - finishingBlock
- (void)finishingBlock:(FinishingBlock)finishingBlock {
    _finishingBlock = [finishingBlock copy];
}

#pragma mark - LMScanerDelegate
//通过摄像头实时扫描
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"%@", metadataObjects);
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        if (_finishingBlock && [obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            [_beepPlayer play];
            [_scaner stopRunning];
            _finishingBlock(obj.stringValue);
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }
}

- (void)sessionIsStartRun {
    [_loadingView removeFromSuperview];
    [self moveScanLayer];
    [self setupButtons];
}

- (void)lastImage:(UIImage *)image {
    [_photoLibraryBtn setImage:image forState:UIControlStateNormal];
}
@end
