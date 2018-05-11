//
//  MFViewController.m
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.
//  https://www.jianshu.com/p/6e079da2370c

#import "MFViewController.h"
#import "MFBlueManagerViewModel.h"

@interface MFViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) MFBlueManagerViewModel *viewModel;

@property (nonatomic,strong) UITableView *tableView;
//设备列表
@property (nonatomic,strong) NSMutableArray *devices;
//连接状态
@property (nonatomic,strong) UILabel *accessoryView;

@end

@implementation MFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(refreshBluetooth)];
    
    _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    @weakify(self)
    [self.viewModel bindViewModel:^(NSMutableArray *devices) {
        @strongify(self)
        self.devices = devices;
        [self.tableView reloadData];
    }];
}

/**
 刷新蓝牙
 */
- (void)refreshBluetooth{
    [self.viewModel refreshBluetooth];
}

- (NSMutableArray *)devices{
    if (!_devices) {
        _devices = [[NSMutableArray alloc] init];
    }
    return _devices;
}

- (MFBlueManagerViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[MFBlueManagerViewModel alloc] init];
    }
    return _viewModel;
}

- (UILabel *)accessoryView{
    if (!_accessoryView) {
        _accessoryView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _accessoryView.text = @"点击连接";
        _accessoryView.textColor = [UIColor grayColor];
    }
    return _accessoryView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.devices.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identifier = NSStringFromClass([UITableViewCell class]);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    CBPeripheral *peripheral = self.devices[indexPath.row];
    cell.accessoryView = self.accessoryView;
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"uuid=%@\n rssi=%@",peripheral.identifier,peripheral.RSSI];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CBPeripheral *peripheral = self.devices[indexPath.row];
    [self.viewModel connect:peripheral];
}

@end
