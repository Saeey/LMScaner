//
//  LMScaner.h
//  LMScanerTest
//
//  Created by 流氓 on 16/7/5.
//  Copyright © 2016年 流氓. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol LMScanerDelegate <NSObject>
@optional
/**
 *  加载完毕时会调用
 */
- (void)sessionIsStartRun;
/**
 *  扫描出结果时会调用
 *
 *  @param captureOutput    captureOutput
 *  @param metadataObjects  扫描出来的数据
 *  @param connection       connection
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection;

- (void)lastImage:(UIImage *)image;
@end



@interface LMScaner: NSObject

@property(nonatomic,assign)id<LMScanerDelegate> delegate;

/**
 *  相机抓取预览图层
 */
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;

/**
 *  资源库
 */
@property(nonatomic,strong)ALAssetsLibrary *library;

/**
 *  自动对焦间隔(选填)
 *  默认为1秒，在- (BOOL)initCaptureDeviceWithRectOfInterest:(CGRect)rect;方法之前设置
 */
@property(assign,nonatomic)int autoFocusTime;


/**
 *  打开闪光灯
 *
 *  @return 开启成功或失败
 */
+ (BOOL)openFlashlight;

/**
 *  关闭闪光灯
 *
 *  @return 关闭成功或失败
 */
+ (BOOL)closeFlashlight;

/**
 *  初始化CaptureDevice并设置关注区域
 *
 *  @param rect 关注区域
 *
 *  @return     返回是否成功开启
 */
- (BOOL)initCaptureDeviceWithRectOfInterest:(CGRect)rect;

/**
 *  设置关注区域
 *
 *  @param rect 关注区域
 */
- (void)setRectOfInterest:(CGRect)rect;

/**
 *  获取最后一张图片，会通过delegate返回
 */
- (void)showLastImage;

- (void)startRunning;

- (void)stopRunning;

@end
