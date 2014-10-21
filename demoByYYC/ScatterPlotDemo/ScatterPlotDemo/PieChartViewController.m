//
//  PieChartViewController.m
//  ScatterPlotDemo
//
//  Created by yuan.yinchun on 14/10/14.
//  Copyright (c) 2014 yyc. All rights reserved.
//

#import "PieChartViewController.h"

@interface PieChartViewController ()

@property (nonatomic) BOOL beforeInsertSeperator;

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
    
    self.myPlotData=[[NSMutableArray alloc]init];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"error",@12,@19, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"warning",@1,@5, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"notify",@1,@37, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"info",@6,@41, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"fatal",@8,@82, nil]];
    
    /*
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"error",@12,@25, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"warning",@1,@21, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"notify",@1,@20, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"info",@6,@15, nil]];
    [self.myPlotData addObject:[NSMutableArray arrayWithObjects:@"fatal",@8,@34, nil]];
     */

    self.myColor=@{
                   @"error":[UIColor colorWithRed:251/255.0 green:177/255.0 blue:80/255.0 alpha:1.0],
                   @"warning":[UIColor colorWithRed:109/255.0 green:216/255.0 blue:198/255.0 alpha:1.0],
                   @"notify":[UIColor colorWithRed:39/255.0 green:213/255.0 blue:60/255.0 alpha:1.0 ],
                   @"info":[UIColor colorWithRed:251/255.0 green:220/255.0 blue:34/255.0 alpha:1.0],
                   @"fatal":[UIColor colorWithRed:230/255.0 green:76/255.0 blue:101/255.0 alpha:1.0],
                   @"seperator":[UIColor clearColor]
                   };
    
}


-(int)getSeperatorData
{
    int totalNumber=0;
    double seperatorData=0.0;
    int factor=64;
    if (self.beforeInsertSeperator==NO){
        for (int i=0;i<[ self.myPlotData count];i+=2) {
        totalNumber+=[self.myPlotData[i][2] intValue];
        }
        
        seperatorData= M_PI*totalNumber/[self.myPlotData count]/2/(factor-M_PI);
    }
    else{
        for (NSArray *array in self.myPlotData) {
            totalNumber+=[array[2] intValue];
        }
        
        seperatorData =M_PI*totalNumber/[self.myPlotData count]/(factor-M_PI);
    }
    
    return (int)seperatorData;
}

-(void)insertSeperatorData
{
    
    int seperatorData=[self getSeperatorData];
    NSMutableArray *newArray=[[NSMutableArray alloc]init];
    for (NSArray * array in self.myPlotData) {
        [newArray addObject:array];
        [newArray addObject:[NSMutableArray arrayWithObjects:@"seperator",[NSNumber numberWithInt:seperatorData],[NSNumber numberWithInt:seperatorData], nil ]];
    }
    self.myPlotData=newArray;
    self. beforeInsertSeperator=NO;
    
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

-(void)takeScreenshot:(NSString *)imgName
{
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(self.view.window.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(self.view.window.bounds.size);
    [self.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData * data = UIImagePNGRepresentation(image);
    [data writeToFile:@"imgName" atomically:YES];
    
}

-(void)changePlotData{
    static int times=1;
    
    NSUInteger count=[self.myPlotData count];
    for (int i=0; i<count; i+=2) {
        NSNumber *num=[NSNumber numberWithInt:arc4random() % (100+1)];//0~100
        self.myPlotData[i][2]=num;
    }
    
    for (int i=1;i<count;i+=2){ //change seperator data
        
    }
    
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionFade;
    animation.duration =1;
    [self.pieChart addAnimation:animation forKey:nil];
    self.pieChart.hidden = YES;
    
    
    
    [self.pieChart reloadPlotData];
   
    NSLog(@"%d ----------\n%@",times,self.myPlotData);
    
    [self takeScreenshot:[NSString stringWithFormat:@"%d.png",times]];
    times++;
    
    self.pieChart.hidden=NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.beforeInsertSeperator=YES;
    [self generateData];
    [self insertSeperatorData];
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
    piePlot.startAngle=M_PI_2;
    piePlot.sliceDirection  = CPTPieDirectionClockwise;
    piePlot.adjustLabelAnchors=NO;
    piePlot.enableSeperator=YES;
    piePlot.delegate = self;
    self.pieChart=piePlot;
    
    CPTMutableLineStyle *lineStyle=[CPTMutableLineStyle lineStyle];
    lineStyle.lineFill=[CPTFill fillWithColor:[CPTColor whiteColor]];
    lineStyle.lineWidth=0.5f;
    lineStyle.lineCap=kCGLineCapRound;
    piePlot.dataLabelLineStyle=lineStyle;
    
    CPTFill *shadowFill=[CPTFill fillWithColor:[CPTColor colorWithComponentRed:1 green:1 blue:1 alpha:0.1]];
    piePlot.shadowFill=shadowFill;
    
    CPTMutableTextStyle *totalStyle=[CPTMutableTextStyle textStyle];
    totalStyle.color=[CPTColor lightGrayColor];
    piePlot.totalTextStyle=totalStyle;
    
    [self.hostView.hostedGraph addPlot:piePlot];
    
    /*
     [CPTAnimation animate:piePlot
     property:@"startAngle"
     from:0
     to:2*M_PI
     duration:1.25];
    
     [CPTAnimation animate:piePlot
     property:@"endAngle"
     from:2*M_PI
     to:0
     duration:1.25];
    */
    
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(changePlotData) userInfo:nil repeats:YES];
    
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
    if (self.pieChart.enableSeperator==YES) {
        if (index%2) {//odd
            return nil;
        }
    }
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
    UIColor *color=nil;
    if (idx%2) {//odd
        color=self.myColor[@"seperator"];
        return [[CPTFill alloc]initWithColor:[[CPTColor alloc]initWithCGColor:  color.CGColor                                             ]];    }
    else{
        color=self.myColor[self.myPlotData[idx][0]];
        return [[CPTFill alloc]initWithColor:[[CPTColor alloc]initWithCGColor:  color.CGColor                                             ]];
    }
}

@end
