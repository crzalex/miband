//
//  AppDelegate.m
//  miband-ble
//
//  Created by Alex Cruz on 5/20/16.
//  Copyright © 2016 BlackWizards. All rights reserved.
//

#import "AppDelegate.h"
#import "MBBatteryInfoModel.h"
#import "MBDeviceInfoModel.h"
#import "MBUserInfoModel.h"

@interface AppDelegate ()
@property (nonatomic, strong) CBCentralManager *myCentralManager;
@property (nonatomic, strong) CBPeripheral     *miBandPeripheral;
@property (nonatomic, strong) NSString   *connected;
@property (nonatomic, strong) NSString   *deviceInfo;
@property (nonatomic, strong) NSString   *bodyData;
@property (nonatomic, strong) NSString   *manufacturer;
@property (assign) uint16_t heartRate;
@property (nonatomic, strong) NSString    *heartRateBPM;
@property (nonatomic, retain) NSTimer    *pulseTimer;




@end
#define UUID_SERVICE_MIBAND_SERVICE @"FEE0"
#define UUID_SERVICE_HEART_RATE @"180D"

#define UUID_CHARACTERISTIC_DEVICE_INFO @"FF01"
#define UUID_CHARACTERISTIC_DEVICE_NAME @"FF02"

#define UUID_CHARACTERISTIC_NOTIFICATION @"FF03"
#define UUID_CHARACTERISTIC_USER_INFO @"FF04"
#define UUID_CHARACTERISTIC_CONTROL_POINT @"FF05"
#define UUID_CHARACTERISTIC_REALTIME_STEPS @"FF06"
#define UUID_CHARACTERISTIC_ACTIVITY_DATA @"FF07"
#define UUID_CHARACTERISTIC_FIRMWARE_DATA @"FF08"
#define UUID_CHARACTERISTIC_LE_PARAMS @"FF09"
#define UUID_CHARACTERISTIC_DATE_TIME @"FF0A"
#define UUID_CHARACTERISTIC_STATISTICS @"FF0B"
#define UUID_CHARACTERISTIC_BATTERY @"FF0C"
#define UUID_CHARACTERISTIC_TEST @"FF0D"
#define UUID_CHARACTERISTIC_SENSOR_DATA @"FF0E"
#define UUID_CHARACTERISTIC_PAIR @"FF0F"
#define UUID_CHARACTERISTIC_HEART_RATE_CONTROL_POINT  @"2A39"
#define UUID_CHARACTERISTIC_HEART_RATE_MEASUREMENT @"2A37"


@implementation AppDelegate
- (void) getBatteryState:(CBCharacteristic *)characteristic
{
    MBBatteryInfoModel *bat = [[MBBatteryInfoModel alloc]initWithData:characteristic.value];
    NSLog(@"%@", bat.description);
    /*NSData *data = [NSData dataWithData:characteristic.value];
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);
    len = sizeof(byteData);
    if(len >= 10){
        int value = byteData[9];
        switch (value) {
            case 0:
                NSLog(@"Battery Normal");
                break;
            case 1:
                NSLog(@"Battery Low");
                break;
            case 2:
                NSLog(@"Charging ...");
                break;
            case 3:
                NSLog(@"Battery Full");
                break;
            case 4:
                NSLog(@"Battery Charge Off");
                break;
            default:
                NSLog(@"Battery State Unknown");
                break;
        }
    }*/
    return;
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}
// Step 2 Connect to peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSString *serviceAddress = [NSString stringWithFormat:@"%x", 0xFEE0];
    CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceAddress];
    [peripheral discoverServices:@[ serviceUUID ] withBlock:^(NSArray *services, NSError *error) {
        __weak typeof(self) weakSelf = self;
        if (error || [services count] == 0) {   //found services error.
            if (error == nil) {
                error = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:0
                                        userInfo:@{ NSLocalizedDescriptionKey: @"No services found." }];
            }
            [weakSelf executeConnectResultBlockInMainThread:peripheral withError:error];
        } else {
            [peripheral discoverCharacteristics:nil
                                     forService:peripheral.service
                                      withBlock:^(NSArray *characteristics, NSError *error) {
                                          if (error == nil && [characteristics count] == 0) {
                                              error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                                          code:0
                                                                      userInfo:@{ NSLocalizedDescriptionKey: @"No characteristics found." }];
                                          }
                                          [weakSelf executeConnectResultBlockInMainThread:peripheral withError:error];
                                      }];
        }
    }];
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    NSLog(@"%@", self.connected);
}

- (void) getBatteryLevelOnPercentage:(CBCharacteristic *)characteristic
{
    NSData *data = [NSData dataWithData:characteristic.value];
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);
    len = sizeof(byteData);
    NSLog(@"%lu", (unsigned long)len);
    if(len >= 1){
        NSLog(@"%hhu",byteData[0]);
    }
    return;
}
-(void) handleUserInfo:(CBCharacteristic *)characteristic{
    MBUserInfoModel *user = [[MBUserInfoModel alloc]initWithData:characteristic.value];
    NSLog(@"%@",user.description);
}
- (void) handlePairResult:(CBCharacteristic *)characteristic
{
    NSData *data = [NSData dataWithData:characteristic.value];
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);
    len = sizeof(byteData);
    NSLog(@"Length = %lu", (unsigned long)len);
    if (byteData != NULL) {
        if (len == 1) {
            @try {
                if (byteData[0] == 2) {
                    NSLog(@"Successfully paired  MI device");
                    return;
                }
            } @catch (NSException *e) {
                NSLog(@"Error identifying pairing result. %@", e);
                return;
            }
        }
        NSString *result = [[NSString alloc] initWithBytes:byteData length:len encoding:NSUTF8StringEncoding];
        NSLog(@"MI Band pairing result: %@", result);
    }
    return;
}

- (void) handleNotifications:(CBCharacteristic *)characteristic
{
    
    NSLog(@"bytes in hex: %@", [characteristic description]);
    NSString *hexValue= [characteristic description];
    NSArray *raw = [hexValue componentsSeparatedByString:@":"];
    NSString *hex = [raw[1] stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    hex = [hex substringToIndex:[hex length] - 1];
    NSString * newString = [hex substringWithRange:NSMakeRange(0, 3)];
    NSLog(@"%@",newString);
    NSData *data = [characteristic value];
    if(data.length != 1){
        NSLog(@"Notifications should be 1 byte long.");
    }
    else{
        if ([newString  isEqual: @"0x6"]){
            
        }
        //NSLog(@"%d",reportData[0] & 0x01);
    }

    return;
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_PAIR]]){
        //[self handlePairResult:characteristic];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
}
- (void) handleRealtimeSteps:(CBCharacteristic *)characteristic {
    // Get the Heart Rate Monitor BPM
    NSData *data = [characteristic value];      // 1
    const uint8_t *reportData = [data bytes];
    int steps = (0xff & reportData[0]) | (0xff & reportData[1]) << 8;
    NSLog(@"Real Time Steps: %d",steps);
    
}
-(void) handleDeviceInfo:(CBCharacteristic *)characteristic{
    MBDeviceInfoModel *dev = [[MBDeviceInfoModel alloc]initWithData:characteristic.value];
    NSLog(@"%@",dev.description);
    // TODO
   /* NSData *data = [characteristic value];
    const uint8_t *reportData = [data bytes];
    NSLog(@"Length: %lu",(unsigned long)[data length]);
    if(data.length == 16 || data.length == 20)
    {
        NSLog(@"%d",reportData[6] & 255);
    }*/
/*if ((data.length == 16 || data.length == 20) && isChecksumCorrect(data)) {
    deviceId = String.format("%02X%02X%02X%02X%02X%02X%02X%02X", data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]);
    profileVersion = getInt(data, 8);
    fwVersion = getInt(data, 12);
    hwVersion = data[6] & 255;
    appearance = data[5] & 255;
    feature = data[4] & 255;
    if (data.length == 20) {
        int s = 0;
        for (int i = 0; i < 4; ++i) {
            s |= (data[16 + i] & 255) << i * 8;
        }
        fw2Version = s;
    } else {
        fw2Version = -1;
    }
} else {
    deviceId = "crc error";
    profileVersion = -1;
    fwVersion = -1;
    hwVersion = -1;
    feature = -1;
    appearance = -1;
    fw2Version = -1;
}*/
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Updated value for heart rate measurement received
    //if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_HEART_RATE_MEASUREMENT]]) { // 1
        // Get the Heart Rate Monitor BPM
    //    [self getHeartBPMData:characteristic error:error];
    //}
    // Retrieve the characteristic value for manufacturer name received
    //if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_USER_INFO]]) {  // 2
    //    [self getManufacturerName:characteristic];
    //}
    //[self handlePairResult:characteristic];
    //[self handleNotifications:characteristic];
    //[self getBatteryLevelOnPercentage:characteristic];
    // Add your constructed device information to your UITextView
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_REALTIME_STEPS]])
         [self handleRealtimeSteps:characteristic];
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_DEVICE_INFO]])
            [self handleDeviceInfo:characteristic];
    //else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_USER_INFO]])
      //  [self handleUserInfo:characteristic];
    else{
        [self getBatteryState:characteristic];
    }
    //self.deviceInfo = [NSString stringWithFormat:@"%@\n%@\n%@\n", self.connected, self.bodyData, self.manufacturer];  // 4
    //NSLog(@"%@",self.deviceInfo);
}

// Step 3 Discover Services
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
        //NSLog(@"Discovered service %@", service);
    }
}
// Step 4 Subscribe to characteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    /*if ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_SERVICE_HEART_RATE]])  {  // 1
        for (CBCharacteristic *aChar in service.characteristics)
        {
            // Request heart rate notifications
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_HEART_RATE_MEASUREMENT]]) { // 2
                [self.miBandPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found heart rate measurement characteristic");
            }
        }
    }*/
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_SERVICE_MIBAND_SERVICE]])  {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_BATTERY]]) {
                //[self.miBandPeripheral setNotifyValue:YES forCharacteristic:aChar];
                [self.miBandPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found Battery State.");
            }
            else if([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_DEVICE_INFO]]){
                [self.miBandPeripheral readValueForCharacteristic:aChar];
            }
            /*else if([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_PAIR]]){
                //[self.miBandPeripheral readValueForCharacteristic:aChar];
                const unsigned char bytes[] = {2};
                NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
                NSLog(@"Pairing");
                [self.miBandPeripheral writeValue:data forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
            }*/
            else if([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_USER_INFO]]){
                [self.miBandPeripheral readValueForCharacteristic:aChar];
            }
            else if([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_REALTIME_STEPS]])
            {
                [self.miBandPeripheral setNotifyValue:YES forCharacteristic:aChar];
                //[self.miBandPeripheral readValueForCharacteristic:aChar];
            }
            else if([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_CHARACTERISTIC_ACTIVITY_DATA]]){
                [self.miBandPeripheral setNotifyValue:YES forCharacteristic:aChar];
            }
        }
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *services = @[[CBUUID UUIDWithString:UUID_SERVICE_MIBAND_SERVICE], [CBUUID UUIDWithString:UUID_SERVICE_HEART_RATE]];
    // Insert code here to initialize your application
    CBCentralManager *centralManagerTemp = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    [centralManagerTemp scanForPeripheralsWithServices:services options:nil];
    self.myCentralManager = centralManagerTemp;

    
}
// Step 1 Scan Devices
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    if([peripheral.name isEqual: @"MI1S"]){
        NSLog(@"Discovered %@", peripheral.name);
        [self.myCentralManager stopScan];
        self.miBandPeripheral = peripheral;
        peripheral.delegate = self;
        NSLog(@"Scanning stopped");
        [self.myCentralManager connectPeripheral:peripheral options:nil];
    }


}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
