//
//  RunloopMonitor.m
//  RunLoopFluecyMonitor
//
//  Created by Ezio Chiu on 9/14/20.
//  Copyright © 2020 Ezio Chiu. All rights reserved.
//

#import "RunloopMonitor.h"

@interface RunloopMonitor ()
@property (nonatomic, assign) int outTime;
@property (nonatomic, assign) BOOL isMonitoring;

@property (nonatomic, assign) CFRunLoopObserverRef observer;
@property (nonatomic, assign) CFRunLoopActivity currentActivity;

@property (nonatomic, strong) dispatch_semaphore_t semphore;
@property (nonatomic, strong) dispatch_semaphore_t eventSemphore;
@end

static NSTimeInterval restore_interval = 5;
static NSTimeInterval time_out_interval = 1;
static int64_t wait_interval = 200 * NSEC_PER_MSEC;

/// 监听runloop状态为before waiting状态下是否卡顿
static inline dispatch_queue_t event_monitor_queue() {
    static dispatch_queue_t event_monitor_queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        event_monitor_queue = dispatch_queue_create("com.eziochiu.event_monitor_queue", NULL);
    });
    return event_monitor_queue;
}

/// 监听runloop状态在after waiting和before sources之间
static inline dispatch_queue_t fluecy_monitor_queue() {
    static dispatch_queue_t fluecy_monitor_queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        fluecy_monitor_queue = dispatch_queue_create("com.eziochiu.monitor_queue", NULL);
    });
    return fluecy_monitor_queue;
}

static void runLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void * info) {
    [RunloopMonitor shareInstance].currentActivity = activity;
    dispatch_semaphore_signal([RunloopMonitor shareInstance].semphore);
#if 0
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"runloop entry");
            break;
        case kCFRunLoopExit:
            NSLog(@"runloop exit");
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"runloop after waiting");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"runloop before timers");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"runloop before sources");
            break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"runloop before waiting");
            break;
        default:
            break;
    }
#endif
};


@implementation RunloopMonitor
static RunloopMonitor *_instance = nil;
// MARK: - 初始化方法
/// 单利方法
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

/// 重写allocWithZone
/// @param zone zone
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

/// 重写copyWithZone
/// @param zone zone
- (instancetype)copyWithZone:(NSZone *)zone {
    return _instance;
}

/// 重写mutableCopyWithZone
/// @param zone zone
- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.semphore = dispatch_semaphore_create(0);
        self.eventSemphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)startMonitoring {
    if (_isMonitoring) { return; }
    _isMonitoring = YES;
    CFRunLoopObserverContext context = { 0, (__bridge void *)self, NULL, NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallback, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    dispatch_async(event_monitor_queue(), ^{
        while ([RunloopMonitor shareInstance].isMonitoring) {
            if ([RunloopMonitor shareInstance].currentActivity == kCFRunLoopBeforeWaiting) {
                __block BOOL timeOut = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    timeOut = NO;
                    dispatch_semaphore_signal([RunloopMonitor shareInstance].eventSemphore);
                });
                [NSThread sleepForTimeInterval: time_out_interval];
                if (timeOut) {
                }
                dispatch_wait([RunloopMonitor shareInstance].eventSemphore, DISPATCH_TIME_FOREVER);
            }
        }
    });
    
    dispatch_async(fluecy_monitor_queue(), ^{
        while ([RunloopMonitor shareInstance].isMonitoring) {
            long waitTime = dispatch_semaphore_wait(self.semphore, dispatch_time(DISPATCH_TIME_NOW, wait_interval));
            if (waitTime != 0) {
                if (![RunloopMonitor shareInstance].observer) {
                    [RunloopMonitor shareInstance].outTime = 0;
                    [[RunloopMonitor shareInstance] stopMonitoring];
                    continue;
                }
                if ([RunloopMonitor shareInstance].currentActivity == kCFRunLoopBeforeSources || [RunloopMonitor shareInstance].currentActivity == kCFRunLoopAfterWaiting) {
                    if (++[RunloopMonitor shareInstance].outTime < 5) {
                        continue;
                    }
                    [NSThread sleepForTimeInterval: restore_interval];
                }
            }
            [RunloopMonitor shareInstance].outTime = 0;
        }
    });
}

- (void)stopMonitoring {
    if (!_isMonitoring) { return; }
    _isMonitoring = NO;
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = nil;
}
@end
