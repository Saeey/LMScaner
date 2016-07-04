//
//  ViewController.m
//  LMScanerTest
//
//  Created by 流氓 on 16/6/29.
//  Copyright © 2016年 流氓. All rights reserved.
//

#import "ViewController.h"
#import "ScanViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *btn = [[UIButton alloc]init];
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn setTitle:@"快点我" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:btn];
}

- (void)btnClick{
    
    ScanViewController *scan = [[ScanViewController alloc]init];
    [scan finishingBlock:^(NSString *string) {
        //返回解析出来的二维码/条形码
    }];
    
    [self.navigationController pushViewController:scan animated:YES];
    //       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:string delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    //        [alert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
