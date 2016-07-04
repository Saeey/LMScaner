//
//  ImagePickerController.h
//  Scanner
//
//  Created by Jakey on 15/2/13.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^UIImagePickerControllerFinishingBlock)(UIImagePickerController *picker, NSDictionary *info, UIImage *originalImage, UIImage *editedImage);
typedef void (^CancelingBlock)(void);


@interface ImagePickerController : UIImagePickerController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    UIImagePickerControllerFinishingBlock _finishingBlock;
    CancelingBlock _cancelingBlock;
}
- (void)cameraSourceType:(UIImagePickerControllerSourceType)source
              onFinishingBlock:(UIImagePickerControllerFinishingBlock)finishingBlock
              onCancelingBlock:(CancelingBlock)cancelingBlock;



@end
