//
//  LMScaner.m
//  LMScanerTest
//
//  Created by 流氓 on 16/7/5.
//  Copyright © 2016年 流氓. All rights reserved.
//

#import "LMScaner.h"
#import "ALAssetsLibrary+WJ.h"

@interface LMScaner ()<AVCaptureMetadataOutputObjectsDelegate> {
    /**
     *  相机
     */
    AVCaptureDevice *_device;
    /**
     *  控制器
     */
    AVCaptureSession *_session;
    /**
     *  输出
     */
    AVCaptureMetadataOutput *_output;
    /**
     *  定时器
     */
    NSTimer *_timer;
}
@end

@implementation LMScaner
+ (BOOL)openFlashlight {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode:AVCaptureTorchModeOn];
        [device unlockForConfiguration];
        return YES;
    } else {
        return NO;
    }

}

+ (BOOL)closeFlashlight {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode:AVCaptureTorchModeOff];
        [device unlockForConfiguration];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)initCaptureDeviceWithRectOfInterest:(CGRect)rect {
    // 1. 摄像头设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 2. 设置输入
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (error) {
        return NO;
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
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGRect cropRect = rect;
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
    return YES;
}

- (void)startRunning {
    [_session startRunning];
}

- (void)stopRunning {
    [_session stopRunning];
}

- (void)setRectOfInterest:(CGRect)rect {
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGRect cropRect = rect;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 1920./1080.;  //使用1080p的图像输出
    if (p1 < p2) {
        CGFloat fixHeight = [UIScreen mainScreen].bounds.size.width * 1920. / 1080.;
        CGFloat fixPadding = (fixHeight - size.height) / 2;
        _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                            cropRect.origin.x / size.width,
                                            cropRect.size.height / fixHeight,
                                            cropRect.size.width / size.width);
    } else {
        CGFloat fixWidth = [UIScreen mainScreen].bounds.size.height * 1080. / 1920.;
        CGFloat fixPadding = (fixWidth - size.width) / 2;
        _output.rectOfInterest = CGRectMake(cropRect.origin.y / size.height,
                                            (cropRect.origin.x + fixPadding)/fixWidth,
                                            cropRect.size.height / size.height,
                                            cropRect.size.width / fixWidth);
    }

}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"running"])
    {
        if (_session.running) {
            [_session removeObserver:self forKeyPath:@"running"];
            _timer = [NSTimer scheduledTimerWithTimeInterval:self.autoFocusTime?:1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
            if ([self.delegate respondsToSelector:@selector(sessionIsStartRun)]) {
                [self.delegate sessionIsStartRun];
            }
        }
    }
}

#pragma mark - 定时器触发方法
- (void)timer {
    if (_device.isFocusPointOfInterestSupported &&[_device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error = nil;
        //对cameraDevice进行操作前，需要先锁定，防止其他线程访问，
        [_device lockForConfiguration:&error];
        [_device setFocusMode:AVCaptureFocusModeAutoFocus];
        //操作完成后，记得进行unlock。
        [_device unlockForConfiguration];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        if ([self.delegate respondsToSelector:@selector(captureOutput:didOutputMetadataObjects:fromConnection:)]) {
            [self.delegate captureOutput:captureOutput didOutputMetadataObjects:metadataObjects fromConnection:connection];
        }
    }
}

- (void)showLastImage {
    ALAssetsLibrary *library = self.library;
    
    if (library == nil) {
        
        self.library = [[ALAssetsLibrary alloc] init];
        [self.library latestAsset:^(ALAsset * _Nullable asset, NSError * _Nullable error) {
            if (asset == nil) {
                return;
            }
            
            ALAssetRepresentation *representation = [asset defaultRepresentation];
            
            // Retrieve the image orientation from the ALAsset
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber *orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }
            
            CGFloat scale  = 0.5;
            UIImage *image = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:scale orientation:orientation];
            
            // do something with the image
            if ([self.delegate respondsToSelector:@selector(lastImage:)]) {
                [self.delegate lastImage:image];
            }
        }];
        
    }
}
@end
