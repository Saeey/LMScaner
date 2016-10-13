//
//  ALAssetsLibrary+WJ.h
//  LMScanerTest
//
//  Created by 流氓 on 16/7/6.
//  Copyright © 2016年 流氓. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetsLibrary (WJ)
/**
 *  获取最新一张图片
 *
 *  @param block 回调
 */
- (void)latestAsset:(void(^_Nullable)(ALAsset * _Nullable asset,NSError *_Nullable error)) block;
@end
