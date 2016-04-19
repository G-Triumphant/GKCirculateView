//
//  ViewController.m
//  GKCirculateView
//
//  Created by apple on 16/4/13.
//  Copyright © 2016年 guoxc. All rights reserved.
//

#import "ViewController.h"
#import "GKCirculateView.h"

@interface ViewController ()<GKCirculateViewDelegate>

@property(nonatomic, strong) GKCirculateView *circulateView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSArray *ary = @[[UIImage imageNamed:@"1.jpg"], [UIImage imageNamed:@"2.jpg"], [UIImage imageNamed:@"3.jpg"], [UIImage imageNamed:@"4.jpg"], [UIImage imageNamed:@"5"]];
    _circulateView = [[GKCirculateView alloc] initWithImageAry:ary];
    _circulateView.frame = CGRectMake(0, 100, 375, 150);
    _circulateView.delegate = self;
    
    _circulateView.time = 5;
    [self.view addSubview:_circulateView];
    
    
}
- (void)circulateView:(GKCirculateView *)circulateView didClickImage:(NSInteger)index {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
