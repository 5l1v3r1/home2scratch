//
//  ViewController.h
//  home2scratch
//
//  Created by Junya Ishihara on 2015/06/29.
//  Copyright (c) 2015年 Tsukurusha LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<CBCentralManagerDelegate>
{
    CBCentralManager *centralManager;
}


//画面関連

@property (weak, nonatomic) IBOutlet UIButton *btnScan;

@property (weak, nonatomic) IBOutlet UITextField *txtTemperature;

@property (weak, nonatomic) IBOutlet UITextField *txtStatus;

- (IBAction)OnBtnScan:(id)sender;

@end
