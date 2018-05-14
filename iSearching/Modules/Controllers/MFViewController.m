//
//  MFViewController.m
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.
//  https://www.jianshu.com/p/6e079da2370c

#import "MFViewController.h"
#import "MFBlueManagerViewModel.h"
#import "MFPeripheralModel.h"

@interface MFViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) MFBlueManagerViewModel *viewModel;

@property (nonatomic,strong) UITableView *tableView;
//设备列表
@property (nonatomic,copy) NSArray <MFPeripheralModel *>*devices;
//连接状态
@property (nonatomic,strong) UILabel *accessoryView;
//刷新状态
@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@end

@implementation MFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(refreshBluetooth)];
//    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        [self.view addSubview:tableView];
        tableView;
    });
    
    _activityView = ({
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView startAnimating];
        self.navigationItem.titleView = activityView;
        activityView;
    });
    
    [self.viewModel addObserver:self forKeyPath:modelDevices options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:modelDevicesContext];

    @weakify(self)
    [self.viewModel bindViewModel:^(NSMutableArray *devices) {
        @strongify(self)
    }];
    
}

/**
 刷新蓝牙
 */
- (void)refreshBluetooth{
    [self.viewModel refreshBluetooth];
}

- (NSArray *)devices{
    if (!_devices) {
        _devices = [[NSArray alloc] init];
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
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identifier = NSStringFromClass([UITableViewCell class]);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    MFPeripheralModel *model = self.devices[indexPath.row];
//    cell.accessoryView = self.accessoryView;
    cell.textLabel.text = model.peripheral.name ?:@"名字为空";
    cell.detailTextLabel.numberOfLines = 2;
    
    NSString *uuid = [model.peripheral.identifier UUIDString];
    NSString *rssi = [model.RSSI stringValue];
    NSString *str = [NSString stringWithFormat:@"%@\n%@",uuid,rssi];
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc]initWithString:str];
    [cell.detailTextLabel setAttributedText:attribute];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MFPeripheralModel *model = self.devices[indexPath.row];
    [self.viewModel connect:model.peripheral];
}



#pragma mark 数组KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (context == modelDevicesContext) {
        if ([keyPath isEqualToString:modelDevices]) {
            self.devices = self.viewModel.modelDevices;
            [self.tableView reloadData];
            [self.activityView stopAnimating];
            //        self.navigationItem.rightBarButtonItem.enabled = YES;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc{
    if (_viewModel) {
        [_viewModel removeObserver:self forKeyPath:modelDevices];
    }
}

@end
