//
//  ViewController.m
//  SU3DPIX
//
//  Created by Su Xiaozhou on 13/10/2016.
//  Copyright © 2016 SXZ. All rights reserved.
//

#import "ViewController.h"
#import "SUPCalculator.h"


static NSString *kIndexValueChangedKey = @"indexValueChanged";

@import CoreMotion;

@interface ViewController ()
@property (nonatomic, strong) UIImageView *showView;
@property (nonatomic, strong)  NSMutableArray *imageNameList;
@property (nonatomic, assign) CGPoint startLocation;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, assign) NSInteger toIndex;
@property (nonatomic, assign) NSUInteger indexValueChanged;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) double startDegree;
@end

@implementation ViewController{
    NSUInteger myValue;
}

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.showView];
    
    [self getReady];
    [self startMotionDetect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc{
    [self removeObserver:self forKeyPath:kIndexValueChangedKey];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification:) name:@"APP_ACTIVE_NOTIFICATION" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:@"APP_ACTIVE_NOTIFICATION"];
}
#pragma mark - kvo

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:kIndexValueChangedKey]) {
        id oldValue =  [change objectForKey:NSKeyValueChangeOldKey];
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];
        if ([oldValue integerValue] != [newValue integerValue]) {
            NSString *imageName = _imageNameList[[newValue integerValue]];
            [self.showView setImage:[UIImage imageNamed:imageName]];
            [self.showView setNeedsDisplay];
        }
    }
}

#pragma mark - Gestures

- (void)handleGesture:(UIGestureRecognizer *)sender{

    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.motionManager stopDeviceMotionUpdates];
        _startLocation = [sender locationInView:self.view];
        _toIndex = _currentIndex;
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        static CGFloat kRotationMultiplier = 0.5f;
        
        CGPoint stopLocation = [sender locationInView:self.view];
        CGFloat dx = stopLocation.x - _startLocation.x;
        
        NSInteger listCount = _imageNameList.count;
        //current index of list count in percent
        CGFloat indexPer = _currentIndex * 1.0 / listCount;
        //gesture location of screen in percent
        CGFloat panChange = dx / (CGRectGetWidth(self.view.bounds) / 2.f) ;
//        NSLog(@"%f",panChange);
        CGFloat indexChanged = indexPer - (panChange * kRotationMultiplier);
        _toIndex =  listCount * indexChanged;
        _toIndex = _toIndex > 0 ? MIN(_toIndex, listCount - 1) : 0;
        [self setValue:@(_toIndex) forKey:kIndexValueChangedKey];
    }
    else if(sender.state == UIGestureRecognizerStateEnded){
        _currentIndex = _toIndex;
        [self startMotionDetect];
    }
}

#pragma mark - Motion

- (void)startMotionDetect{
    
    __weak typeof(self) weakSelf = self;
    _startDegree = 0.;
    NSInteger startIndex = _currentIndex;
    if (self.motionManager.deviceMotionAvailable) {
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [weakSelf processMotion:motion fromIndex:startIndex];
        }];
        
    }
}

- (void)processMotion:(CMDeviceMotion *)motion fromIndex:(NSInteger)startIndex{
    NSInteger listCount = _imageNameList.count;

    double temp = motion.attitude.roll + motion.attitude.pitch - motion.attitude.yaw;
    double roll = [SUPCalculator degrees:temp];

    if (_startDegree == 0.) {
        _startDegree = [SUPCalculator degrees:temp];
    }
    double diff =  roll - _startDegree;
    double diffChange = diff / 70;
    
    NSInteger diffIndex = listCount * diffChange;
    _toIndex = startIndex - diffIndex;
    _toIndex = _toIndex > 0 ? MIN(_toIndex, listCount - 1) : 0;
    
    while (_currentIndex > _toIndex) {
        _currentIndex--;
         [self updateCurrentIndexWithListCount:listCount];
    }
    
    while (_currentIndex < _toIndex) {
        _currentIndex++;
        [self updateCurrentIndexWithListCount:listCount];
    }
}

- (void)updateCurrentIndexWithListCount:(NSInteger)listCount{
    _currentIndex = _currentIndex > 0 ? MIN(_currentIndex, listCount - 1) : 0;
    [self setValue:@(_currentIndex) forKey:kIndexValueChangedKey];
}

- (void)receivedNotification:(NSNotification *)notification{
    if ([notification.name isEqualToString:@"APP_ACTIVE_NOTIFICATION"]) {
        //TODO
    }
}

#pragma mark - Data

- (void)getReady{
     [self addObserver:self forKeyPath:kIndexValueChangedKey options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    _currentIndex = self.imageNameList.count * 0.5;
    [self setValue:@(_currentIndex) forKey:kIndexValueChangedKey];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    [self.view addGestureRecognizer:pan];
}

#pragma mark - Properties

- (NSMutableArray *)imageNameList{
    if (!_imageNameList) {
        _imageNameList = [NSMutableArray new];
        for (NSInteger i = 0; i < 150; i++) {
            NSString *imageName = [NSString stringWithFormat:@"pic_%03li", (long)i];
            [_imageNameList addObject:imageName];
        }
    }
    return _imageNameList;
}

- (UIImageView *)showView{
    if (!_showView) {
        _showView = [[UIImageView alloc] initWithFrame:self.view.frame];
        _showView.contentMode = UIViewContentModeScaleAspectFill;
        
    }
    return _showView;
}

- (CMMotionManager *)motionManager{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 0.01;
    }
    return _motionManager;
}
@end
