//
//  VoiceCoventTxtHelper.h
//  client_ios_fm_a
//
//  Created by xinsun001 on 2022/3/22.
//  Copyright © 2022 xinsun001. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MJExtension.h>
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

//授权检测
typedef void(^successBlock)(NSString *str);
typedef void(^failBlock)(NSString *str);

//获取语音转文字的结果
typedef void(^speechListenBlock)(NSString *str);

typedef void(^speechFinshBlock)(NSString *str);
//设备不支持
typedef void(^deviceFailBlock)(NSString *str);
//录音器启动失败
typedef void(^startAudioFailBlock)(NSString *str);

typedef NS_ENUM(NSInteger, SFSpeechRecognizerStatus) {
    NotDetermined,    //语音识别未授权
    Denied,    //用户拒绝使用语音识别
    Restricted,        //设备不支持语音识别
    Authorized          //可以进行语音识别
};


@interface VoiceCoventTxtHelper : NSObject<SFSpeechRecognitionTaskDelegate,SFSpeechRecognizerDelegate>

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

//语音识别的文本
@property (nonatomic, strong) NSString *getSpeechStr;

//识别器状态变得不可用
@property(nonatomic,copy)void (^speehStatusChangeBlock)(NSString *str);

//关闭录音功能
@property(nonatomic,copy) void(^stopAudioBlock)(void);

//说话后三秒视为录入完成
@property(nonatomic,copy) void(^overVoiceBlock)(void);

//5秒内没声音关闭录音器
@property(nonatomic,copy) void(^noVoiceBlock)(void);

#pragma mark- 检测授权状态
-(void)checkSpeechFunction:(successBlock)sucBlock andFail:(failBlock)failBlock;

#pragma mark- 录音器初始化
-(void)setSpeech;

#pragma mark- 开始(停止)录音
- (void)startAvaudio:(speechListenBlock)listenBlock andFinish:(speechFinshBlock)finshBlock andDeviceFail:(deviceFailBlock)deviceBlock andAudioFail:(startAudioFailBlock)audioBlock;
- (void)stopAvaudio;



@end

NS_ASSUME_NONNULL_END
