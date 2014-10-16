//
//  PieChartViewController.h
//  ScatterPlotDemo
//
//  Created by yuan.yinchun on 14/10/14.
//  Copyright (c) 2014 yyc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PieChartViewController : UIViewController<CPTPlotSpaceDelegate, CPTPlotDataSource, CPTAnimationDelegate>

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property(nonatomic,strong) NSArray *myPlotData;
@property(nonatomic,strong) NSDictionary *myColor;

@end
