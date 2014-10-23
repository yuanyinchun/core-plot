//
//  PieChartViewController.h
//  ScatterPlotDemo
//
//  Created by yuan.yinchun on 14/10/14.
//  Copyright (c) 2014 yyc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@interface PieChartViewController : UIViewController<CPTPlotSpaceDelegate, CPTPlotDataSource, CPTAnimationDelegate>

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property(nonatomic,strong) NSMutableArray *myPlotData;
@property(nonatomic,strong) NSDictionary *myColor;

@property(nonatomic,strong) CPTPieChart *pieChartZero;
@property(nonatomic,strong) CPTPieChart *pieChartOne;
@property(nonatomic,strong) CPTPieChart *pieChart;

@end
