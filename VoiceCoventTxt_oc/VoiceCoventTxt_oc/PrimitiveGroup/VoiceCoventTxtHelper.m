//
//  VoiceCoventTxtHelper.m
//  client_ios_fm_a
//
//  Created by xinsun001 on 2022/3/22.
//  Copyright © 2022 xinsun001. All rights reserved.
//

#import "VoiceCoventTxtHelper.h"

@implementation VoiceCoventTxtHelper

-(void)setGetSpeechStr:(NSString *)getSpeechStr{
    _getSpeechStr = getSpeechStr;
}

#pragma mark- 检测授权状态
//plist文件添加语音识别权限，否则会崩溃Privacy - Speech Recognition Usage Description
-(void)checkSpeechFunction:(successBlock)sucBlock andFail:(failBlock)failBlock{
    [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    failBlock([self getSpeechStatus:NotDetermined]);
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    failBlock([self getSpeechStatus:Denied]);
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    failBlock([self getSpeechStatus:Restricted]);
                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    sucBlock([self getSpeechStatus:Authorized]);
                    break;
                default:
                    break;
            }
        });
    }];
}

-(NSString *)getSpeechStatus:(NSInteger )status{
    NSString *statusStr;
    switch (status) {
        case 0:
            statusStr = @"语音识别未授权";
            break;
        case 1:
            statusStr = @"用户拒接使用语音识别";
            break;
        case 2:
            statusStr = @"设备不支持语音识别";
            break;
        case 3:
            statusStr = @"可以进行语音识别";
            break;
        default:
            break;
    }
    return statusStr;
}

#pragma mark- 录音器初始化
-(void)setSpeech{
    if (!_speechRecognizer){
        NSLocale *cale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
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
                                    //声道，录制仅需单声道即可
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    //线性采样位数
                                    [NSNumber numberWithInt:32], AVLinearPCMBitDepthKey,
                                    //编码比特率
                                    [NSNumber numberWithInt:128000], AVEncoderBitRateKey,
                                    //声音质量
                                    [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                                    nil];
    
    // 监听器
    NSString *monitorPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"monitor.caf"];
    _monitorURL = [NSURL fileURLWithPath:monitorPath];
    _monitor = [[AVAudioRecorder alloc] initWithURL:_monitorURL settings:recordSettings error:NULL];
    _monitor.meteringEnabled = YES;
}

#pragma mark- 识别语音
- (void)setupTimer {
    //给定一个初始值
    self.nonVoiceInterVal = [[NSDate date] timeIntervalSince1970];
    [self setNonVoiceInterVal:self.nonVoiceInterVal];

    [self.monitor record];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
}

// 结束的方法
- (void)updateTimer {

    [self.monitor updateMeters];
    // 音频功率的平均值,安静的办公室约为-80，完全没有声音-160.0，0是最大音量
    float power = [self.monitor peakPowerForChannel:0];
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    //正常办公室（不安静也不算吵）环境约-35左右
    if (power > -20) {
        self.nonVoiceInterVal = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"环境比较吵闹");
    }
    
    NSInteger voiceNone = now - self.nonVoiceInterVal;
    NSLog(@"静音时间差%ld",(long)voiceNone);
    
    if (self.getSpeechStr.length>0) {
        //出声后静音2秒结束录音
        if (voiceNone > 3) {
            NSLog(@"本次录音结束");
            if (self.overVoiceBlock) {
                self.overVoiceBlock();
            }
            [self stopAvaudio];
        }
    }else{
        //开始录音后5秒内未获取到声音结束录音
        if (voiceNone > 5) {
            NSLog(@"未获取到声音");
            if (self.noVoiceBlock) {
                self.noVoiceBlock();
            }
            [self stopAvaudio];
        }
    }
}

- (void)startAvaudio:(speechListenBlock)listenBlock andFinish:(speechFinshBlock)finshBlock andDeviceFail:(deviceFailBlock)deviceBlock andAudioFail:(startAudioFailBlock)audioBlock{
    
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
        //设备不支持
        deviceBlock(@"设备不支持");
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
            
            listenBlock(bestStr);
            
            self.getSpeechStr = bestStr;
            
            if (isFinal) {
                //如果语音输入已完成，进行识别查询
                finshBlock(bestStr);
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
        audioBlock(@"录音引擎启动失败");
        return;
    }
    
    [self setupTimer];
    
}

- (void)stopAvaudio{
    
    //停止监听器并且删除文件
    [self.monitor stop];
    [self.monitor deleteRecording];
    [self.timer invalidate];
    [self.recognitionRequest endAudio];
    
    if (self.stopAudioBlock) {
        self.stopAudioBlock();
    }
    
}


#pragma mark- 语音识别代理
-(void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        //识别器发生变化，无法使用
        [self stopAvaudio];
        if (self.speehStatusChangeBlock) {
            self.speehStatusChangeBlock(@"识别器状态发生变化，无法识别语音");
        }
    }
}

@end
