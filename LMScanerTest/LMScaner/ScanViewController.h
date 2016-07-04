//
//  ScanViewController.h
//  Scanner
//
//  Created by 流氓 on 16/6/29.
//  Copyright © 2016年 流氓. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
typedef void (^FinishingBlock)(NSString *string);

@interface ScanViewController : UIViewController<AVCaptureMetadataOutputObjectsDelegate>
/**
 *  扫描成功后的回调(必输)
 *
 *  @param finishingBlock
 */
- (void)finishingBlock:(FinishingBlock)finishingBlock;
/**
 *  标题(选填)
 *  默认为"二维码/条形码"
 */
@property(strong,nonatomic)NSString *titleString;
/**
 *  描述文字(选填)
 *  默认为"将二维码/条码放入框内，即可自动扫描"
 */
@property(strong,nonatomic)NSString *describeLabelString;
/**
 *  自动对焦间隔(选填)
 *  默认为1秒
 */
@property(assign,nonatomic)int autoFocusTime;
/**
 *  扫描相册失败时的文字描述(选填)
 *  默认为"啥都没扫到,换个姿势吧!"
 */
@property(strong,nonatomic)NSString *scanPhotoLibraryFail;
/**
 *  加载时文字描述(选填)
 *  默认为"正在加载..."
 */
@property(strong,nonatomic)NSString *loadingString;
/**
 *  是否隐藏闪光灯按钮(选填)
 *  默认不隐藏，如果无闪光灯，自动隐藏
 */
@property(assign,nonatomic)BOOL hiddenLighting;
/**
 *  是否隐藏相册按钮(选填)
 *  默认不隐藏
 */
@property(assign,nonatomic)BOOL hiddenPhotoLibrary;
@end
