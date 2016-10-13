//
//  ALAssetsLibrary+WJ.m
//  LMScanerTest
//
//  Created by 流氓 on 16/7/6.
//  Copyright © 2016年 流氓. All rights reserved.
//

#import "ALAssetsLibrary+WJ.h"


//ALAssetsLibrary+WJ.m
#import "ALAssetsLibrary+WJ.h"
@implementation ALAssetsLibrary (WJ)
- (void)latestAsset:(void (^)(ALAsset * _Nullable, NSError *_Nullable))block {
    [self enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [group enumerateAssetsWithOptions:NSEnumerationReverse/*遍历方式*/ usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result) {
                    if (block) {
                        block(result,nil);
                    }
                    *stop = YES;
                }
            }];
            *stop = YES;
        }
    } failureBlock:^(NSError *error) {
        if (error) {
            if (block) {
                block(nil,error);
            }
        }
    }];
}
@end
