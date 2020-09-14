//
//  ViewController.m
//  RunLoopFluecyMonitor
//
//  Created by Ezio Chiu on 9/14/20.
//  Copyright © 2020 Ezio Chiu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass: [UITableViewCell class] forCellReuseIdentifier: @"cell"];
}


- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
    return 500;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: @"cell"];
    cell.textLabel.text = [NSString stringWithFormat: @"第%lu行", indexPath.row];
    if (indexPath.row > 0 && indexPath.row % 30 == 0) {
        sleep(2.0);
    }
    return cell;
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
    sleep(2.0);
}


@end
