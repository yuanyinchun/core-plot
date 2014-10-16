#import "DonutChart.h"

NSString *const innerChartName = @"Inner";
NSString *const outerChartName = @"Outer";

@implementation DonutChart

+(void)load
{
    [super registerPlotItem:self];
}

-(id)init
{
    if ( (self = [super init]) ) {
        self.title   = @"Donut Chart";
        self.section = kPieCharts;
    }

    return self;
}

-(void)dealloc
{
    [plotData release];
    [super dealloc];
}

-(void)generateData
{
    if ( plotData == nil ) {
        plotData = [[NSMutableArray alloc] initWithObjects:
                    @20.0,
                    @20.0,
                    @40.0,
                    nil];
        self.myPlotData=@[
                     @[@"warning",@4,@20],
                     @[@"notify",@1,@20],
                     @[@"info",@6,@40],
                     ];
        self.myColor=@{
                  @"warning":[UIColor blueColor],
                  @"notify":[UIColor greenColor],
                  @"info":[UIColor yellowColor]
                  };
    }
}

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = layerHostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(layerHostingView.bounds);
#endif

    CPTGraph *graph = [[[CPTXYGraph alloc] initWithFrame:bounds] autorelease];
    [self addGraph:graph toHostingView:layerHostingView];
    [self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTDarkGradientTheme]];

    [self setTitleDefaultsForGraph:graph withBounds:bounds];
    //[self setPaddingDefaultsForGraph:graph withBounds:bounds];
    
    graph.paddingLeft=0;
    graph.paddingRight=0;
    graph.paddingTop=0;
    graph.paddingBottom=300;
     

    graph.plotAreaFrame.masksToBorder = NO;
    graph.axisSet                     = nil;

    CPTMutableLineStyle *whiteLineStyle = [CPTMutableLineStyle lineStyle];
    whiteLineStyle.lineColor = [CPTColor whiteColor];

    CPTMutableShadow *whiteShadow = [CPTMutableShadow shadow];
    whiteShadow.shadowOffset     = CGSizeMake(2.0, -4.0);
    whiteShadow.shadowBlurRadius = 4.0;
    whiteShadow.shadowColor      = [[CPTColor whiteColor] colorWithAlphaComponent:0.25];

    // Add pie chart
    const CGFloat outerRadius=50.0;
    
    /*
    const CGFloat outerRadius = MIN(0.7 * (layerHostingView.frame.size.height - 2 * graph.paddingLeft) / 2.0,
                                    0.7 * (layerHostingView.frame.size.width - 2 * graph.paddingTop) / 2.0);
     */
    const CGFloat innerRadius = outerRadius / 2.0;

    CPTPieChart *piePlot = [[CPTPieChart alloc] init];
    piePlot.dataSource      = self;
    piePlot.pieRadius       = outerRadius;
    piePlot.pieInnerRadius  = innerRadius + 5.0;
    piePlot.identifier      = outerChartName;
    piePlot.labelOffset=50.0;
    piePlot.customizeLabelPosition=YES;
    CPTMutableLineStyle *lineStyle=[CPTMutableLineStyle lineStyle];
    lineStyle.lineColor=[CPTColor whiteColor];
    lineStyle.lineWidth=2.0f;
    piePlot.dataLabelLineStyle=lineStyle;
    
    //piePlot.backgroundColor=[UIColor whiteColor].CGColor;

    piePlot.startAngle=M_PI;
    piePlot.sliceDirection  = CPTPieDirectionClockwise;
    piePlot.delegate        = self;
    [graph addPlot:piePlot];
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
 
    [piePlot release];
}

-(void)pieChart:(CPTPieChart *)plot sliceWasSelectedAtRecordIndex:(NSUInteger)index
{
    NSLog(@"%@ slice was selected at index %lu. Value = %@", plot.identifier, (unsigned long)index, plotData[index]);
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [plotData count];
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

    if ( [(NSString *)plot.identifier isEqualToString : outerChartName] ) {
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
        //newLayer.fill            = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
        //newLayer.cornerRadius    = 5.0;
        //newLayer.paddingLeft     = 3.0;
        //newLayer.paddingTop      = 3.0;
        //newLayer.paddingRight    = 3.0;
        //newLayer.paddingBottom   = 3.0;
        //newLayer.borderLineStyle = [CPTLineStyle lineStyle];
    }

    return newLayer;
}

-(CGFloat)radialOffsetForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    CGFloat result = 0.0;

    if ( [(NSString *)pieChart.identifier isEqualToString : outerChartName] ) {
        result = (index == 0 ? 0.0 : 0.0);
    }
    return result;
}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)idx
{
    
    UIColor *color=self.myColor[
                 self.myPlotData[idx][0]
                  ];
    return [[CPTFill alloc]initWithColor:[[CPTColor alloc]initWithCGColor:  color.CGColor                                             ]];
}

#pragma mark -
#pragma mark Animation Delegate

-(void)animationDidStart:(CPTAnimationOperation *)operation
{
    NSLog(@"animationDidStart: %@", operation);
}

-(void)animationDidFinish:(CPTAnimationOperation *)operation
{
    NSLog(@"animationDidFinish: %@", operation);
}

-(void)animationCancelled:(CPTAnimationOperation *)operation
{
    NSLog(@"animationCancelled: %@", operation);
}

-(void)animationWillUpdate:(CPTAnimationOperation *)operation
{
    NSLog(@"animationWillUpdate:");
}

-(void)animationDidUpdate:(CPTAnimationOperation *)operation
{
    NSLog(@"animationDidUpdate:");
}

@end
