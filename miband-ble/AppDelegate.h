//
//  AppDelegate.h
//  miband-ble
//
//  Created by Alex Cruz on 5/20/16.
//  Copyright © 2016 BlackWizards. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>


@end

