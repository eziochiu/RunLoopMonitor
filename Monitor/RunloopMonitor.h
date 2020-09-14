//
//  RunloopMonitor.h
//  RunLoopFluecyMonitor
//
//  Created by Ezio Chiu on 9/14/20.
//  Copyright © 2020 Ezio Chiu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RunloopMonitor : NSObject
+ (instancetype)shareInstance;
- (void)startMonitoring;
- (void)stopMonitoring;
@end

NS_ASSUME_NONNULL_END
