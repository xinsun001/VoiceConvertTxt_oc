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

#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface PrimitiveViewController ()<SFSpeechRecognitionTaskDelegate,SFSpeechRecognizerDelegate>

@property(nonatomic,strong)UILabel *txtLabel;
@property(nonatomic,strong)UITextView *textView;

@property(nonatomic,strong)UILabel *idenLabel;
@property(nonatomic,strong)UILabel *instLabel;

@property(nonatomic,strong)UILabel *languageLabel;
@property(nonatomic,strong)UIButton *languageButton;

@property(nonatomic,strong)UIButton *clearButton;
@property(nonatomic,strong)UIButton *coventButton;

@property(nonatomic,strong)NSString *languageStr;



@property (strong, nonatomic)SFSpeechRecognitionTask *recognitionTask; //语音识别任务
@property (strong, nonatomic)SFSpeechRecognizer *speechRecognizer; //语音识别器
@property (strong, nonatomic)SFSpeechAudioBufferRecognitionRequest *recognitionRequest; //识别请求
@property (strong, nonatomic)AVAudioEngine *audioEngine; //录音引擎

/** 监听设备 */
@property (nonatomic, strong) AVAudioRecorder *monitor;
/** 监听器 URL */
@property (nonatomic, strong) NSURL *monitorURL;
/** 定时器 */
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSTimeInterval nonVoiceInterVal;

@end

@implementation PrimitiveViewController

-(void)dealloc{
    [self stopAvaudio];
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
    
    NSLocale *cale = [[NSLocale alloc] initWithLocaleIdentifier:_languageStr];
    self.speechRecognizer = [[SFSpeechRecognizer alloc]initWithLocale:cale];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self checkSpeechFunction];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"源生语音";
    
    UIBarButtonItem *rightBtnitem = [[UIBarButtonItem alloc] initWithTitle:@"指令库" style:UIBarButtonItemStyleDone target:self action:@selector(getDataAction)];
    self.navigationItem.rightBarButtonItem = rightBtnitem;
    
    self.languageStr = zhCN;
    
    [self setSpeech];
    
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

#pragma mark- 录音器初始化

-(void)setSpeech{
    if (!_speechRecognizer){
        NSLocale *cale = [[NSLocale alloc] initWithLocaleIdentifier:self.languageStr];
        _speechRecognizer = [[SFSpeechRecognizer alloc]initWithLocale:cale];
        _speechRecognizer.delegate = self;
    }
    
    if (_audioEngine == nil) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    
    // 1. 音频会话
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    
    // 参数设置
    NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    //采样率
                                    [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                                    //录音格式
                                    [NSNumber numberWithInt: kAudioFormatAppleIMA4], AVFormatIDKey,
                                    //双声道
                                    [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                    //声音质量
                                    [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                                    nil];
    
    // 监听器
    NSString *monitorPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"monitor.caf"];
    _monitorURL = [NSURL fileURLWithPath:monitorPath];
    _monitor = [[AVAudioRecorder alloc] initWithURL:_monitorURL settings:recordSettings error:NULL];
    _monitor.meteringEnabled = YES;
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
        
        [self stopAvaudio];
        
        [self.coventButton setTitle:@"开始录音" forState:UIControlStateNormal];
        self.coventButton.selected = NO;
    }else{
        
        [self startAvaudio];
        
        [self.coventButton setTitle:@"结束录音" forState:UIControlStateNormal];
        self.coventButton.selected = YES;
    }
}

#pragma mark- 识别语音

- (void)setupTimer {
    self.nonVoiceInterVal = [[NSDate date] timeIntervalSince1970];
    [self.monitor record];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
}


// 结束的方法
- (void)updateTimer {

    [self.monitor updateMeters];
    
    // 音频功率的平均值,安静的办公室约为-80，完全没有声音-160.0，0是最大音量
    float power = [self.monitor peakPowerForChannel:0];
    
    self.instLabel.text = [NSString stringWithFormat:@"语音识别中...\n音频功率%.2f",power];

    if (power > -30) {
        self.nonVoiceInterVal = [[NSDate date] timeIntervalSince1970];

        
    }else{
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        
        if (self.textView.text.length>0) {
            if (now - self.nonVoiceInterVal > 1) {
                NSLog(@"本次录音结束");
                [self stopAvaudio];
            }
        }else{
            if (now - self.nonVoiceInterVal > 5) {
                NSLog(@"未获取到声音");
                [self stopAvaudio];
            }
        }
        
    }
    
}


- (void)startAvaudio{
    
    [SVProgressHUD showWithStatus:@"识别中..."];

    if (self.recognitionTask) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    AVAudioSession *audioSession = [AVAudioSession new];
    //音频类型，只播放
    BOOL cartoryBool = [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    //模式，最小系统
    BOOL modeBool = [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
    //通用配置，若有其他音频，先中断，自身播放器进程完毕后，其他音频继续
    BOOL activeBool = [audioSession setActive:true withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (cartoryBool || modeBool || activeBool) {
        
    }else{
        
        [SVProgressHUD showErrorWithStatus:@"设备不支持"];
        return;
    }
    
    //通过音频流创建请求
    self.recognitionRequest = [SFSpeechAudioBufferRecognitionRequest new];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    //持续回调，不是等到说完一句再回调
    self.recognitionRequest.shouldReportPartialResults = true;
        
    //创建识别任务
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        //语音处理是否完成
        BOOL isFinal = false;
        if (result) {
            NSString *bestStr = [[result bestTranscription] formattedString];
            isFinal = [result isFinal];
            
            self.textView.text = bestStr;
            
            if (isFinal) {
                [self funOfMethod];
            }
        }
        
        
        if (isFinal || error) {
            //暂停录音引擎
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            self.recognitionRequest = nil;
            self.recognitionTask = nil;
        }
    }];
    
    //创建avaudio为buffer类，输出设置，
    AVAudioFormat *recorfFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recorfFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        //拼接流文件
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];

    //准备引擎
    [self.audioEngine prepare];
    //开启音频引擎
    BOOL audioEngBool = [self.audioEngine startAndReturnError:nil];
    if (!audioEngBool) {
        [SVProgressHUD showErrorWithStatus:@"录音引擎启动失败"];
    }
    
    [self setupTimer];
    
}

- (void)stopAvaudio{
    
    //停止监听器并且删除文件
    [self.monitor stop];
    [self.monitor deleteRecording];
    [self.timer invalidate];
    [self.recognitionRequest endAudio];
    
    [self.coventButton setTitle:@"开始录音" forState:UIControlStateNormal];
    self.coventButton.selected = NO;
    
    [SVProgressHUD dismiss];
    
}

#pragma mark- 语音识别代理

-(void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        [SVProgressHUD showErrorWithStatus:@"录音不可使用"];
    }
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
