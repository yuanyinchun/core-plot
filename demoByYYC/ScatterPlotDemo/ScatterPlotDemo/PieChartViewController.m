//
//  PieChartViewController.m
//  ScatterPlotDemo
//
//  Created by yuan.yinchun on 14/10/14.
//  Copyright (c) 2014 yyc. All rights reserved.
//

#import "PieChartViewController.h"

@interface PieChartViewController ()

@end

@implementation PieChartViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)generateData
{
    
    self.myPlotData=@[
                          @[@"warning",@4,@20],
                          @[@"notify",@1,@40],
                          @[@"info",@6,@80],
                          ];
    self.myColor=@{
                       @"warning":[UIColor blueColor],
                       @"notify":[UIColor greenColor],
                       @"info":[UIColor yellowColor]
                       };

}


-(void)configureHost {
	self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:CGRectMake(0, 0, 320, 150)];
	self.hostView.allowPinchScaling = YES;
	[self.view addSubview:self.hostView];
}

-(void)configureGraph
{
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
	[graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
	self.hostView.hostedGraph = graph;
    
    graph.paddingLeft=0;
    graph.paddingRight=0;
    graph.paddingTop=0;
    graph.paddingBottom=0;
    graph.plotAreaFrame.masksToBorder = NO;
    graph.axisSet                     = nil;
    
    graph.plotAreaFrame.cornerRadius=0.0f;
    graph.plotAreaFrame.borderLineStyle =nil;

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self generateData];
    [self configureHost];
    [self configureGraph];
    
    
    // Add pie chart
    const CGFloat outerRadius=50.0;
    const CGFloat innerRadius = outerRadius / 2.0;
    
    CPTPieChart *piePlot = [[CPTPieChart alloc] init];
    piePlot.dataSource      = self;
    piePlot.pieRadius       = outerRadius;
    piePlot.pieInnerRadius  = innerRadius + 5.0;
    piePlot.identifier      = @"outer";
    piePlot.labelOffset=50.0;
    piePlot.customizeLabelPosition=YES;
    piePlot.startAngle=M_PI;
    piePlot.sliceDirection  = CPTPieDirectionClockwise;
    piePlot.delegate        = self;
    
    CPTMutableLineStyle *lineStyle=[CPTMutableLineStyle lineStyle];
    lineStyle.lineFill=[CPTFill fillWithColor:[CPTColor whiteColor]];
    lineStyle.lineWidth=0.5f;
    lineStyle.lineCap=kCGLineCapRound;
    piePlot.dataLabelLineStyle=lineStyle;
    
    CPTFill *shadowFill=[CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.8 green:0.8 blue:0.8 alpha:0.1]];
    piePlot.shadowFill=shadowFill;
    
    CPTMutableTextStyle *totalStyle=[CPTMutableTextStyle textStyle];
    totalStyle.color=[CPTColor lightGrayColor];
    piePlot.totalTextStyle=totalStyle;
    
    [self.hostView.hostedGraph addPlot:piePlot];
    /*
     if ( animated ) {
     [CPTAnimation animate:piePlot
     property:@"startAngle"
     from:M_PI_2
     to:M_PI_4
     duration:1.25];
     [CPTAnimation animate:piePlot
     property:@"endAngle"
     from:M_PI_2
     to:3.0 * M_PI_4
     duration:1.25];
     }*/
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [self.myPlotData count];
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num;
    
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
        num = self.myPlotData[index][2];
    }
    else {
        return @(index);
    }
    
    return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    static CPTMutableTextStyle *whiteText = nil;
    static dispatch_once_t onceToken;
    
    CPTTextLayer *newLayer = nil;
    
    if ( [(NSString *)plot.identifier isEqualToString : @"outer"] ) {
        dispatch_once(&onceToken, ^{
            whiteText = [[CPTMutableTextStyle alloc] init];
            whiteText.color = [CPTColor whiteColor];
        });
        
        NSMutableAttributedString *unRead=[[NSMutableAttributedString alloc]initWithString:[_myPlotData[index][1]  stringValue ] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor whiteColor]} ];
        
        NSMutableString *allStr=[[NSMutableString alloc]initWithString:@"/"];
        [allStr appendString:[_myPlotData[index][2]  stringValue ]];
        
        NSMutableAttributedString *all=[[NSMutableAttributedString alloc]initWithString:allStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20],NSForegroundColorAttributeName:[UIColor grayColor]} ];
        
        NSMutableString *levelStr=[[NSMutableString  alloc] initWithString:_myPlotData[index][0]];
        [levelStr appendString:@" "];
        NSMutableAttributedString *level=[[NSMutableAttributedString alloc]initWithString:levelStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15],NSForegroundColorAttributeName:_myColor[_myPlotData[index][0]] } ];
        
        NSMutableAttributedString *str=[[NSMutableAttributedString alloc]init];
        [str appendAttributedString:level];
        [str appendAttributedString:unRead];
        [str appendAttributedString:all];
        
        newLayer=[[CPTTextLayer alloc]initWithAttributedText:str];
    }
    
    return newLayer;
}

-(CGFloat)radialOffsetForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    CGFloat result = 0.0;
    return result;
}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)idx
{
    
    UIColor *color=self.myColor[
                                self.myPlotData[idx][0]
                                ];
    return [[CPTFill alloc]initWithColor:[[CPTColor alloc]initWithCGColor:  color.CGColor                                             ]];
}

@end
