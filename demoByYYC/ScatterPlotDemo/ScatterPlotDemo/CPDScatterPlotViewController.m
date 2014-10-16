//
//  CPDScatterPlotViewController.m
//  CorePlotDemo
//
//  Created by Fahim Farook on 19/5/12.
//  Copyright 2012 RookSoft Pte. Ltd. All rights reserved.
//

#import "CPDScatterPlotViewController.h"

static const NSString *plotSpace2Id=@"plotSpace2";
@implementation CPDScatterPlotViewController

@synthesize hostView = hostView_;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - UIViewController lifecycle methods
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initPlot];
}

#pragma mark - Chart behavior
-(void)initPlot {
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
    [self configAnnotation];
}

-(void)configureHost {  
	self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:self.view.bounds];
	self.hostView.allowPinchScaling = YES;    
	[self.view addSubview:self.hostView];    
}

-(void)configureGraph {
	// 1 - Create the graph
	CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
	[graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
	self.hostView.hostedGraph = graph;
    /*
	// 2 - Set graph title
	NSString *title = @"Portfolio Prices: April 2012";
	graph.title = title;  
    */
    
	// 3 - Create and set text style
	CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
	titleStyle.color = [CPTColor whiteColor];
	titleStyle.fontName = @"Helvetica-Bold";
	titleStyle.fontSize = 16.0f;
	graph.titleTextStyle = titleStyle;
	graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
	graph.titleDisplacement = CGPointMake(50.0f, -10.0f);
    graph.paddingTop=0.0f;
    graph.paddingLeft=0.0f;
    graph.paddingRight=0.0f;
    graph.paddingBottom=0.0f;
    
    
    graph.plotAreaFrame.cornerRadius=0.0f;
    
    
	// 4 - Set padding for plot area
	[graph.plotAreaFrame setPaddingLeft:30.0f];
	[graph.plotAreaFrame setPaddingBottom:30.0f];
    [graph.plotAreaFrame setPaddingRight:30.0f];
	[graph.plotAreaFrame setPaddingTop:30.0f];
    
	// 5 - Enable user interactions for plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = YES;
    
    //add second plotSpace
    CPTXYPlotSpace *plotSpace2=[[CPTXYPlotSpace alloc]init];
    plotSpace2.identifier=plotSpace2Id;
    plotSpace2.xRange=[CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(60) length:CPTDecimalFromInt(-60)];
    plotSpace2.yRange=[CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(1000) length:CPTDecimalFromInt(-1000)];
    [graph addPlotSpace:plotSpace2];
    plotSpace2.allowsUserInteraction=YES;
}

-(void)configurePlots { 
	// 1 - Get graph and plot space
	CPTGraph *graph = self.hostView.hostedGraph;
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
	// 2 - Create the three plots
	CPTScatterPlot *aaplPlot = [[CPTScatterPlot alloc] init];
	aaplPlot.dataSource = self;
	aaplPlot.identifier = CPDTickerSymbolAAPL;
	CPTColor *aaplColor = [CPTColor colorWithComponentRed:167/255.0 green:65/255.0 blue:193/255.0 alpha:1.0];
	[graph addPlot:aaplPlot toPlotSpace:[graph plotSpaceWithIdentifier:plotSpace2Id]];
	CPTScatterPlot *googPlot = [[CPTScatterPlot alloc] init];
	googPlot.dataSource = self;
	googPlot.identifier = CPDTickerSymbolGOOG;
	CPTColor *googColor = [CPTColor colorWithComponentRed:24/255.0 green:117/255.0 blue:187/255.0 alpha:1.0];
	[graph addPlot:googPlot toPlotSpace:plotSpace];    
	CPTScatterPlot *msftPlot = [[CPTScatterPlot alloc] init];
	msftPlot.dataSource = self;
	msftPlot.identifier = CPDTickerSymbolMSFT;
	CPTColor *msftColor = [CPTColor colorWithComponentRed:130/255.0 green:185/255.0 blue:57/255.0 alpha:1.0];
	[graph addPlot:msftPlot toPlotSpace:plotSpace];
    
   

    aaplPlot.areaFill=[CPTFill fillWithGradient:[CPTGradient gradientWithBeginningColor:[aaplColor colorWithAlphaComponent:0.5] endingColor:[aaplColor colorWithAlphaComponent:0.3] beginningPosition:0.0 endingPosition:1.0]];
    aaplPlot.areaBaseValue=[[NSNumber numberWithInt:0]decimalValue];
    
    
    
    googPlot.areaFill=[CPTFill fillWithColor:[googColor colorWithAlphaComponent:0.3]];
    googPlot.areaBaseValue=[[NSNumber numberWithInt:0]decimalValue];
    
    msftPlot.areaFill=[CPTFill fillWithColor:[msftColor colorWithAlphaComponent:0.3]];
    msftPlot.areaBaseValue=[[NSNumber numberWithInt:0]decimalValue];

    
	// 3 - Set up plot space
    plotSpace.xRange=[CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(30)];
    plotSpace.yRange=[CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(800)];
    
	//[plotSpace scaleToFitPlots:[NSArray arrayWithObjects:aaplPlot, googPlot, msftPlot, nil]];
    /*
	CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
	[xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.1f)];        
	plotSpace.xRange = xRange;
	CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
	[yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];        
	plotSpace.yRange = yRange;
     */
    
	// 4 - Create styles and symbols
	CPTMutableLineStyle *aaplLineStyle = [aaplPlot.dataLineStyle mutableCopy];
	aaplLineStyle.lineWidth = 2.5;
	aaplLineStyle.lineColor = aaplColor;
	aaplPlot.dataLineStyle = aaplLineStyle;
	CPTMutableLineStyle *aaplSymbolLineStyle = [CPTMutableLineStyle lineStyle];
	aaplSymbolLineStyle.lineColor = aaplColor;
	CPTPlotSymbol *aaplSymbol = [CPTPlotSymbol ellipsePlotSymbol];
	aaplSymbol.fill = [CPTFill fillWithColor:aaplColor];
	aaplSymbol.lineStyle = aaplSymbolLineStyle;
	aaplSymbol.size = CGSizeMake(6.0f, 6.0f);
	aaplPlot.plotSymbol = aaplSymbol;   
	CPTMutableLineStyle *googLineStyle = [googPlot.dataLineStyle mutableCopy];
	googLineStyle.lineWidth = 1.0;
	googLineStyle.lineColor = googColor;
	googPlot.dataLineStyle = googLineStyle;
	CPTMutableLineStyle *googSymbolLineStyle = [CPTMutableLineStyle lineStyle];
	googSymbolLineStyle.lineColor = googColor;
	CPTPlotSymbol *googSymbol = [CPTPlotSymbol starPlotSymbol];
	googSymbol.fill = [CPTFill fillWithColor:googColor];
	googSymbol.lineStyle = googSymbolLineStyle;
	googSymbol.size = CGSizeMake(6.0f, 6.0f);
	googPlot.plotSymbol = googSymbol;       
	CPTMutableLineStyle *msftLineStyle = [msftPlot.dataLineStyle mutableCopy];
	msftLineStyle.lineWidth = 2.0;
	msftLineStyle.lineColor = msftColor;
	msftPlot.dataLineStyle = msftLineStyle;  
	CPTMutableLineStyle *msftSymbolLineStyle = [CPTMutableLineStyle lineStyle];
	msftSymbolLineStyle.lineColor = msftColor;
	CPTPlotSymbol *msftSymbol = [CPTPlotSymbol diamondPlotSymbol];
	msftSymbol.fill = [CPTFill fillWithColor:msftColor];
	msftSymbol.lineStyle = msftSymbolLineStyle;
	msftSymbol.size = CGSizeMake(6.0f, 6.0f);
	msftPlot.plotSymbol = msftSymbol;
    
}

-(void)configAnnotation {
    CPTGraph *graph=self.hostView.hostedGraph;
    
    
    for(CPTPlot * plot in [graph allPlots]){
        CPTMutableTextStyle *annoStyle=[[CPTMutableTextStyle alloc]init];
        annoStyle.color=[CPTColor whiteColor];
        annoStyle.fontSize=8.0;
        
        int num=[self numberOfRecordsForPlot:plot];
        NSNumber *lastValue=[self numberForPlot:plot field:CPTCoordinateY recordIndex:num-1];
        
        
        // Now add the annotation to the plot area
        CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.2f",[lastValue doubleValue]] style:annoStyle];
        textLayer.backgroundColor=((CPTScatterPlot *)plot).dataLineStyle.lineColor.cgColor;
        CGFloat width=textLayer.bounds.size.width;
        CPTPlotSpaceAnnotation *anno              = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace anchorPlotPoint:@[@0,lastValue]];
        
        anno.contentLayer = textLayer;
        if(plot.plotSpace==graph.defaultPlotSpace){
            anno.displacement = CGPointMake(-width/2.0-1, 0.0);
        }else
        {
            anno.displacement = CGPointMake(width/2+1.0, 0.0);
        }
        
        [graph.plotAreaFrame.plotArea addAnnotation:anno];
    }
    
}


-(void)configureAxes {
	// 1 - Create styles
	CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
	axisTitleStyle.color = [CPTColor whiteColor];
	axisTitleStyle.fontName = @"Helvetica-Bold";
	axisTitleStyle.fontSize = 12.0f;
	CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
	axisLineStyle.lineWidth = 2.0f;
	axisLineStyle.lineColor = [CPTColor whiteColor];
	CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
	axisTextStyle.color = [CPTColor whiteColor];
	axisTextStyle.fontName = @"Helvetica-Bold";    
	axisTextStyle.fontSize = 8.0f;
	CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
	tickLineStyle.lineColor = [CPTColor whiteColor];
	tickLineStyle.lineWidth = 2.0f;
	CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    gridLineStyle.lineColor=[[CPTColor whiteColor] colorWithAlphaComponent:0.1];
	tickLineStyle.lineColor = [CPTColor blackColor];
	tickLineStyle.lineWidth = 1.0f;       
	// 2 - Get axis set
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
	// 3 - Configure x-axis
	CPTXYAxis *x = axisSet.xAxis;
    x.majorGridLineStyle = gridLineStyle;
    x.alternatingBandFills=@[
                             [[CPTColor blackColor] colorWithAlphaComponent:0.1],
    [[CPTColor grayColor] colorWithAlphaComponent:0.1]
                             ];
    /*
	x.title = @"Day of Month"; 
	x.titleTextStyle = axisTitleStyle;    
	x.titleOffset = 15.0f;
     */
	x.axisLineStyle = axisLineStyle;
	x.labelingPolicy = CPTAxisLabelingPolicyNone;
	x.labelTextStyle = axisTextStyle;    
    x.labelingPolicy=CPTAxisLabelingPolicyAutomatic;
    x.orthogonalCoordinateDecimal=CPTDecimalFromInt(0);
    x.visibleRange=((CPTXYPlotSpace *)x.plotSpace).xRange;
    
	// 4 - Configure y-axis
	CPTXYAxis *y = axisSet.yAxis;
    /*
	y.title = @"Price";
	y.titleTextStyle = axisTitleStyle;
	y.titleOffset = 20.0f;
     */
	y.axisLineStyle = axisLineStyle;
	y.majorGridLineStyle = gridLineStyle;
	y.labelTextStyle = axisTextStyle;    
	y.labelOffset = 0.0f;
	y.majorTickLineStyle = axisLineStyle;
	y.majorTickLength = 4.0f;
	y.minorTickLength = 2.0f;    
	y.tickDirection = CPTSignNegative;

    y.labelingPolicy=CPTAxisLabelingPolicyAutomatic;
    y.orthogonalCoordinateDecimal=CPTDecimalFromInt(0);
    y.visibleRange=((CPTXYPlotSpace *)y.plotSpace).yRange;
    
    
    //x2
    CPTXYAxis *x2=[[CPTXYAxis alloc]init];
    
    x2.coordinate=CPTCoordinateX;
    x2.plotSpace=[self.hostView.hostedGraph plotSpaceWithIdentifier:plotSpace2Id];
    x2.orthogonalCoordinateDecimal=CPTDecimalFromInt(0);
    x2.labelingPolicy=CPTAxisLabelingPolicyAutomatic;
    x2.labelOffset=0.0;
    x2.majorTickLength=4.0f;
    x2.majorTickLineStyle=axisLineStyle;
    x2.axisLineStyle=axisLineStyle;
    x2.labelTextStyle=axisTextStyle;
    x2.minorTickLength=2.0f;
    x2.tickDirection=CPTSignPositive;
    x2.visibleRange=((CPTXYPlotSpace *)x2.plotSpace).xRange;
    
    //y2
    CPTXYAxis *y2=[[CPTXYAxis alloc]init];
    
    y2.coordinate=CPTCoordinateY;
    
    y2.plotSpace=[self.hostView.hostedGraph plotSpaceWithIdentifier:plotSpace2Id];
    y2.visibleRange=((CPTXYPlotSpace *)y2.plotSpace).yRange;
    y2.orthogonalCoordinateDecimal=CPTDecimalFromInt(00);
    y2.labelingPolicy=CPTAxisLabelingPolicyAutomatic;
    y2.labelOffset=0.0;
    y2.majorTickLength=4.0f;
    y2.minorTickLength=2.0f;
    y2.majorTickLineStyle=axisLineStyle;
    y2.labelTextStyle=axisTextStyle;
    y2.axisLineStyle=axisLineStyle;
    y2.tickDirection=CPTSignPositive;
    
    
    self.hostView.hostedGraph.axisSet.axes=@[x,y,x2,y2];
}

#pragma mark - Rotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
	return [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
	NSInteger valueCount = [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
			if (index < valueCount) {
                NSString* xValue=[[CPDStockPriceStore sharedInstance] datesInMonth][index];
				return [NSNumber numberWithInt:[xValue intValue]];
			}
			break;
			
		case CPTScatterPlotFieldY:
			if ([plot.identifier isEqual:CPDTickerSymbolAAPL] == YES) {
				return [[[CPDStockPriceStore sharedInstance] monthlyPrices:CPDTickerSymbolAAPL] objectAtIndex:index];
			} else if ([plot.identifier isEqual:CPDTickerSymbolGOOG] == YES) {
				return [[[CPDStockPriceStore sharedInstance] monthlyPrices:CPDTickerSymbolGOOG] objectAtIndex:index];               
			} else if ([plot.identifier isEqual:CPDTickerSymbolMSFT] == YES) {
				return [[[CPDStockPriceStore sharedInstance] monthlyPrices:CPDTickerSymbolMSFT] objectAtIndex:index];               
			}
			break;
	}
	return [NSDecimalNumber zero];
}

@end
