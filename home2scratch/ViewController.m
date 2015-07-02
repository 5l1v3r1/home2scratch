//
//  ViewController.m
//  home2scratch
//
//  Created by Junya Ishihara on 2015/06/29.
//  Copyright (c) 2015年 Tsukurusha LLC. All rights reserved.
//

#import "ViewController.h"
#import "Utilities.h"

#define PORT 42001
#define MAX_RETRY 10

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

    [centralManager setDelegate:self];

    _btnScan.enabled = false;


    // initialize network related variables
    NSString *currentIPAddress = [Utilities currentIPAddress];
    NSArray *numbers = [currentIPAddress componentsSeparatedByString: @"."];
    ipRange = [NSString stringWithFormat:@"%@.%@.%@.", numbers[0], numbers[1], numbers[2]];
    lastNumberOfIPAddress = 1;
    retryCount = 0;
    autoConnecting = NO;

    _hostAddressTextField.text = ipRange;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectButtonTouchDown:(id)sender {
    retryCount = MAX_RETRY;
    [self disconnect];
    
    lastNumberOfIPAddress = 1;
    
    NSArray *numbers = [_hostAddressTextField.text componentsSeparatedByString: @"."];
    if ([numbers count] == 4 && [numbers[0] length] > 0 && [numbers[1] length] > 0 && [numbers[2] length] > 0 && [numbers[3] length] > 0) {
        autoConnecting = NO;
        hostAddress = _hostAddressTextField.text;
        [self connectToScratch];
    } else {
        autoConnecting = YES;
        [self autoConnect];
    }
}

- (void)sensorUpdate:(NSDictionary *)sensors {
    if (asyncSocket.isDisconnected){
        return;
    }
    
    NSMutableArray *sensorPairs = [[NSMutableArray alloc] init];
    for (id key in [sensors keyEnumerator]) {
        [sensorPairs addObject:[NSString stringWithFormat:@"\"%@\" %@", key, sensors[key]]];
    }
    NSString *message = [NSString stringWithFormat:@"sensor-update %@", [sensorPairs componentsJoinedByString:@" "]];
    NSData *data = [[NSString stringWithString:message] dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *toSend;
    Byte *toAppend = (Byte*)malloc(4);
    
    toAppend[0]=(([data length] >> 24) & 0xFF);
    toAppend[1]=(([data length] >> 16) & 0xFF);
    toAppend[2]=(([data length] >> 8) & 0xFF);
    toAppend[3]=([data length] & 0xFF);
    
    toSend = [NSMutableData dataWithBytes:toAppend length:4];
    [toSend appendData:data];
    
    [asyncSocket writeData:toSend withTimeout:-1 tag:0];
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
        
        NSDictionary *sensors = @{
                                  @"temperature": [[NSNumber alloc] initWithDouble:temperature / 100.0],
                                  @"temperaturex100": [[NSNumber alloc] initWithDouble:temperature]
                                  };
        [self sensorUpdate:sensors];
    }

    //int16_t temperature = 2700;
    //NSLog(@"temp: %d", temperature);

    //_txtTemperature.text = [NSString stringWithFormat:@"%d", temperature];
    
    //NSDictionary *sensors = @{
    //                          @"temperature": [[NSNumber alloc] initWithDouble:temperature / 100.0]
    //                          };
    //[self sensorUpdate:sensors];
}

- (void)showMessage:(NSString *)message {
    _debugMessageTextField.text = message;
}

- (void)tap:(UIGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}

- (void)dealloc
{
    [asyncSocket setDelegate:nil delegateQueue:NULL];
    [asyncSocket disconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark GCDAsyncSocket
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)connectToScratch {
    NSLog(@"Connecting... %@:%d", hostAddress, PORT);
    [self showMessage: [NSString stringWithFormat:@"Connecting... %@:%d", hostAddress, PORT]];
    NSError *error = nil;
    if (![asyncSocket connectToHost:hostAddress onPort:PORT withTimeout: 0.2 error:&error])
    {
        [self showMessage:error.localizedDescription];
        NSLog(@"Connection Error: %@", error);
    }
}

- (void)processMessage:(NSString *)message
{
    if ([message hasPrefix:@"broadcast"]) {
        NSString *action = [message substringWithRange:NSMakeRange(11, [message length] - 12)];
        NSLog(@"action: %@", action);
    } else if ([message hasPrefix:@"sensor-update"]) {
        NSString *pairs = [message substringWithRange:NSMakeRange(14, [message length] - 14)];
        NSArray *array = [pairs componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        for (int i = 0; i < [array count] - 1; i+=2) {
            NSString *varName = array[i];
            NSString *newValue = array[i+1];
            
            int intNewValue;
            // Write an action that triggered by changing Scratch values.
        }
    }
    [NSThread sleepForTimeInterval:0.1f];
}

- (void)disconnect {
    [asyncSocket disconnect];
}

- (void) autoConnect {
    hostAddress = [NSString stringWithFormat:@"%@%d", ipRange, lastNumberOfIPAddress];
    [self connectToScratch];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSString *message = [NSString stringWithFormat:@"Connected to %@", host];
    [self showMessage:message];
    NSLog(@"%@", message);
    
    _hostAddressTextField.text = host;
    autoConnecting = NO;
    retryCount = 0;
    
    [asyncSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    int dataLength = [data length];
    int processedDataLength = 0;
    
    while (processedDataLength < dataLength) {
        UInt8 dataBytes[1024];
        
        [data getBytes:dataBytes range:NSMakeRange(processedDataLength, 4)];
        NSData *lengthData = [NSData dataWithBytes:dataBytes length:4];
        int length = CFSwapInt32BigToHost(*(int*)([lengthData bytes]));
        
        [data getBytes:dataBytes range:NSMakeRange(processedDataLength + 4, length)];
        NSData *messageData = [NSData dataWithBytes:dataBytes length:length];
        NSString *message = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
        NSLog(@"message: %@", message);
        
        [self processMessage:message];
        processedDataLength += (length + 4);
    }
    
    [asyncSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [self showMessage:@"Disconnected."];
    NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
    if (autoConnecting) {
        if (lastNumberOfIPAddress < 255) {
            hostAddress = [NSString stringWithFormat:@"%@%d", ipRange, lastNumberOfIPAddress];
            [self connectToScratch];
            lastNumberOfIPAddress++;
        }
    } else {
        if (retryCount < MAX_RETRY) {
            NSLog(@"retry %d", retryCount);
            [self performSelector:@selector(connectToScratch) withObject:nil afterDelay:5.0f];
            retryCount++;
        }
    }
}

@end
