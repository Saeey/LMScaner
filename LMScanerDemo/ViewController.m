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
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [[UIButton alloc]init];
    button.frame = CGRectMake(100, 100, 100, 100);
    [button setTitle:@"快点我" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [self.view addSubview:button];
}

- (void)buttonClick {
    ScanViewController *scan = [[ScanViewController alloc]init];
    [scan finishingBlock:^(NSString *string) {
        //这里会或得到扫描出来的结果
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"扫描出来了" message:string delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }];
    [self.navigationController pushViewController:scan animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
