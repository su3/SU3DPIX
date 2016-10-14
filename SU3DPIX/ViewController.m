//
//  ViewController.m
//  SU3DPIX
//
//  Created by Su Xiaozhou on 13/10/2016.
//  Copyright © 2016 SXZ. All rights reserved.
//

#import "ViewController.h"

@import CoreMotion;

@interface ViewController ()
@property (nonatomic, strong) UIImageView *showView;
@property (nonatomic, strong)  NSMutableArray *imageNameList;
@property (nonatomic, assign) CGPoint startLocation;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger toIndex;

@end

@implementation ViewController

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self.view addSubview:self.showView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Gestures

- (void)handleGesture:(UIGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateBegan) {
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
        NSString *imageName = _imageNameList[_toIndex];
        [self.showView setImage:[UIImage imageNamed:imageName]];
        [self.showView setNeedsDisplay];
    }
    else if(sender.state == UIGestureRecognizerStateEnded){
        _currentIndex = _toIndex;
    }
}

#pragma mark - Data

- (void)initData{
    _currentIndex = self.imageNameList.count * 0.5;
    NSString *imageName = _imageNameList[_currentIndex];
    [self.showView setImage:[UIImage imageNamed:imageName]];
    
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

@end
