//
//  ViewController.m
//  VoiceCoventTxt_oc
//
//  Created by facilityone on 2022/2/16.
//

#import "ViewController.h"
#import "IFLyMscViewController.h"
#import "PrimitiveViewController.h"

@interface ViewController ()
@end

@implementation ViewController


-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.navigationItem.title = @"语音助手";
    
    UIButton *iflyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    iflyBtn.backgroundColor = [UIColor greenColor];
    [iflyBtn setTitle:@"科大讯飞语音转文本" forState:UIControlStateNormal];
    [iflyBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [iflyBtn addTarget:self action:@selector(iflyBtnAction) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *PrimitiveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    PrimitiveBtn.backgroundColor = [UIColor greenColor];
    [PrimitiveBtn setTitle:@"源生语音转文本" forState:UIControlStateNormal];
    [PrimitiveBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [PrimitiveBtn addTarget:self action:@selector(PrimitiveBtnAction) forControlEvents:UIControlEventTouchUpInside];

    
    iflyBtn.frame = CGRectMake(60, screenHeight/2-80, screenWidth-120, 40);
    PrimitiveBtn.frame = CGRectMake(60, screenHeight/2, screenWidth-120, 40);

    [self.view addSubview:iflyBtn];
    [self.view addSubview:PrimitiveBtn];
    
}


-(void)iflyBtnAction{
    IFLyMscViewController *vc = [IFLyMscViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)PrimitiveBtnAction{
    PrimitiveViewController *vc = [PrimitiveViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}






@end
