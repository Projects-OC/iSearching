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
    
    @weakify(self)
    [self.viewModel bindViewModel:^(NSMutableArray *devices) {
        @strongify(self)
    }];
    
    [self.viewModel addObserver:self forKeyPath:devicesKeyPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:devicesContext];
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
        NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithCapacity:0] forKey:devicesKeyPath];
        _viewModel = [[MFBlueManagerViewModel alloc] initWithDic:dic];
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

#pragma mark 数组KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (context == devicesContext) {
        if ([keyPath isEqualToString:devicesKeyPath]) {
            self.devices = (NSMutableArray *)object;
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
        [_viewModel removeObserver:self forKeyPath:devicesKeyPath];
    }
}

@end
