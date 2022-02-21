//
//  ChooseLanguageViewController.h
//  VoiceCoventTxt_oc
//
//  Created by facilityone on 2022/2/17.
//

#import <UIKit/UIKit.h>
#import "LanguageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChooseLanguageViewController : UIViewController

@property(nonatomic,strong)NSArray *languageArray;

@property(nonatomic,copy)void(^clickLanguageBlock)(LanguageModel *model);

@end

NS_ASSUME_NONNULL_END
