//
//  IFLyMscViewController.m
//  VoiceCoventTxt_oc
//
//  Created by facilityone on 2022/2/22.
//

#import "IFLyMscViewController.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "ChooseLanguageViewController.h"
#import "InstructionViewController.h"
#import <Masonry.h>
#import <MJExtension.h>

#import "LanguageModel.h"
#import "CoventModel.h"

#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

#import "iflyMSC.framework/Headers/IFlyMSC.h"
#import "ISRDataHelper.h"


#define screenHeight [UIScreen mainScreen].bounds.size.height
#define screenWidth [UIScreen mainScreen].bounds.size.width

#define APPID_VALUE           @"5a127423"


@interface IFLyMscViewController ()<IFlySpeechRecognizerDelegate>

@property(nonatomic,strong)UILabel *txtLabel;
@property(nonatomic,strong)UITextView *textView;

@property(nonatomic,strong)UILabel *idenLabel;
@property(nonatomic,strong)UILabel *instLabel;

@property(nonatomic,strong)UILabel *languageLabel;
@property(nonatomic,strong)UIButton *languageButton;

@property(nonatomic,strong)UIButton *clearButton;
@property(nonatomic,strong)UIButton *coventButton;

@property(nonatomic,strong)NSString *languageStr;

@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;


@end

@implementation IFLyMscViewController

-(void)dealloc{
    
    [self onEndOfSpeech];
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

//-(void)getlange{
//
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    NSArray* languages = [defaults objectForKey:@"AppleLanguages"];
//}


-(void)setLanguageStr:(NSString *)languageStr{
    _languageStr = languageStr;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self checkSpeechFunction];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", APPID_VALUE];
    [IFlySpeechUtility createUtility:initString];
    
    self.navigationItem.title = @"科大讯飞";
    
    UIBarButtonItem *rightBtnitem = [[UIBarButtonItem alloc] initWithTitle:@"指令库" style:UIBarButtonItemStyleDone target:self action:@selector(getDataAction)];
    self.navigationItem.rightBarButtonItem = rightBtnitem;
    
    self.languageStr = @"zh_CN";
    
    [self setIFlySpeech];
    
    [self setUI];
    
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

#pragma mark- 科大讯飞初始化

-(void)setIFlySpeech{
    if (!_iFlySpeechRecognizer) {
        //创建语音识别对象
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        _iFlySpeechRecognizer.delegate = self;
        //设置识别参数
        //应用领域，设置为听写模式
        [_iFlySpeechRecognizer setParameter: @"iat" forKey: [IFlySpeechConstant IFLY_DOMAIN]];
        //asr_audio_path 是录音文件路径，设置value为nil或者为空取消保存，默认保存目录在Library/cache下。
        [_iFlySpeechRecognizer setParameter:@"iat.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        //前后断点检测，区别录音前后的静音时长。前端默认5000ms，后端1800ms,范围均为0-10000ms
        [_iFlySpeechRecognizer setParameter:@"2000" forKey:[IFlySpeechConstant VAD_EOS]];
        [_iFlySpeechRecognizer setParameter:@"3000" forKey:[IFlySpeechConstant VAD_BOS]];
        //网络连接超时时间
        [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
        //合成识别等采样率，8khz和16khz
        [_iFlySpeechRecognizer setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
        //语言
        [_iFlySpeechRecognizer setParameter:self.languageStr forKey:[IFlySpeechConstant LANGUAGE]];
        //方言，LANGUAGE为中文时支持，设置为mandarin
        [_iFlySpeechRecognizer setParameter:@"mandarin" forKey:[IFlySpeechConstant ACCENT]];
        //是否有标点，1开启
        [_iFlySpeechRecognizer setParameter:@"1" forKey:[IFlySpeechConstant ASR_PTT]];
        
    }
    
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


#pragma mark- 检测授权状态

-(void)checkSpeechFunction{
    [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    [self setCovenState:NO andShowStr:@"语音识别未授权"];
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    [self setCovenState:NO andShowStr:@"用户拒接使用语音识别"];
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    [self setCovenState:NO andShowStr:@"设备不支持语音识别"];
                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    [self setCovenState:YES andShowStr:@"可以进行语音识别"];
                    break;
                    
                default:
                    break;
            }
            
        });
    }];
}

-(void)setCovenState:(BOOL )enable andShowStr:(NSString *)str{
    
    if (!enable) {
        self.coventButton.backgroundColor = [UIColor lightGrayColor];
        self.coventButton.userInteractionEnabled = NO;
        [SVProgressHUD showErrorWithStatus:str];
    }else{
        self.coventButton.backgroundColor = [UIColor orangeColor];
        self.coventButton.userInteractionEnabled = YES;
        [SVProgressHUD showSuccessWithStatus:str];
    }
    
    
}

#pragma mark- 录音操作

-(void)startSpeech{
    
    self.textView.text = @"";
   
    if (self.coventButton.isSelected) {
        [_iFlySpeechRecognizer stopListening];
        
        [self.coventButton setTitle:@"开始录音" forState:UIControlStateNormal];
        self.coventButton.selected = NO;

    }else{
        //启动识别服务
        [_iFlySpeechRecognizer startListening];
      
        [self.coventButton setTitle:@"结束录音" forState:UIControlStateNormal];
        self.coventButton.selected = YES;
    }
    
}


#pragma mark- IFlySpeechRecognizerDelegate协议实现
//识别结果返回代理
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast{
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    
    NSString *resultFromJson = [ISRDataHelper stringFromJson:resultString];

    self.textView.text = [self.textView.text stringByAppendingFormat:@"%@", resultFromJson];
    
}
//识别会话结束返回代理
- (void)onCompleted: (IFlySpeechError *) error{
    
    if (error && error.errorCode != 0) {
        [SVProgressHUD showErrorWithStatus:error.description];
    }else{
        [self funOfMethod];
    }
}
//停止录音回调
- (void) onEndOfSpeech{
    self.clearButton.userInteractionEnabled = YES;
    self.languageButton.userInteractionEnabled = YES;
    
    [_iFlySpeechRecognizer stopListening];
    [self.coventButton setTitle:@"开始录音" forState:UIControlStateNormal];
    self.coventButton.selected = NO;
    
    [SVProgressHUD dismiss];
    
}
//开始录音回调
- (void) onBeginOfSpeech{
    self.clearButton.userInteractionEnabled = NO;
    self.languageButton.userInteractionEnabled = NO;
    
    [SVProgressHUD showWithStatus:@"录音中..."];
    
}
//音量回调函数
- (void) onVolumeChanged: (int)volume{
    
    self.instLabel.text = [NSString stringWithFormat:@"语音识别中...\n音量%d",volume];
    
    
}
//会话取消回调
- (void) onCancel{}


#pragma mark- 在本地方法库中寻找


-(int )getLanguageCartoryNum{
    if ([self.languageStr isEqualToString:@"zh_CN"]) {
        return 1;
    }else if ([self.languageStr isEqualToString:@"en_GB"]){
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
            case 2:
                
                break;
            default:
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
