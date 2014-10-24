//
//  PieChartViewController.m
//  ScatterPlotDemo
//
//  Created by yuan.yinchun on 14/10/14.
//  Copyright (c) 2014 yyc. All rights reserved.
//

#import "PieChartViewController.h"

@interface PieChartViewController ()

@property (nonatomic,readwrite) NSMutableArray *cumulateArray;

@property (nonatomic) CGFloat outerRadius;
@property (nonatomic) CGFloat innerRadius;
@property (nonatomic,readwrite) NSMutableArray *source;

@property (nonatomic,readwrite) CPTPieChart *currentPieChart;
@property (nonatomic,readwrite) CPTPieChart *toBeVisible;

@end

@implementation PieChartViewController


#pragma mark - Life Cycle

-(id)init
{
    self=[super init];
    if(self){
        self.myPlotData=[[NSMutableArray alloc]init];
        self.myColor=@{
                       @"error":[UIColor colorWithRed:251/255.0 green:177/255.0 blue:80/255.0 alpha:1.0],
                       @"warning":[UIColor colorWithRed:109/255.0 green:216/255.0 blue:198/255.0 alpha:1.0],
                       @"notify":[UIColor colorWithRed:39/255.0 green:213/255.0 blue:60/255.0 alpha:1.0 ],
                       @"info":[UIColor colorWithRed:251/255.0 green:220/255.0 blue:34/255.0 alpha:1.0],
                       @"fatal":[UIColor colorWithRed:230/255.0 green:76/255.0 blue:101/255.0 alpha:1.0],
                       @"seperator":[UIColor clearColor]
                       };
        
        self.source=[[NSMutableArray alloc]init];
        [self.source addObject:[NSMutableArray arrayWithObjects:@"error",@12,@45, nil]];
        [self.source addObject:[NSMutableArray arrayWithObjects:@"warning",@1,@73, nil]];
        [self.source addObject:[NSMutableArray arrayWithObjects:@"notify",@1,@59, nil]];
        [self.source addObject:[NSMutableArray arrayWithObjects:@"info",@6,@88, nil]];
        [self.source addObject:[NSMutableArray arrayWithObjects:@"fatal",@8,@31, nil]];

        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self configureHost];
    [self configureGraph];
    [self configurePieCharts];
    [self checkPlotData];
    
    
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(changePlotData) userInfo:nil repeats:YES];
 
    //[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hideTest) userInfo:nil repeats:YES];
    
}

-(void)hideTest
{
    /*
    BOOL flagZero=self.pieChartZero.hidden;
    self.pieChartZero.hidden=!flagZero;
    [self.pieChartZero setNeedsDisplay];
   
    
    BOOL flagOne=self.pieChartOne.hidden;
    self.pieChartOne.hidden=!flagOne;
    
    
    BOOL flag=self.pieChart.hidden;
    self.pieChart.hidden=!flag;
    */
    
    int opacityZero=self.pieChartZero.opacity;
    
    [CPTAnimation animate:self.pieChartZero property:@"opacity" from:opacityZero to:!opacityZero duration:1];
    
    //self.pieChartZero.opacity=!opacityZero;
    
    int opacityOne=self.pieChartOne.opacity;
    self.pieChartOne.opacity=!opacityOne;
    
    int opacity=self.pieChart.opacity;
    self.pieChart.opacity=!opacity;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Config

-(void)configureHost {
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:CGRectMake(0, 0, 320, 150)];
    self.hostView.allowPinchScaling = NO;
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

-(void)configurePieCharts
{
    self.outerRadius = 50.0;
    self.innerRadius = self.outerRadius / 2.0;
    [self configPieChartZero];
    [self configPieChartOne];
    [self configPieChart];
    
    self.pieChartZero.opacity=1;
    self.pieChartOne.opacity=0;
    self.pieChart.opacity=0;
    self.currentPieChart=self.pieChartZero;
}



-(void)configPieChartZero
{
    CPTPieChart *pieChart = [[CPTPieChart alloc] init];
    pieChart.dataSource      = self;
    pieChart.pieRadius       = self.outerRadius;
    pieChart.pieInnerRadius  = self.innerRadius + 5.0;
    pieChart.identifier      = @"outer";
    pieChart.startAngle=M_PI;
    pieChart.sliceDirection  = CPTPieDirectionClockwise;
    pieChart.adjustLabelAnchors=NO;
    pieChart.enableSeperator=YES;
    pieChart.delegate = self;
    pieChart.centerAnchor=CGPointMake(0.2, 0.5);
    self.pieChartZero=pieChart;
    
    CPTFill *shadowFill=[CPTFill fillWithColor:[CPTColor colorWithComponentRed:1 green:1 blue:1 alpha:0.1]];
    pieChart.shadowFill=shadowFill;
    
    CPTMutableTextStyle *totalStyle=[CPTMutableTextStyle textStyle];
    totalStyle.color=[CPTColor lightGrayColor];
    pieChart.totalTextStyle=totalStyle;
    
    [self.hostView.hostedGraph addPlot:pieChart];
    
    /*
    CPTMutableTextStyle *style=[CPTMutableTextStyle textStyle];
    style.fontSize=10;
    style.color=[CPTColor blueColor];
    CPTTextLayer *layer=[[CPTTextLayer alloc] initWithText:@"当前系统运行状况良好" style:style];
    layer.anchorPoint=CGPointMake(0.5, 0.5);
    CPTLayerAnnotation *anno=[[CPTLayerAnnotation alloc]initWithAnchorLayer:layer];
    [self.pieChartZero addAnnotation:anno];
     */


}

-(void)configPieChartOne
{
    CPTPieChart *pieChart = [[CPTPieChart alloc] init];
    pieChart.dataSource      = self;
    pieChart.pieRadius       = self.outerRadius;
    pieChart.pieInnerRadius  = self.innerRadius + 5.0;
    pieChart.identifier      = @"outer";
    pieChart.labelOffset=50.0;
    pieChart.customizeLabelPosition=YES;
    pieChart.startAngle=M_PI;
    pieChart.sliceDirection  = CPTPieDirectionClockwise;
    pieChart.adjustLabelAnchors=NO;
    pieChart.enableSeperator=YES;
    pieChart.delegate = self;
    pieChart.centerAnchor=CGPointMake(0.2, 0.5);
    self.pieChartOne=pieChart;
    
    CPTMutableLineStyle *lineStyle=[CPTMutableLineStyle lineStyle];
    lineStyle.lineFill=[CPTFill fillWithColor:[CPTColor lightGrayColor]];
    lineStyle.lineCap=kCGLineCapRound;
    pieChart.dataLabelLineStyle=lineStyle;
    
    CPTFill *shadowFill=[CPTFill fillWithColor:[CPTColor colorWithComponentRed:1 green:1 blue:1 alpha:0.1]];
    pieChart.shadowFill=shadowFill;
    
    CPTMutableTextStyle *totalStyle=[CPTMutableTextStyle textStyle];
    totalStyle.color=[CPTColor lightGrayColor];
    pieChart.totalTextStyle=totalStyle;
    
    [self.hostView.hostedGraph addPlot:pieChart];

}

-(void)configPieChart
{
    CPTPieChart *pieChart = [[CPTPieChart alloc] init];
    pieChart.dataSource      = self;
    pieChart.pieRadius       = self.outerRadius;
    pieChart.pieInnerRadius  = self.innerRadius + 5.0;
    pieChart.identifier      = @"outer";
    pieChart.labelOffset=50.0;
    pieChart.customizeLabelPosition=YES;
    pieChart.startAngle=M_PI_2;
    pieChart.sliceDirection  = CPTPieDirectionClockwise;
    pieChart.adjustLabelAnchors=NO;
    pieChart.enableSeperator=YES;
    pieChart.delegate = self;
    pieChart.centerAnchor=CGPointMake(0.5, 0.5);
    self.pieChart=pieChart;
    
    CPTMutableLineStyle *lineStyle=[CPTMutableLineStyle lineStyle];
    lineStyle.lineFill=[CPTFill fillWithColor:[CPTColor lightGrayColor]];
    lineStyle.lineCap=kCGLineCapRound;
    pieChart.dataLabelLineStyle=lineStyle;
    
    CPTFill *shadowFill=[CPTFill fillWithColor:[CPTColor colorWithComponentRed:1 green:1 blue:1 alpha:0.1]];
    pieChart.shadowFill=shadowFill;
    
    CPTMutableTextStyle *totalStyle=[CPTMutableTextStyle textStyle];
    totalStyle.color=[CPTColor lightGrayColor];
    pieChart.totalTextStyle=totalStyle;
    
    [self.hostView.hostedGraph addPlot:pieChart];
    
}

#pragma mark - Data generation

-(void)checkPlotData
{
    switch ([self.myPlotData count]) {
        case 0:
        {
            [self.myPlotData addObjectsFromArray:
             @[
               @[@"notify",@10,@10],
               @[@"notify",@10,@10]
               ]
             ];
            [self insertSeperatorData];
            self.pieChartZero.totalNumber=0; //manually set total number;
            
        }
            break;
        case 1:
        {
            [self.myPlotData addObject:[self.myPlotData[0] mutableCopy]];
            [self insertSeperatorData];
            self.pieChartOne.totalNumber=[self.myPlotData[0][2] intValue]; //manually set total number;
        }
            break;
        default:
        {
            [self insertSeperatorData];
        }
            break;
    }
}

-(void)changePlotData{
   
    int itemNum=arc4random()%6;//0~5
    //int itemNum=0;
    
    
    if (itemNum==0) {
        [self.myPlotData removeAllObjects];
        [self checkPlotData];
        
        self.toBeVisible=self.pieChartZero;
        [CPTAnimation animate:self.currentPieChart property:@"opacity" from:1 to:0 duration:2 withDelay:0 animationCurve:CPTAnimationCurveBackIn delegate:self];
        
        /*
        [CPTAnimation animate:self.currentPieChart property:@"opacity" from:1 to:0 duration:1];
        [self.pieChartZero reloadData];
        [self.pieChartZero reloadSliceFills];
        [CPTAnimation animate:self.pieChartZero property:@"opacity" from:0 to:1 duration:1];
        self.currentPieChart=self.pieChartZero;
         */
        return;
    }
    if (itemNum==1) {
        [self.myPlotData removeAllObjects];
        [self.myPlotData addObject:[self.source[arc4random()%5] mutableCopy] ]; //add one random data;
        [self checkPlotData];
        
        self.toBeVisible=self.pieChartOne;
        [CPTAnimation animate:self.currentPieChart property:@"opacity" from:1 to:0 duration:2 withDelay:0 animationCurve:CPTAnimationCurveBackIn delegate:self];
         
        
        /*
        [CPTAnimation animate:self.currentPieChart property:@"opacity" from:1 to:0 duration:2];
        [self.pieChartOne reloadData];
        [self.pieChartOne reloadSliceFills];
        [CPTAnimation animate:self.pieChartOne property:@"opacity" from:0 to:1 duration:2];
        self.currentPieChart=self.pieChartOne;
        */
        return;
    }
    
    //2~5 itemNum
    [self.myPlotData removeAllObjects];
    int startIdx=arc4random()%5;
    for (int i=0; i<itemNum; i++) {
        [self.myPlotData addObject:self.source[(startIdx+i)%[self.source count]]];
    }
    
    for (int i=0; i<itemNum; i++) {
        NSNumber *num=[NSNumber numberWithInt:arc4random() % (1000+1)];//0~100
        self.myPlotData[i][2]=num;
    }
    [self checkPlotData];
    [self rearrangeData];
    
    self.toBeVisible=self.pieChart;
    [CPTAnimation animate:self.currentPieChart property:@"opacity" from:1 to:0 duration:2 withDelay:0 animationCurve:CPTAnimationCurveBackIn delegate:self];
    
    /*
    [CPTAnimation animate:self.currentPieChart property:@"opacity" from:1 to:0 duration:2];
    
    [self.pieChart reloadData]; //reload plotData and dataLabels
    [self.pieChart reloadSliceFills];
    
    [CPTAnimation animate:self.pieChart property:@"opacity" from:0 to:1 duration:2];
    self.currentPieChart=self.pieChart;
     */
}


-(double)getSeperatorData
{
    int totalNumber=0;
    double seperatorData=0.0;
    int factor=512;
    int currentCount=[self.myPlotData count];
    
   
    for (NSArray *array in self.myPlotData) {
        totalNumber+=[array[2] intValue];
    }
    
    seperatorData= M_PI*totalNumber/(factor-currentCount*M_PI);
    return seperatorData;
}


-(void)insertSeperatorData
{
    
    double seperatorData=[self getSeperatorData];
    NSMutableArray *newArray=[[NSMutableArray alloc]init];
    for (NSArray * array in self.myPlotData) {
        [newArray addObject:array];
        [newArray addObject:[NSMutableArray arrayWithObjects:@"seperator",[NSNumber numberWithDouble:seperatorData],[NSNumber numberWithDouble:seperatorData], nil ]];
    }
    self.myPlotData=newArray;
    
}


#pragma mark - Rearrange origin data

-(void)rearrangeData
{
    BOOL pass;
    NSMutableArray *left=[[NSMutableArray alloc]init];
    NSMutableArray *right=[[NSMutableArray alloc]init];
    int count=0;
    
    do {
        if (count==5) {
            break;
        }
        
        [left removeAllObjects];
        [right removeAllObjects];
        [self getCumulateArray];
        [self caculateLeft:left right:right];
        if ([left count]==3 && [right count]==2) {
            NSLog(@"pause");
        }
        pass=[self passTest:left :right];
        if(!pass){
            [self shuffleData:left right:right];
            count++;
        }
    } while (!pass);
    
}

-(void)shuffleData:(NSMutableArray *)left right:(NSMutableArray *)right
{
    switch ([self.myPlotData count]/2) {
        case 5:
            switch ([left count]) {
                case 1:  //1+4
                    [self moveDataFrom:right to:left direction:YES num:1];
                    break;
                case 3: //3+2
                    [self moveDataFrom:left to:right direction:NO num:3];
                    break;
                case 4: //4+1
                    [self moveDataFrom:left to:right direction:NO num:2];
                    break;
            }
            break;
        case 4:
            switch ([left count]) {
                case 1: //1+3
                    [self moveDataFrom:right to:left direction:YES num:1];
                    break;
                case 3: //3+1
                    [self moveDataFrom:left to:right direction:NO num:1];
                default:
                    break;
            }
            break;
        case 3:
            switch ([left count]) {
                case 2: //2+1
                    [self moveDataFrom:left to:right direction:NO num:2];
                    break;
                default:
                    break;
            }
            break;
        case 2:
            
            break;
        case 1:
            
            break;
        default:
            break;
    }
}


-(void)moveDataFrom:(NSMutableArray *)from to:(NSMutableArray *)to
          direction:(BOOL)rightToLeft
                num:(int)num
{
    
    //sort array "from" in asceding order
    for(int i=0;i<[from count];i++){
        int smallest=INT_MAX;
        int smallestIdx=-1;
        for (int j=i; j<[from count]; j++) {
            int current=[self.myPlotData[[from[j] intValue]][2] intValue];
            if (current<smallest) {
                smallest=current;
                smallestIdx=j;
            }
        }
        
        [from exchangeObjectAtIndex:i withObjectAtIndex:smallestIdx];
    }
    
    
    //move 'num' smallest in 'from' to the end of self.myPlotData
    NSMutableArray *tmpArray=[[NSMutableArray alloc]init];
    NSMutableIndexSet *indexSet=[NSMutableIndexSet indexSet];
    for (int i=0; i<num; i++) {
        int idx=[from[i] intValue];
        [indexSet addIndex:idx];
        [indexSet addIndex:idx+1];
        [tmpArray addObject: [self.myPlotData[idx] mutableCopy]];
        [tmpArray addObject: [self.myPlotData[idx+1] mutableCopy]];
    }
    
    
    
    [self.myPlotData removeObjectsAtIndexes:indexSet];
    
    if (rightToLeft) {
        [self.myPlotData addObjectsFromArray:tmpArray];
    }else
    {
        for (int i=0;i<[tmpArray count];i+=2){
            [self.myPlotData insertObject:tmpArray[i+1] atIndex:0];
            [self.myPlotData insertObject:tmpArray[i] atIndex:0];
        }
        
    }
}

-(BOOL)passTest:(NSMutableArray *)left :(NSMutableArray *)right
{
    
    switch ([self.myPlotData count]/2) {
        case 5:
            if ([left count]==2 && [right count]==3)
                return true;
            else
                return false;
            break;
        case 4:
            if ([left count]==2 && [right count]==2)
                return true;
            else
                return false;
            break;
        case 3:
            if ([left count]==1 && [right count]==2)
                return true;
            else
                return false;
            break;
        case 2:
            if ([left count]==1 && [right count]==1)
                return true;
            else
                return false;            break;
        case 1:
            if ([left count]==1 && [right count]==2)
                return true;
            else
                return false;
            break;
        default:
            return true;
            break;
    }
}

-(void)caculateLeft:(NSMutableArray *)left right:(NSMutableArray *)right
{
    double total=[[self.cumulateArray lastObject][2] doubleValue];
    double center=0.0;
    
    center=[self.cumulateArray[0][2] doubleValue]/2;
    double radius=center/total*2*M_PI;
    //if(radius >=M_PI_2 && radius <=3*M_PI_2)
    if(radius >=0 && radius <=M_PI)
    {
        //[left addObject:@0];
        [right addObject:@0];
    }
    else
        //[right addObject:@0];
        [left addObject:@0];
    
    for (int i=2; i<[self.cumulateArray count]; i+=2) {
        center=[self.cumulateArray[i-1][2] doubleValue]+[self.myPlotData[i][2] doubleValue]/2;
        radius=center/total*2*M_PI;
        // if(radius >=M_PI_2 && radius <=3*M_PI_2)
        if(radius >=0 && radius <=M_PI)
        {
            //[left addObject:[NSNumber numberWithInt:i]];
            [right addObject:[NSNumber numberWithInt:i]];
        }
        else
            //[right addObject:[NSNumber numberWithInt:i]];
            [left addObject:[NSNumber numberWithInt:i]];
    }
    
}

-(void)getCumulateArray
{
    //true deep copy
    self.cumulateArray=[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.myPlotData]];
    for (int i=1; i<[self.cumulateArray count]; i++) {
        double current;
        double previous;
        current=[self.cumulateArray[i][2] doubleValue];
        previous=[self.cumulateArray[i-1][2] doubleValue];
        self.cumulateArray[i][2]=[NSNumber numberWithDouble:previous+current];
    }
    
}


#pragma mark - Screenshot

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





#pragma mark - Plot Data Source Methods

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
    if (plot==self.pieChartZero || plot==self.pieChartOne) {
        return nil;
    }
    
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
        
        NSMutableAttributedString *unRead=[[NSMutableAttributedString alloc]initWithString:[_myPlotData[index][1]  stringValue ] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20],NSForegroundColorAttributeName:[UIColor whiteColor]} ];
        
        NSMutableString *allStr=[[NSMutableString alloc]initWithString:@"/"];
        [allStr appendString:[_myPlotData[index][2]  stringValue ]];
        
        NSMutableAttributedString *all=[[NSMutableAttributedString alloc]initWithString:allStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15],NSForegroundColorAttributeName:[UIColor grayColor]} ];
        
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

#pragma mark - CPTAnimation Delegate

-(void)animationDidFinish:(CPTAnimationOperation *)operation
{
    [self.toBeVisible reloadData];
    [self.toBeVisible reloadSliceFills];
    [CPTAnimation animate:self.toBeVisible property:@"opacity" from:0 to:1 duration:2];
    self.currentPieChart=self.toBeVisible;
}

@end
