//
//  ViewController.m
//  home2scratch
//
//  Created by Junya Ishihara on 2015/06/29.
//  Copyright (c) 2015年 Tsukurusha LLC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

    [centralManager setDelegate:self];

    _btnScan.enabled = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if(central.state == CBCentralManagerStatePoweredOn) {
        _btnScan.enabled = true;
        _txtStatus.text = @"初期化完了";
    }
}

- (IBAction)OnBtnScan:(id)sender {
    _txtStatus.text = @"スキャン中";
    NSLog(@"Scanning...");
    [centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {

    //スキャンの終了
    [centralManager stopScan];

    _txtStatus.text = @"ペリフェラル検知";

    NSLog(@"Detected peripheral");
    NSLog(@"advertisementData: %@", advertisementData);

    NSData *data = advertisementData[@"kCBAdvDataManufacturerData"];

    if (data) {
        const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
        int16_t temperature = (dataBuffer[4] | (dataBuffer[5] << 8));
        NSLog(@"temp: %d", temperature);

        _txtTemperature.text = [NSString stringWithFormat:@"%d", temperature];
    }

//    int16_t temperature = 10;
//    NSLog(@"temp: %d", temperature);
//
//    _txtTemperature.text = [NSString stringWithFormat:@"%d", temperature];
}

@end
