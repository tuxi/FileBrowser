//
//  OSFileUtils.m
//  FileBrowser
//
//  Created by Swae on 2017/11/1.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import "OSFileUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation OSFileUtils

+ (NSString *)MD5HashWithString:(NSString *)string {
    
    CC_MD5_CTX md5;
    CC_MD5_Init (&md5);
    CC_MD5_Update (&md5, [string UTF8String], (CC_LONG) [string length]);
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final (digest, &md5);
    NSString *s = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   digest[0],  digest[1],
                   digest[2],  digest[3],
                   digest[4],  digest[5],
                   digest[6],  digest[7],
                   digest[8],  digest[9],
                   digest[10], digest[11],
                   digest[12], digest[13],
                   digest[14], digest[15]];
    
    return s;
    
}

@end
