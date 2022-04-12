//
//  PrimitiveViewController.m
//  VoiceCoventTxt_oc
//
//  Created by facilityone on 2022/2/22.
//

#import "PrimitiveViewController.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "ChooseLanguageViewController.h"
#import "InstructionViewController.h"

#import <Masonry.h>
#import <MJExtension.h>

#import "LanguageModel.h"
#import "CoventModel.h"

#import "VoiceCoventTxtHelper.h"


@interface PrimitiveViewController ()

@property(nonatomic,strong)UILabel *txtLabel;
@property(nonatomic,strong)UITextView *textView;

@property(nonatomic,strong)UILabel *idenLabel;
@property(nonatomic,strong)UILabel *instLabel;

@property(nonatomic,strong)UILabel *languageLabel;
@property(nonatomic,strong)UIButton *languageButton;

@property(nonatomic,strong)UIButton *clearButton;
@property(nonatomic,strong)UIButton *coventButton;

@property(nonatomic,strong)NSString *languageStr;

@property (nonatomic, strong) VoiceCoventTxtHelper *voiceHelper;

@end

@implementation PrimitiveViewController

-(void)dealloc{
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

-(UILabel *)txtLabel{
    if (!_txtLabel) {
        _txtLabel = [UILabel new];
        _txtLabel.textColor = [UIColor blackColor];
        _txtLabel.text=@"识别文本:";
    }
    return _txtLabel;
}

-(UITextView *)textView{
    if (!_textView) {
        _textView = [UITextView new];
        _textView.layer.borderColor = [UIColor grayColor].CGColor;
        _textView.layer.borderWidth = 2;
        _textView.backgroundColor = [UIColor orangeColor];
        _textView.textColor = [UIColor blackColor];
        _textView.userInteractionEnabled = NO;
        _textView.font = [UIFont systemFontOfSize:15];
    }
    return _textView;
}

-(UILabel *)idenLabel{
    if (!_idenLabel) {
        _idenLabel = [UILabel new];
        _idenLabel.textColor = [UIColor blackColor];
        _idenLabel.text=@"匹配指令:";
    }
    return _idenLabel;
}

-(UILabel *)instLabel{
    if (!_instLabel) {
        _instLabel = [UILabel new];
        _instLabel.numberOfLines = 0;
        _instLabel.textColor = [UIColor blackColor];
        _instLabel.layer.borderColor = [UIColor orangeColor].CGColor;
        _instLabel.layer.borderWidth = 1;
    }
    return _instLabel;
}

-(UILabel *)languageLabel{
    if (!_languageLabel) {
        _languageLabel = [UILabel new];
        _languageLabel.textColor = [UIColor blackColor];
        _languageLabel.text = @"点击切换语言:";
    }
    return _languageLabel;
}

-(UIButton *)languageButton{
    if (!_languageButton) {
        _languageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_languageButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_languageButton setTitle:@"中文" forState:UIControlStateNormal];
        _languageButton.layer.borderColor = [UIColor grayColor].CGColor;
        _languageButton.layer.borderWidth = 1;
        [_languageButton addTarget:self action:@selector(languageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _languageButton;
}

-(void)languageButtonAction{
    
    [self jumpChooseLanguage];
    
}

-(UIButton *)clearButton{
    if (!_clearButton) {
        _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_clearButton setTitle:@"清除" forState:UIControlStateNormal];
        _clearButton.backgroundColor = [UIColor orangeColor];
        [_clearButton addTarget:self action:@selector(clearButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clearButton;
}

-(void)clearButtonAction{
    self.instLabel.text = @"";
    self.textView.text = @"";
}

-(UIButton *)coventButton{
    if (!_coventButton) {
        _coventButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_coventButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_coventButton setTitle:@"开始录音" forState:UIControlStateNormal];
        _coventButton.backgroundColor = [UIColor orangeColor];
        [_coventButton addTarget:self action:@selector(coventButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _coventButton;
}

-(void)coventButtonAction{

    [self startSpeech];

}


#pragma mark- 查看指令库

-(void)getDataAction{
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"instruction" ofType:@"plist"];
    NSArray  *fileArray = [NSArray arrayWithContentsOfFile:filePath];
    NSArray *modelArray=[CoventModel mj_objectArrayWithKeyValuesArray:fileArray];

    InstructionViewController *vc = [InstructionViewController new];
    vc.instructionArray = modelArray;
    [self.navigationController pushViewController:vc animated:YES];
    
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"源生语音";
    
    UIBarButtonItem *rightBtnitem = [[UIBarButtonItem alloc] initWithTitle:@"指令库" style:UIBarButtonItemStyleDone target:self action:@selector(getDataAction)];
    self.navigationItem.rightBarButtonItem = rightBtnitem;
    
    self.languageStr = zhCN;
    
    __weak typeof(self)  weakSelf=self;

    self.voiceHelper = [VoiceCoventTxtHelper new];
    [self.voiceHelper checkSpeechFunction:^(NSString * _Nonnull str) {
        //初始化语音交互窗口
        [weakSelf showAlert:str];
    } andFail:^(NSString * _Nonnull str) {
        [weakSelf showAlert:str];
    }];
    
    [self setUI];
    
}

#pragma mark- 录音操作

-(void)startSpeech{
    
    self.textView.text = @"";
   
    if (self.coventButton.isSelected) {
        [self stopAvaudio];
    }else{
        [self startAvaudio];
    }
}

- (void)startAvaudio{
    [self.coventButton setTitle:@"结束录音" forState:UIControlStateNormal];
    self.coventButton.selected = YES;
    [self setSpeech];
    
}

- (void)stopAvaudio{
    
    [self.voiceHelper stopAvaudio];
    [self.coventButton setTitle:@"开始录音" forState:UIControlStateNormal];
    self.coventButton.selected = NO;
    [SVProgressHUD dismiss];
    
}

-(void)showAlert:(NSString *)str{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil  message:str preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"确定", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark- 录音器初始化

-(void)setSpeech{
    __weak typeof(self)  weakSelf=self;
    
    //语音输入状态已改变
    [self.voiceHelper setSpeehStatusChangeBlock:^(NSString * _Nonnull str) {
        [weakSelf showAlert:str];
    }];
    
    //5秒内没检测到声音
    [self.voiceHelper setNoVoiceBlock:^{
        //显示未检测到声音
        weakSelf.textView.text = @"未检测到声音";
        [weakSelf stopAvaudio];
    }];
    
    //说完话几秒内没有声音
    [self.voiceHelper setOverVoiceBlock:^{
        [weakSelf stopAvaudio];
//        NSLog(@"捕获语音信息----\n%@",weakSelf..text);
    }];
    
    dispatch_queue_t asynchronousQueue = dispatch_queue_create("voiceStart", NULL);
    dispatch_async(asynchronousQueue, ^{
        [self.voiceHelper setSpeech];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.voiceHelper startAvaudio:^(NSString * _Nonnull str) {
//                NSLog(@"检测到了语音---\n%@",str);
                weakSelf.textView.text = str;
            } andFinish:^(NSString * _Nonnull str) {
//                NSLog(@"最终的语音转文字---\n%@",str);
                weakSelf.textView.text = str;
                if (str.length > 0) {
                    [weakSelf funOfMethod];
                }
                [weakSelf stopAvaudio];
            } andDeviceFail:^(NSString * _Nonnull str) {
                [weakSelf showAlert:str];
                [weakSelf stopAvaudio];
            } andAudioFail:^(NSString * _Nonnull str) {
                [weakSelf showAlert:str];
                [weakSelf stopAvaudio];
            }];
        });
    });
    
    [self.voiceHelper setStopAudioBlock:^{
        //延迟一秒才可以点击
        weakSelf.coventButton.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^ {
            weakSelf.coventButton.userInteractionEnabled = YES;
        });
    }];
}


#pragma mark- 设置UI

-(void)setUI{
    
    __weak typeof(self)  weakSelf=self;
    
    [self.view addSubview:self.txtLabel];
    [self.view addSubview:self.textView];
    [self.txtLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.view).offset(30);
        make.top.equalTo(weakSelf.view.mas_top).offset(20+88);
    }];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(screenWidth-60);
        make.top.equalTo(weakSelf.txtLabel.mas_bottom).offset(10);
        make.height.mas_equalTo(80);
        make.centerX.equalTo(weakSelf.view);
    }];
    
    [self.view addSubview:self.idenLabel];
    [self.view addSubview:self.instLabel];
    [self.idenLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.view).offset(30);
        make.top.equalTo(weakSelf.textView.mas_bottom).offset(10);
    }];
    
    [self.instLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(screenWidth-60);
        make.top.equalTo(weakSelf.idenLabel.mas_bottom).offset(10);
        make.height.mas_equalTo(screenHeight/4-20);
        make.centerX.equalTo(weakSelf.view);
    }];
    
    [self.view addSubview:self.languageLabel];
    [self.view addSubview:self.languageButton];
    [self.languageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.view).offset(-50);
        make.top.equalTo(weakSelf.instLabel.mas_bottom).offset(50);
    }];
    
    [self.languageButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.languageLabel.mas_centerY);
        make.leading.equalTo(weakSelf.languageLabel.mas_trailing).offset(10);
        make.height.mas_equalTo(35);
        make.width.mas_equalTo(100);
    }];
    
    [self.view addSubview:self.clearButton];
    [self.view addSubview:self.coventButton];
    [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo((screenWidth-60-30)/2);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(-60);
        make.height.mas_equalTo(40);
        make.leading.equalTo(weakSelf.view.mas_leading).offset(30);
    }];
    
    [self.coventButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo((screenWidth-60-30)/2);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(-60);
        make.height.mas_equalTo(40);
        make.trailing.equalTo(weakSelf.view.mas_trailing).offset(-30);
    }];
    
    
    
}

#pragma mark- 选择语言

-(void)jumpChooseLanguage{
    
    __weak typeof(self)  weakSelf=self;

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"language" ofType:@"plist"];
    NSArray  *fileArray = [NSArray arrayWithContentsOfFile:filePath];
    NSArray *modelArray=[LanguageModel mj_objectArrayWithKeyValuesArray:fileArray];

    ChooseLanguageViewController *vc = [ChooseLanguageViewController new];
    vc.languageArray = modelArray;
    [vc setClickLanguageBlock:^(LanguageModel * _Nonnull model) {
        [weakSelf.languageButton setTitle:model.name forState:UIControlStateNormal];
        weakSelf.languageStr = model.desc;
    }];
    [self.navigationController pushViewController:vc animated:YES];
    
}

#pragma mark- 在本地方法库中寻找

-(int )getLanguageCartoryNum{
    if ([self.languageStr isEqualToString:zhCN]) {
        return 1;
    }else if ([self.languageStr isEqualToString:enGB]){
        return 2;
    }else{
        //为0表示还为寻找到
        return 0;
    }
}

-(void)funOfMethod{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"instruction" ofType:@"plist"];
    NSArray  *fileArray = [NSArray arrayWithContentsOfFile:filePath];
    NSArray *modelArray=[CoventModel mj_objectArrayWithKeyValuesArray:fileArray];

    for (CoventModel *searchModel in modelArray) {
        switch ([self getLanguageCartoryNum]) {
            case 1:
                [self getSearchStr:searchModel andContainStr:searchModel.zh_CN];
                break;
            default:
                self.instLabel.text = @"本地库中未查询到";
                break;
        }
    }
}

-(void)getSearchStr:(CoventModel *)searchModel andContainStr:(NSString *)containStr{
    NSString *txtofTextView = self.textView.text;
    if ([txtofTextView containsString:containStr]) {
        NSString *showStr = [NSString stringWithFormat:@"%@值:\n中文:%@\n%@值:\n执行方法:%@",@"key",containStr,@"value",searchModel.function];
        self.instLabel.text = showStr;
        [self funcMothodAction:searchModel.function];
    }else{
        self.instLabel.text = @"本地库中未查询到";
    }
}

-(void)funcMothodAction:(NSString *)funStr{
    
    if ([funStr isEqualToString:@"speechBackDeskTop"]) {
        [self speechBackDeskTop];
    }else if ([funStr isEqualToString:@"speechChooseLanguage"]){
        [self jumpChooseLanguage];
    }
    
    
}

-(void)speechBackDeskTop{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"退出APP" message:@"APP将要回到桌面" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        UIWindow *window = app.window;
        [UIView animateWithDuration:1.0f animations:^{
            window.alpha = 0;
            window.frame = CGRectMake(0, window.bounds.size.width, 0, 0);
        } completion:^(BOOL finished) {
            exit(0);
        }];

    }];
    
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:^{
        
    }];
    
    
}


@end
