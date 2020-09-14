//
//  BacktraceLoger.h
//  RunLoopFluecyMonitor
//
//  Created by Ezio Chiu on 9/14/20.
//  Copyright © 2020 Ezio Chiu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BacktraceLoger : NSObject
+ (NSString *)backtraceOfAllThread;
+ (NSString *)backtraceOfMainThread;
+ (NSString *)backtraceOfCurrentThread;
+ (NSString *)backtraceOfNSThread:(NSThread *)thread;

+ (void)logMain;
+ (void)logCurrent;
+ (void)logAllThread;
@end

NS_ASSUME_NONNULL_END
