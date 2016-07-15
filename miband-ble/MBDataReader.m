//
//  MBDataReader.m
//  MiBandApiSample
//
//  Created by TracyYih on 15/1/2.
//  Copyright (c) 2015年 esoftmobile.com. All rights reserved.
//

#import "MBDataReader.h"

@implementation MBDataReader

- (instancetype)init {
    self = [super init];
    if (self) {
        _bytes = [NSMutableData dataWithLength:0].mutableBytes;
        _length = 0;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _bytes = (Byte *)data.bytes;
        _length = data.length;
    }
    return self;
}

- (instancetype)rePos:(NSUInteger)pos {
    _pos = pos;
    return self;
}

- (NSUInteger)bytesLeftCount {
    return _length - _pos;
}

- (NSUInteger)readInt:(NSUInteger)bytesCount {
    NSUInteger result = 0;
    for (int i = 0; i < bytesCount; i++) {
        result |= _bytes[_pos++] << (i * 8);
    }
    return result;
}

- (NSUInteger)readIntReverse:(NSUInteger)bytesCount {
    NSUInteger result = 0;
    NSUInteger pos = _pos + bytesCount - 1;
    for (int i = 0; i < bytesCount; i++) {
        result |= _bytes[pos--] << (i * 8);
    }
    return result;
}

- (NSInteger)readSensorData {
    NSInteger temp = [self readInt:2] & 0xfff;
    if (temp & 0x800) {
        temp -= 0x1000;
    }
    return temp;
}

- (NSString *)readString:(NSUInteger)bytesCount {
    return [[[NSString alloc] initWithBytes:(_bytes + _pos) length:bytesCount encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)readVersionString {
    _pos += 4;
    return [NSString stringWithFormat:@"%d.%d.%d.%d", _bytes[_pos - 1], _bytes[_pos - 2], _bytes[_pos - 3], _bytes[_pos - 4]];
}

- (NSDate *)readDate {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dataComponents = [[NSDateComponents alloc] init];
    dataComponents.calendar = calendar;
    dataComponents.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dataComponents.year = _bytes[_pos++] + 2000;
    dataComponents.month = _bytes[_pos++] + 1;
    dataComponents.day = _bytes[_pos++];
    dataComponents.hour = _bytes[_pos++];
    dataComponents.minute = _bytes[_pos++];
    dataComponents.second = _bytes[_pos++];
    return [dataComponents date];
}

@end
