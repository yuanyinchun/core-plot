#import "CPTPieChart.h"

#import "CPTColor.h"
#import "CPTFill.h"
#import "CPTLegend.h"
#import "CPTLineStyle.h"
#import "CPTTextStyle.h"
#import "CPTMutableTextStyle.h"
#import "CPTMutableNumericData.h"
#import "CPTPathExtensions.h"
#import "CPTPlotArea.h"
#import "CPTPlotSpace.h"
#import "CPTPlotSpaceAnnotation.h"
#import "CPTUtilities.h"
#import "NSCoderExtensions.h"
#import "NSNumberExtensions.h"
#import <tgmath.h>

/** @defgroup plotAnimationPieChart Pie Chart
 *  @brief Pie chart properties that can be animated using Core Animation.
 *  @ingroup plotAnimation
 **/

/** @if MacOnly
 *  @defgroup plotBindingsPieChart Pie Chart Bindings
 *  @brief Binding identifiers for pie charts.
 *  @ingroup plotBindings
 *  @endif
 **/

NSString *const CPTPieChartBindingPieSliceWidthValues   = @"sliceWidths";        ///< Pie slice widths.
NSString *const CPTPieChartBindingPieSliceFills         = @"sliceFills";         ///< Pie slice interior fills.
NSString *const CPTPieChartBindingPieSliceRadialOffsets = @"sliceRadialOffsets"; ///< Pie slice radial offsets.

/// @cond
@interface CPTPieChart()

@property (nonatomic, readwrite, copy) NSArray *sliceWidths;
@property (nonatomic, readwrite, copy) NSArray *sliceFills;
@property (nonatomic, readwrite, copy) NSArray *sliceRadialOffsets;
@property (nonatomic, readwrite, assign) NSUInteger pointingDeviceDownIndex;

-(void)updateNormalizedData;
-(CGFloat)radiansForPieSliceValue:(CGFloat)pieSliceValue;
-(CGFloat)normalizedPosition:(CGFloat)rawPosition;
-(BOOL)angle:(CGFloat)touchedAngle betweenStartAngle:(CGFloat)startingAngle endAngle:(CGFloat)endingAngle;

-(void)addSliceToPath:(CGMutablePathRef)slicePath centerPoint:(CGPoint)center startingAngle:(CGFloat)startingAngle finishingAngle:(CGFloat)finishingAngle;
-(CPTFill *)sliceFillForIndex:(NSUInteger)idx;

@end

/// @endcond

#pragma mark -

/**
 *  @brief A pie chart.
 *  @see See @ref plotAnimationPieChart "Pie Chart" for a list of animatable properties.
 *  @if MacOnly
 *  @see See @ref plotBindingsPieChart "Pie Chart Bindings" for a list of supported binding identifiers.
 *  @endif
 **/
@implementation CPTPieChart

@dynamic sliceWidths;
@dynamic sliceFills;
@dynamic sliceRadialOffsets;

/** @property CGFloat pieRadius
 *  @brief The radius of the overall pie chart. Defaults to @num{80%} of the initial frame size.
 *  @ingroup plotAnimationPieChart
 **/
@synthesize pieRadius;

/** @property CGFloat pieInnerRadius
 *  @brief The inner radius of the pie chart, used to create a @quote{donut hole}. Defaults to 0.
 *  @ingroup plotAnimationPieChart
 **/
@synthesize pieInnerRadius;

/** @property CGFloat startAngle
 *  @brief The starting angle for the first slice in radians. Defaults to @num{π/2}.
 *  @ingroup plotAnimationPieChart
 **/
@synthesize startAngle;

/** @property CGFloat endAngle
 *  @brief The ending angle for the last slice in radians. If @NAN, the ending angle
 *  is the same as the start angle, i.e., the pie slices fill the whole circle. Defaults to @NAN.
 *  @ingroup plotAnimationPieChart
 **/
@synthesize endAngle;

/** @property CPTPieDirection sliceDirection
 *  @brief Determines whether the pie slices are drawn in a clockwise or counter-clockwise
 *  direction from the starting point. Defaults to clockwise.
 **/
@synthesize sliceDirection;

/** @property CGPoint centerAnchor
 *  @brief The position of the center of the pie chart with the x and y coordinates
 *  given as a fraction of the width and height, respectively. Defaults to (@num{0.5}, @num{0.5}).
 *  @ingroup plotAnimationPieChart
 **/
@synthesize centerAnchor;

/** @property CPTLineStyle *borderLineStyle
 *  @brief The line style used to outline the pie slices.  If @nil, no border is drawn.  Defaults to @nil.
 **/
@synthesize borderLineStyle;

@synthesize dataLabelLineStyle;

@synthesize totalTextStyle;

@synthesize totalNumber;

@synthesize shadowFill;

@synthesize leftLabels;

@synthesize rightLabels;

@synthesize enableSeperator;


//@synthesize annotationsFrame;

/** @property CPTFill *overlayFill
 *  @brief A fill drawn on top of the pie chart.
 *  Can be used to add shading and/or gloss effects. Defaults to @nil.
 **/
@synthesize overlayFill;

/** @property BOOL labelRotationRelativeToRadius
 *  @brief If @NO, the default, the data labels are rotated relative to the default coordinate system (the positive x-axis is zero rotation).
 *  If @YES, the labels are rotated relative to the radius of the pie chart (zero rotation is parallel to the radius).
 **/
@synthesize labelRotationRelativeToRadius;

@synthesize customizeLabelPosition;

/** @internal
 *  @property NSUInteger pointingDeviceDownIndex
 *  @brief The index that was selected on the pointing device down event.
 **/
@synthesize pointingDeviceDownIndex;

#pragma mark -
#pragma mark Convenience Factory Methods

static const CGFloat colorLookupTable[10][3] =
{
    {
        CPTFloat(1.0), CPTFloat(0.0), CPTFloat(0.0)
    },{
        CPTFloat(0.0), CPTFloat(1.0), CPTFloat(0.0)
    },{
        CPTFloat(0.0), CPTFloat(0.0), CPTFloat(1.0)
    },{
        CPTFloat(1.0), CPTFloat(1.0), CPTFloat(0.0)
    },{
        CPTFloat(0.25), CPTFloat(0.5), CPTFloat(0.25)
    },{
        CPTFloat(1.0), CPTFloat(0.0), CPTFloat(1.0)
    },{
        CPTFloat(0.5), CPTFloat(0.5), CPTFloat(0.5)
    },{
        CPTFloat(0.25), CPTFloat(0.5), CPTFloat(0.0)
    },{
        CPTFloat(0.25), CPTFloat(0.25), CPTFloat(0.25)
    },{
        CPTFloat(0.0), CPTFloat(1.0), CPTFloat(1.0)
    }
};

/** @brief Creates and returns a CPTColor that acts as the default color for that pie chart index.
 *  @param pieSliceIndex The pie slice index to return a color for.
 *  @return A new CPTColor instance corresponding to the default value for this pie slice index.
 **/

+(CPTColor *)defaultPieSliceColorForIndex:(NSUInteger)pieSliceIndex
{
    return [CPTColor colorWithComponentRed:( colorLookupTable[pieSliceIndex % 10][0] + (CGFloat)(pieSliceIndex / 10) * CPTFloat(0.1) )
                                     green:( colorLookupTable[pieSliceIndex % 10][1] + (CGFloat)(pieSliceIndex / 10) * CPTFloat(0.1) )
                                      blue:( colorLookupTable[pieSliceIndex % 10][2] + (CGFloat)(pieSliceIndex / 10) * CPTFloat(0.1) )
                                     alpha:CPTFloat(1.0)];
}

#pragma mark -
#pragma mark Init/Dealloc

/// @cond

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#else
+(void)initialize
{
    if ( self == [CPTPieChart class] ) {
        [self exposeBinding:CPTPieChartBindingPieSliceWidthValues];
        [self exposeBinding:CPTPieChartBindingPieSliceFills];
        [self exposeBinding:CPTPieChartBindingPieSliceRadialOffsets];
    }
}
#endif

/// @endcond

/// @name Initialization
/// @{

/** @brief Initializes a newly allocated CPTPieChart object with the provided frame rectangle.
 *
 *  This is the designated initializer. The initialized layer will have the following properties:
 *  - @ref pieRadius = @num{40%} of the minimum of the width and height of the frame rectangle
 *  - @ref pieInnerRadius = @num{0.0}
 *  - @ref startAngle = @num{π/2}
 *  - @ref endAngle = @NAN
 *  - @ref sliceDirection = #CPTPieDirectionClockwise
 *  - @ref centerAnchor = (@num{0.5}, @num{0.5})
 *  - @ref borderLineStyle = @nil
 *  - @ref overlayFill = @nil
 *  - @ref labelRotationRelativeToRadius = @NO
 *  - @ref labelOffset = @num{10.0}
 *  - @ref labelField = #CPTPieChartFieldSliceWidth
 *
 *  @param newFrame The frame rectangle.
 *  @return The initialized CPTPieChart object.
 **/
-(instancetype)initWithFrame:(CGRect)newFrame
{
    if ( (self = [super initWithFrame:newFrame]) ) {
        pieRadius                     = CPTFloat(0.8) * ( MIN(newFrame.size.width, newFrame.size.height) / CPTFloat(2.0) );
        pieInnerRadius                = CPTFloat(0.0);
        startAngle                    = CPTFloat(M_PI_2); // pi/2
        endAngle                      = NAN;
        sliceDirection                = CPTPieDirectionClockwise;
        centerAnchor                  = CPTPointMake(0.5, 0.5);
        borderLineStyle               = nil;
        overlayFill                   = nil;
        labelRotationRelativeToRadius = NO;
        customizeLabelPosition=NO;
        enableSeperator=NO;
        //annotationsFrame=[[NSMutableArray alloc]init];
        shadowFill=nil;
        totalTextStyle=nil;
        totalNumber=-1;
        leftLabels=[[NSMutableArray alloc] init];
        rightLabels=[[NSMutableArray alloc] init];
        pointingDeviceDownIndex       = NSNotFound;

        self.labelOffset = CPTFloat(10.0);
        self.labelField  = CPTPieChartFieldSliceWidth;
    }
    return self;
}

/// @}

/// @cond

-(instancetype)initWithLayer:(id)layer
{
    if ( (self = [super initWithLayer:layer]) ) {
        CPTPieChart *theLayer = (CPTPieChart *)layer;

        pieRadius                     = theLayer->pieRadius;
        pieInnerRadius                = theLayer->pieInnerRadius;
        startAngle                    = theLayer->startAngle;
        endAngle                      = theLayer->endAngle;
        sliceDirection                = theLayer->sliceDirection;
        centerAnchor                  = theLayer->centerAnchor;
        borderLineStyle               = theLayer->borderLineStyle;
        overlayFill                   = theLayer->overlayFill;
        labelRotationRelativeToRadius = theLayer->labelRotationRelativeToRadius;
        pointingDeviceDownIndex       = NSNotFound;
    }
    return self;
}

/// @endcond

#pragma mark -
#pragma mark NSCoding Methods

/// @cond

-(void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeCGFloat:self.pieRadius forKey:@"CPTPieChart.pieRadius"];
    [coder encodeCGFloat:self.pieInnerRadius forKey:@"CPTPieChart.pieInnerRadius"];
    [coder encodeCGFloat:self.startAngle forKey:@"CPTPieChart.startAngle"];
    [coder encodeCGFloat:self.endAngle forKey:@"CPTPieChart.endAngle"];
    [coder encodeInteger:self.sliceDirection forKey:@"CPTPieChart.sliceDirection"];
    [coder encodeCPTPoint:self.centerAnchor forKey:@"CPTPieChart.centerAnchor"];
    [coder encodeObject:self.borderLineStyle forKey:@"CPTPieChart.borderLineStyle"];
    [coder encodeObject:self.overlayFill forKey:@"CPTPieChart.overlayFill"];
    [coder encodeBool:self.labelRotationRelativeToRadius forKey:@"CPTPieChart.labelRotationRelativeToRadius"];

    // No need to archive these properties:
    // pointingDeviceDownIndex
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    if ( (self = [super initWithCoder:coder]) ) {
        pieRadius                     = [coder decodeCGFloatForKey:@"CPTPieChart.pieRadius"];
        pieInnerRadius                = [coder decodeCGFloatForKey:@"CPTPieChart.pieInnerRadius"];
        startAngle                    = [coder decodeCGFloatForKey:@"CPTPieChart.startAngle"];
        endAngle                      = [coder decodeCGFloatForKey:@"CPTPieChart.endAngle"];
        sliceDirection                = (CPTPieDirection)[coder decodeIntegerForKey : @"CPTPieChart.sliceDirection"];
        centerAnchor                  = [coder decodeCPTPointForKey:@"CPTPieChart.centerAnchor"];
        borderLineStyle               = [[coder decodeObjectForKey:@"CPTPieChart.borderLineStyle"] copy];
        overlayFill                   = [[coder decodeObjectForKey:@"CPTPieChart.overlayFill"] copy];
        labelRotationRelativeToRadius = [coder decodeBoolForKey:@"CPTPieChart.labelRotationRelativeToRadius"];
        pointingDeviceDownIndex       = NSNotFound;
    }
    return self;
}

/// @endcond

#pragma mark -
#pragma mark Data Loading

/// @cond

-(void)reloadData
{
    [super reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsReloadEntriesForPlotNotification object:self];
}

-(void)reloadDataInIndexRange:(NSRange)indexRange
{
    [super reloadDataInIndexRange:indexRange];

    // Slice fills
    [self reloadSliceFillsInIndexRange:indexRange];

    // Radial offsets
    [self reloadRadialOffsetsInIndexRange:indexRange];

    // Legend
    id<CPTPieChartDataSource> theDataSource = (id<CPTPieChartDataSource>)self.dataSource;

    if ( [theDataSource respondsToSelector:@selector(legendTitleForPieChart:recordIndex:)] ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
    }
}

-(void)reloadPlotDataInIndexRange:(NSRange)indexRange
{
    [super reloadPlotDataInIndexRange:indexRange];

    if ( ![self loadNumbersForAllFieldsFromDataSourceInRecordIndexRange:indexRange] ) {
        id<CPTPieChartDataSource> theDataSource = (id<CPTPieChartDataSource>)self.dataSource;

        // Pie slice widths
        if ( theDataSource ) {
            // Grab all values from the data source
            id rawSliceValues = [self numbersFromDataSourceForField:CPTPieChartFieldSliceWidth recordIndexRange:indexRange];
            [self cacheNumbers:rawSliceValues forField:CPTPieChartFieldSliceWidth atRecordIndex:indexRange.location];
        }
        else {
            [self cacheNumbers:nil forField:CPTPieChartFieldSliceWidth];
        }
    }

    [self updateNormalizedData];
}

-(void)insertDataAtIndex:(NSUInteger)idx numberOfRecords:(NSUInteger)numberOfRecords
{
    [super insertDataAtIndex:idx numberOfRecords:numberOfRecords];
    [[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsReloadEntriesForPlotNotification object:self];
}

-(void)deleteDataInIndexRange:(NSRange)indexRange
{
    [super deleteDataInIndexRange:indexRange];
    [self updateNormalizedData];

    [[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsReloadEntriesForPlotNotification object:self];
}

-(void)updateNormalizedData
{
    // Normalize these widths to 1.0 for the whole pie
    NSUInteger sampleCount = self.cachedDataCount;

    if ( sampleCount > 0 ) {
        CPTMutableNumericData *rawSliceValues = [self cachedNumbersForField:CPTPieChartFieldSliceWidth];
        if ( self.doublePrecisionCache ) {
            double valueSum         = 0.0;
            const double *dataBytes = (const double *)rawSliceValues.bytes;
            const double *dataEnd   = dataBytes + sampleCount;
            while ( dataBytes < dataEnd ) {
                double currentWidth = *dataBytes++;
                if ( !isnan(currentWidth) ) {
                    valueSum += currentWidth;
                }
            }

            CPTNumericDataType dataType = CPTDataType( CPTFloatingPointDataType, sizeof(double), CFByteOrderGetCurrent() );

            CPTMutableNumericData *normalizedSliceValues = [[CPTMutableNumericData alloc] initWithData:[NSData data] dataType:dataType shape:nil];
            normalizedSliceValues.shape = @[@(sampleCount)];
            CPTMutableNumericData *cumulativeSliceValues = [[CPTMutableNumericData alloc] initWithData:[NSData data] dataType:dataType shape:nil];
            cumulativeSliceValues.shape = @[@(sampleCount)];

            double cumulativeSum = 0.0;

            dataBytes = (const double *)rawSliceValues.bytes;
            double *normalizedBytes = normalizedSliceValues.mutableBytes;
            double *cumulativeBytes = cumulativeSliceValues.mutableBytes;
            while ( dataBytes < dataEnd ) {
                double currentWidth = *dataBytes++;
                if ( isnan(currentWidth) ) {
                    *normalizedBytes++ = NAN;
                }
                else {
                    *normalizedBytes++ = currentWidth / valueSum;
                    cumulativeSum     += currentWidth;
                }
                *cumulativeBytes++ = cumulativeSum / valueSum;
            }
            [self cacheNumbers:normalizedSliceValues forField:CPTPieChartFieldSliceWidthNormalized];
            [self cacheNumbers:cumulativeSliceValues forField:CPTPieChartFieldSliceWidthSum];
        }
        else {
            NSDecimal valueSum         = CPTDecimalFromInteger(0);
            const NSDecimal *dataBytes = (const NSDecimal *)rawSliceValues.bytes;
            const NSDecimal *dataEnd   = dataBytes + sampleCount;
            while ( dataBytes < dataEnd ) {
                NSDecimal currentWidth = *dataBytes++;
                if ( !NSDecimalIsNotANumber(&currentWidth) ) {
                    valueSum = CPTDecimalAdd(valueSum, currentWidth);
                }
            }

            CPTNumericDataType dataType = CPTDataType( CPTDecimalDataType, sizeof(NSDecimal), CFByteOrderGetCurrent() );

            CPTMutableNumericData *normalizedSliceValues = [[CPTMutableNumericData alloc] initWithData:[NSData data] dataType:dataType shape:nil];
            normalizedSliceValues.shape = @[@(sampleCount)];
            CPTMutableNumericData *cumulativeSliceValues = [[CPTMutableNumericData alloc] initWithData:[NSData data] dataType:dataType shape:nil];
            cumulativeSliceValues.shape = @[@(sampleCount)];

            NSDecimal cumulativeSum = CPTDecimalFromInteger(0);

            NSDecimal decimalNAN = CPTDecimalNaN();
            dataBytes = (const NSDecimal *)rawSliceValues.bytes;
            NSDecimal *normalizedBytes = normalizedSliceValues.mutableBytes;
            NSDecimal *cumulativeBytes = cumulativeSliceValues.mutableBytes;
            while ( dataBytes < dataEnd ) {
                NSDecimal currentWidth = *dataBytes++;
                if ( NSDecimalIsNotANumber(&currentWidth) ) {
                    *normalizedBytes++ = decimalNAN;
                }
                else {
                    *normalizedBytes++ = CPTDecimalDivide(currentWidth, valueSum);
                    cumulativeSum      = CPTDecimalAdd(cumulativeSum, currentWidth);
                }
                *cumulativeBytes++ = CPTDecimalDivide(cumulativeSum, valueSum);
            }
            [self cacheNumbers:normalizedSliceValues forField:CPTPieChartFieldSliceWidthNormalized];
            [self cacheNumbers:cumulativeSliceValues forField:CPTPieChartFieldSliceWidthSum];
        }
    }
    else {
        [self cacheNumbers:nil forField:CPTPieChartFieldSliceWidthNormalized];
        [self cacheNumbers:nil forField:CPTPieChartFieldSliceWidthSum];
    }

    // Labels
    id<CPTPlotDataSource> theDataSource = self.dataSource;
    [self relabelIndexRange:NSMakeRange(0, [theDataSource numberOfRecordsForPlot:self])];
}

/// @endcond

/**
 *  @brief Reload all slice fills from the data source immediately.
 **/
-(void)reloadSliceFills
{
    [self reloadSliceFillsInIndexRange:NSMakeRange(0, self.cachedDataCount)];
}

/** @brief Reload slice fills in the given index range from the data source immediately.
 *  @param indexRange The index range to load.
 **/
-(void)reloadSliceFillsInIndexRange:(NSRange)indexRange
{
    id<CPTPieChartDataSource> theDataSource = (id<CPTPieChartDataSource>)self.dataSource;

    BOOL needsLegendUpdate = NO;

    if ( [theDataSource respondsToSelector:@selector(sliceFillsForPieChart:recordIndexRange:)] ) {
        needsLegendUpdate = YES;

        [self cacheArray:[theDataSource sliceFillsForPieChart:self recordIndexRange:indexRange]
                  forKey:CPTPieChartBindingPieSliceFills
           atRecordIndex:indexRange.location];
    }
    else if ( [theDataSource respondsToSelector:@selector(sliceFillForPieChart:recordIndex:)] ) {
        needsLegendUpdate = YES;

        id nilObject          = [CPTPlot nilData];
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:indexRange.length];
        NSUInteger maxIndex   = NSMaxRange(indexRange);

        for ( NSUInteger idx = indexRange.location; idx < maxIndex; idx++ ) {
            CPTFill *dataSourceFill = [theDataSource sliceFillForPieChart:self recordIndex:idx];
            if ( dataSourceFill ) {
                [array addObject:dataSourceFill];
            }
            else {
                [array addObject:nilObject];
            }
        }

        [self cacheArray:array forKey:CPTPieChartBindingPieSliceFills atRecordIndex:indexRange.location];
    }

    // Legend
    if ( needsLegendUpdate ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
    }

    [self setNeedsDisplay];
}

/**
 *  @brief Reload all slice offsets from the data source immediately.
 **/
-(void)reloadRadialOffsets
{
    [self reloadRadialOffsetsInIndexRange:NSMakeRange(0, self.cachedDataCount)];
}

/** @brief Reload slice offsets in the given index range from the data source immediately.
 *  @param indexRange The index range to load.
 **/
-(void)reloadRadialOffsetsInIndexRange:(NSRange)indexRange
{
    id<CPTPieChartDataSource> theDataSource = (id<CPTPieChartDataSource>)self.dataSource;

    if ( [theDataSource respondsToSelector:@selector(radialOffsetsForPieChart:recordIndexRange:)] ) {
        [self cacheArray:[theDataSource radialOffsetsForPieChart:self recordIndexRange:indexRange]
                  forKey:CPTPieChartBindingPieSliceRadialOffsets
           atRecordIndex:indexRange.location];
    }
    else if ( [theDataSource respondsToSelector:@selector(radialOffsetForPieChart:recordIndex:)] ) {
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:indexRange.length];
        NSUInteger maxIndex   = NSMaxRange(indexRange);

        for ( NSUInteger idx = indexRange.location; idx < maxIndex; idx++ ) {
            CGFloat offset = [theDataSource radialOffsetForPieChart:self recordIndex:idx];
            [array addObject:@(offset)];
        }

        [self cacheArray:array forKey:CPTPieChartBindingPieSliceRadialOffsets atRecordIndex:indexRange.location];
    }

    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Drawing

/// @cond

-(void)renderAsVectorInContext:(CGContextRef)context
{
    if ( self.hidden ) {
        return;
    }

    NSUInteger sampleCount = self.cachedDataCount;
    if ( sampleCount == 0 ) {
        return;
    }

    CPTPlotArea *thePlotArea = self.plotArea;
    if ( !thePlotArea ) {
        return;
    }

    [super renderAsVectorInContext:context];
    
    CGContextBeginTransparencyLayer(context, NULL);

    CGRect plotAreaBounds = thePlotArea.bounds;
    CGPoint anchor        = self.centerAnchor;
    CGPoint centerPoint   = CPTPointMake(plotAreaBounds.origin.x + plotAreaBounds.size.width * anchor.x,
                                         plotAreaBounds.origin.y + plotAreaBounds.size.height * anchor.y);
    centerPoint = [self convertPoint:centerPoint fromLayer:thePlotArea];
    if ( self.alignsPointsToPixels ) {
        centerPoint = CPTAlignPointToUserSpace(context, centerPoint);
    }

    NSUInteger currentIndex = 0;
    CGFloat startingWidth   = CPTFloat(0.0);

    CPTLineStyle *borderStyle = self.borderLineStyle;
    CPTFill *overlay          = self.overlayFill;

    BOOL hasNonZeroOffsets = NO;
    NSArray *offsetArray   = [self cachedArrayForKey:CPTPieChartBindingPieSliceRadialOffsets];
    for ( NSNumber *offset in offsetArray ) {
        if ( [offset cgFloatValue] != CPTFloat(0.0) ) {
            hasNonZeroOffsets = YES;
            break;
        }
    }

    CGRect bounds;
    if ( overlay && hasNonZeroOffsets ) {
        CGFloat radius = self.pieRadius + borderStyle.lineWidth * CPTFloat(0.5);

        bounds = CPTRectMake( centerPoint.x - radius, centerPoint.y - radius, radius * CPTFloat(2.0), radius * CPTFloat(2.0) );
    }

    [borderStyle setLineStyleInContext:context];
    Class fillClass = [CPTFill class];
    
    
    //draw underline for each data label
    NSUInteger idx=0;
    NSUInteger multiplyFactor=self.enableSeperator?2:1;
    //NSUInteger tailFactor=self.enableSeperator?1:0;
    for (CPTPlotSpaceAnnotation *anno in self.annotations) {
        
        //NSLog(@"%@",NSStringFromCGRect(anno.contentLayer.frame) );
        
        CGRect frame=[self convertRect:anno.contentLayer.frame toLayer:thePlotArea];
        // NSLog(@"%@",NSStringFromCGRect(frame) );
        // NSLog(@"--------------");
        
        
        CGMutablePathRef mypath=CGPathCreateMutable();
        CGPoint originPoint=frame.origin;
        CGPoint tailPoint=CGPointMake(frame.origin.x+frame.size.width, frame.origin.y);
        
        CGFloat medianAngle=[self medianAngleForPieSliceIndex:multiplyFactor*idx];
        CGPoint medianPoint=CGPointMake(centerPoint.x+self.pieRadius*cos(medianAngle), centerPoint.y+self.pieRadius*sin(medianAngle));
        
        if ( self.alignsPointsToPixels ) {
            originPoint = CPTAlignPointToUserSpace(context, originPoint);
            tailPoint = CPTAlignIntegralPointToUserSpace(context, tailPoint);
            medianPoint = CPTAlignIntegralPointToUserSpace(context, medianPoint);
        }
        
        if ([self.leftLabels containsObject:[NSNumber numberWithUnsignedInteger:multiplyFactor*idx]]) {
            CGPathMoveToPoint(mypath, NULL, medianPoint.x, medianPoint.y);
            CGPathAddLineToPoint(mypath, NULL, tailPoint.x,tailPoint.y);
            CGPathAddLineToPoint(mypath, NULL, originPoint.x,originPoint.y);
        }
        if ([self.rightLabels containsObject:[NSNumber numberWithUnsignedInteger:multiplyFactor*idx]]) {
            CGPathMoveToPoint(mypath, NULL, medianPoint.x, medianPoint.y);
            CGPathAddLineToPoint(mypath, NULL, originPoint.x,originPoint.y);
            CGPathAddLineToPoint(mypath, NULL, tailPoint.x,tailPoint.y);
        }
        
        
        CGContextBeginPath(context);
        CGContextAddPath(context, mypath);
        [self.dataLabelLineStyle strokePathInContext:context];
        CGPathRelease(mypath);
        idx++;
    }

    
    while ( currentIndex < sampleCount ) {
        CGFloat currentWidth = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthNormalized recordIndex : currentIndex];

        if ( !isnan(currentWidth) ) {
            CGFloat radialOffset = [(NSNumber *)offsetArray[currentIndex] cgFloatValue];

            // draw slice
            CGContextSaveGState(context);

            CGFloat startingAngle  = [self radiansForPieSliceValue:startingWidth];
            CGFloat finishingAngle = [self radiansForPieSliceValue:startingWidth + currentWidth];

            CGFloat xOffset = CPTFloat(0.0);
            CGFloat yOffset = CPTFloat(0.0);
            CGPoint center  = centerPoint;
            if ( radialOffset != 0.0 ) {
                CGFloat medianAngle = CPTFloat(0.5) * (startingAngle + finishingAngle);
                xOffset = cos(medianAngle) * radialOffset;
                yOffset = sin(medianAngle) * radialOffset;

                center = CPTPointMake(centerPoint.x + xOffset, centerPoint.y + yOffset);

                if ( self.alignsPointsToPixels ) {
                    center = CPTAlignPointToUserSpace(context, center);
                }
            }

            CGMutablePathRef slicePath = CGPathCreateMutable();
            [self addSliceToPath:slicePath centerPoint:center startingAngle:startingAngle finishingAngle:finishingAngle];
            CGPathCloseSubpath(slicePath);

            CPTFill *currentFill = [self sliceFillForIndex:currentIndex];
            if ( [currentFill isKindOfClass:fillClass] ) {
                CGContextBeginPath(context);
                CGContextAddPath(context, slicePath);
                [currentFill fillPathInContext:context];
            }
            
            //draw shadow
            if (!self.enableSeperator ||
                (self.enableSeperator && currentIndex%2==0 )) {
                CGContextSaveGState(context);
                CGMutablePathRef shadowPath=CGPathCreateMutable();
                [self addShadowToPath:shadowPath centerPoint:center startingAngle:startingAngle finishingAngle:finishingAngle];
                CGPathCloseSubpath(shadowPath);
                if([self.shadowFill isKindOfClass:fillClass]){
                CGContextBeginPath(context);
                CGContextAddPath(context, shadowPath);
                [self.shadowFill fillPathInContext:context];
                }
                CGPathRelease(shadowPath);
                CGContextRestoreGState(context);
            }
           
            
            
            // Draw the border line around the slice
            if ( borderStyle ) {
                CGContextBeginPath(context);
                CGContextAddPath(context, slicePath);
                [borderStyle strokePathInContext:context];
            }

            // draw overlay for exploded pie charts
            if ( overlay && hasNonZeroOffsets ) {
                CGContextSaveGState(context);

                CGContextAddPath(context, slicePath);
                CGContextClip(context);
                [overlay fillRect:CGRectOffset(bounds, xOffset, yOffset) inContext:context];

                CGContextRestoreGState(context);
            }

            CGPathRelease(slicePath);
            CGContextRestoreGState(context);
            
            

            startingWidth += currentWidth;
            
            
        }
        currentIndex++;
    }
    
    
    CGContextEndTransparencyLayer(context);

    
    // draw overlay all at once if not exploded
    if ( overlay && !hasNonZeroOffsets ) {
        // no shadow for the overlay
        CGContextSetShadowWithColor(context, CGSizeZero, CPTFloat(0.0), NULL);

        CGMutablePathRef fillPath = CGPathCreateMutable();

        CGFloat innerRadius = self.pieInnerRadius;
        if ( innerRadius > 0.0 ) {
            CGPathAddArc(fillPath, NULL, centerPoint.x, centerPoint.y, self.pieRadius, CPTFloat(0.0), CPTFloat(2.0 * M_PI), false);
            CGPathAddArc(fillPath, NULL, centerPoint.x, centerPoint.y, innerRadius, CPTFloat(2.0 * M_PI), CPTFloat(0.0), true);
        }
        else {
            CGPathMoveToPoint(fillPath, NULL, centerPoint.x, centerPoint.y);
            CGPathAddArc(fillPath, NULL, centerPoint.x, centerPoint.y, self.pieRadius, CPTFloat(0.0), CPTFloat(2.0 * M_PI), false);
        }
        CGPathCloseSubpath(fillPath);

        CGContextBeginPath(context);
        CGContextAddPath(context, fillPath);
        [overlay fillPathInContext:context];

        CGPathRelease(fillPath);
    }
    
    
    //draw total number;
    NSString *totalStr=nil;
    
    if (self.totalNumber!=-1) {
        totalStr=[NSString stringWithFormat:@"%ld",self.totalNumber];
    }else{
        CGFloat total=0;
        NSUInteger tail=self.enableSeperator?2:1;
        for(NSUInteger i=0;i<self.cachedDataCount;i+=tail){
            CGFloat currentWidth = CPTFloat([self cachedDoubleForField:CPTPieChartFieldSliceWidth recordIndex:i]);
            total+=currentWidth;
            }
        totalStr=[NSString stringWithFormat:@"%d",(int)total];
    }
    
    float tmp=sqrtf(2)*((float)self.pieInnerRadius)/2;
    CGRect totalRect=CGRectMake(centerPoint.x-tmp, centerPoint.y-tmp, tmp*2, tmp*2);
    //NSLog(@"%@",NSStringFromCGRect(totalRect));
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0,self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
   
    UIFont* font = [self getFontForString:totalStr toFitInRect:totalRect seedFont:[UIFont fontWithName:self.totalTextStyle.fontName size:100]];
    CGSize strSize=[totalStr sizeWithAttributes:@{NSFontAttributeName:font}];
    self.totalTextStyle.fontSize=font.pointSize;
    
    totalRect=CGRectMake(totalRect.origin.x+(totalRect.size.width-strSize.width)/2, totalRect.origin.y+(totalRect.size.height-strSize.height)/2, strSize.width*1.1f, strSize.height);
    [totalStr drawInRect:totalRect withTextStyle:self.totalTextStyle inContext:context];
    /*
    //test usage: stroke totalRect
    CGContextSaveGState(context);
    CGMutablePathRef rectPath=CGPathCreateMutable();
    CGPathAddRect(rectPath, nil, totalRect);
    
    CGContextAddPath(context, rectPath);
    CGContextSetRGBStrokeColor(context, 0.0,0.0,1.0,1.0);
    CGContextStrokePath(context);
    
    CGPathRelease(rectPath);
    CGContextRestoreGState(context);
    */
    CGContextRestoreGState(context);
    
}

-(UIFont*)getFontForString:(NSString*)string
               toFitInRect:(CGRect)rect
                  seedFont:(UIFont*)seedFont{
    UIFont* returnFont = seedFont;
    CGSize stringSize = [string sizeWithFont:returnFont];
    
    while(stringSize.width > rect.size.width || stringSize.height > rect.size.width){
        returnFont = [UIFont systemFontOfSize:returnFont.pointSize -1];
        stringSize = [string sizeWithFont:returnFont];
    }
    
    return returnFont;
}

-(CGFloat)radiansForPieSliceValue:(CGFloat)pieSliceValue
{
    CGFloat angle       = self.startAngle;
    CGFloat endingAngle = self.endAngle;
    CGFloat pieRange;

    switch ( self.sliceDirection ) {
        case CPTPieDirectionClockwise:
            pieRange = isnan(endingAngle) ? CPTFloat(2.0 * M_PI) : CPTFloat(2.0 * M_PI) - ABS(endingAngle - angle);
            angle   -= pieSliceValue * pieRange;
            break;

        case CPTPieDirectionCounterClockwise:
            pieRange = isnan(endingAngle) ? CPTFloat(2.0 * M_PI) : ABS(endingAngle - angle);
            angle   += pieSliceValue * pieRange;
            break;
    }
    return angle;
}

-(void)addShadowToPath:(CGMutablePathRef)shadowPath centerPoint:(CGPoint)center startingAngle:(CGFloat)startingAngle
        finishingAngle:(CGFloat)finishingAngle
{
    bool direction      = (self.sliceDirection == CPTPieDirectionClockwise) ? true : false;
    CGFloat innerRadius = self.pieInnerRadius;
    
    CGPathAddArc(shadowPath, NULL, center.x, center.y, self.pieRadius, startingAngle, finishingAngle, direction);
    CGPathAddArc(shadowPath, NULL, center.x, center.y, innerRadius+(self.pieRadius-innerRadius)*2/5, finishingAngle, startingAngle, !direction);

}

-(void)addSliceToPath:(CGMutablePathRef)slicePath centerPoint:(CGPoint)center startingAngle:(CGFloat)startingAngle finishingAngle:(CGFloat)finishingAngle
{
    bool direction      = (self.sliceDirection == CPTPieDirectionClockwise) ? true : false;
    CGFloat innerRadius = self.pieInnerRadius;

    if ( innerRadius > 0.0 ) {
        CGPathAddArc(slicePath, NULL, center.x, center.y, self.pieRadius, startingAngle, finishingAngle, direction);
        CGPathAddArc(slicePath, NULL, center.x, center.y, innerRadius, finishingAngle, startingAngle, !direction);
    }
    else {
        CGPathMoveToPoint(slicePath, NULL, center.x, center.y);
        CGPathAddArc(slicePath, NULL, center.x, center.y, self.pieRadius, startingAngle, finishingAngle, direction);
    }
}

-(CPTFill *)sliceFillForIndex:(NSUInteger)idx
{
    CPTFill *currentFill = [self cachedValueForKey:CPTPieChartBindingPieSliceFills recordIndex:idx];

    if ( (currentFill == nil) || (currentFill == [CPTPlot nilData]) ) {
        currentFill = [CPTFill fillWithColor:[CPTPieChart defaultPieSliceColorForIndex:idx]];
    }

    return currentFill;
}

-(void)drawSwatchForLegend:(CPTLegend *)legend atIndex:(NSUInteger)idx inRect:(CGRect)rect inContext:(CGContextRef)context
{
    [super drawSwatchForLegend:legend atIndex:idx inRect:rect inContext:context];

    if ( self.drawLegendSwatchDecoration ) {
        CPTFill *theFill           = [self sliceFillForIndex:idx];
        CPTLineStyle *theLineStyle = self.borderLineStyle;

        if ( theFill || theLineStyle ) {
            CGFloat radius = legend.swatchCornerRadius;

            if ( [theFill isKindOfClass:[CPTFill class]] ) {
                CGContextBeginPath(context);
                AddRoundedRectPath(context, CPTAlignIntegralRectToUserSpace(context, rect), radius);
                [theFill fillPathInContext:context];
            }

            if ( theLineStyle ) {
                [theLineStyle setLineStyleInContext:context];
                CGContextBeginPath(context);
                AddRoundedRectPath(context, CPTAlignBorderedRectToUserSpace(context, rect, theLineStyle), radius);
                [theLineStyle strokePathInContext:context];
            }
        }
    }
}

/// @endcond

#pragma mark -
#pragma mark Information

/** @brief Searches the pie slices for one corresponding to the given angle.
 *  @param angle An angle in radians.
 *  @return The index of the pie slice that matches the given angle. Returns @ref NSNotFound if no such pie slice exists.
 **/
-(NSUInteger)pieSliceIndexAtAngle:(CGFloat)angle
{
    // Convert the angle to its pie slice value
    CGFloat pieAngle      = [self normalizedPosition:angle];
    CGFloat startingAngle = [self normalizedPosition:self.startAngle];

    // Iterate through the pie slices and compute their starting and ending angles.
    // If the angle we are searching for lies within those two angles, return the index
    // of that pie slice.
    for ( NSUInteger currentIndex = 0; currentIndex < self.cachedDataCount; currentIndex++ ) {
        CGFloat width = CPTFloat([self cachedDoubleForField:CPTPieChartFieldSliceWidthNormalized recordIndex:currentIndex]);
        if ( isnan(width) ) {
            continue;
        }
        CGFloat endingAngle = startingAngle;

        if ( self.sliceDirection == CPTPieDirectionClockwise ) {
            endingAngle -= width;
        }
        else {
            endingAngle += width;
        }

        if ( [self angle:pieAngle betweenStartAngle:startingAngle endAngle:endingAngle] ) {
            return currentIndex;
        }

        startingAngle = endingAngle;
    }

    // Searched every pie slice but couldn't find one that corresponds to the given angle.
    return NSNotFound;
}

/** @brief Computes the halfway-point between the starting and ending angles of a given pie slice.
 *  @param idx A pie slice index.
 *  @return The angle that is halfway between the slice's starting and ending angles, or @NAN if
 *  an angle matching the given index cannot be found.
 **/
-(CGFloat)medianAngleForPieSliceIndex:(NSUInteger)idx
{
    NSUInteger sampleCount = self.cachedDataCount;

    NSParameterAssert(idx < sampleCount);

    if ( sampleCount == 0 ) {
        return NAN;
    }

    CGFloat startingWidth = CPTFloat(0.0);

    // Iterate through the pie slices until the slice with the given index is found
    for ( NSUInteger currentIndex = 0; currentIndex < sampleCount; currentIndex++ ) {
        CGFloat currentWidth = CPTFloat([self cachedDoubleForField:CPTPieChartFieldSliceWidthNormalized recordIndex:currentIndex]);

        // If the slice index is a match...
        if ( !isnan(currentWidth) && (idx == currentIndex) ) {
            // Compute and return the angle that is halfway between the slice's starting and ending angles
            CGFloat startingAngle  = [self radiansForPieSliceValue:startingWidth];
            CGFloat finishingAngle = [self radiansForPieSliceValue:startingWidth + currentWidth];
            return (startingAngle + finishingAngle) * CPTFloat(0.5);
        }

        startingWidth += currentWidth;
    }

    // Searched every pie slice but couldn't find one that corresponds to the given index
    return NAN;
}

#pragma mark -
#pragma mark Animation

/// @cond

+(BOOL)needsDisplayForKey:(NSString *)aKey
{
    static NSSet *keys = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        keys = [NSSet setWithArray:@[@"pieRadius",
                                     @"pieInnerRadius",
                                     @"startAngle",
                                     @"endAngle",
                                     @"centerAnchor"]];
    });

    if ( [keys containsObject:aKey] ) {
        return YES;
    }
    else {
        return [super needsDisplayForKey:aKey];
    }
}

/// @endcond

#pragma mark -
#pragma mark Fields

/// @cond

-(NSUInteger)numberOfFields
{
    return 1;
}

-(NSArray *)fieldIdentifiers
{
    return @[@(CPTPieChartFieldSliceWidth)];
}

/// @endcond

#pragma mark -
#pragma mark Data Labels

-(void)customizePositionLabelAnnotation:(CPTPlotSpaceAnnotation *)label
    forIndex:(NSUInteger)idx
    left: (BOOL)left
    pos:(NSUInteger)pos
    total: (NSUInteger)total
{
    CPTLayer *contentLayer   = label.contentLayer;
    CPTPlotArea *thePlotArea = self.plotArea;
    
    if ( contentLayer && thePlotArea ) {
        CGRect plotAreaBounds = thePlotArea.bounds;
        CGPoint anchor        = self.centerAnchor;
        CGPoint centerPoint   = CPTPointMake(plotAreaBounds.origin.x + plotAreaBounds.size.width * anchor.x,
                                             plotAreaBounds.origin.y + plotAreaBounds.size.height * anchor.y);
        
        NSDecimal plotPoint[2];
        [self.plotSpace plotPoint:plotPoint numberOfCoordinates:2 forPlotAreaViewPoint:centerPoint];
        NSDecimalNumber *xValue = [[NSDecimalNumber alloc] initWithDecimal:plotPoint[CPTCoordinateX]];
        NSDecimalNumber *yValue = [[NSDecimalNumber alloc] initWithDecimal:plotPoint[CPTCoordinateY]];
        label.anchorPlotPoint = @[xValue, yValue];
        
        CGFloat currentWidth = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthNormalized recordIndex : idx];
        if ( self.hidden || isnan(currentWidth) ) {
            contentLayer.hidden = YES;
        }
        else {
            CGFloat radialOffset = [(NSNumber *)[self cachedValueForKey:CPTPieChartBindingPieSliceRadialOffsets recordIndex:idx] cgFloatValue];
            CGFloat labelRadius  = self.pieRadius + self.labelOffset + radialOffset;
            
            CGFloat startingWidth = CPTFloat(0.0);
            if ( idx > 0 ) {
                startingWidth = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthSum recordIndex : idx - 1];
            }

            
            CGFloat labelAngle = [self radiansForPieSliceValue:startingWidth + currentWidth / CPTFloat(2.0)];
            
            
            CGFloat verticalLength=2*self.pieInnerRadius;
            CGFloat xAxisDisplacement=left ? -labelRadius:labelRadius;
            CGFloat yAxisDisplacement=0.0;
            if(total%2){//odd
                if (total==1) {
                    yAxisDisplacement=10.0f;
                }else
                    yAxisDisplacement=verticalLength/(total-1)*((NSInteger)(total/2)-(NSInteger)pos);
            }else{//even
                if(pos<total/2)
                    yAxisDisplacement=verticalLength/total*(total/2-pos);
                else{
                    yAxisDisplacement=verticalLength/total*((NSInteger)total/2-(NSInteger)pos-1);
                }
            }
            
            
            label.displacement = CPTPointMake(xAxisDisplacement ,  yAxisDisplacement);
            //label.displacement=CPTPointMake(xAxisDisplacement-xAxisDisplacement,yAxisDisplacement);
            
            /*
            NSLog(@"index:%d,anchorPoint:%@,xDisplacement:%f,yDisplacement:%f",idx,label.anchorPlotPoint,label.displacement.x,label.displacement.y);
            NSLog(@"%f,%f",centerPoint.x,centerPoint.y);
             */
            
            if ( self.labelRotationRelativeToRadius ) {
                CGFloat rotation = [self normalizedPosition:self.labelRotation + labelAngle];
                if ( ( rotation > CPTFloat(0.25) ) && ( rotation < CPTFloat(0.75) ) ) {
                    rotation -= CPTFloat(0.5);
                }
                
                label.rotation = rotation * CPTFloat(2.0 * M_PI);
            }
            
            contentLayer.hidden = NO;
        }
    }
    else {
        label.anchorPlotPoint = nil;
        label.displacement    = CGPointZero;
    }

    
    
}


-(void) defaultPositionLabelAnnotation:(CPTPlotSpaceAnnotation *)label forIndex:(NSUInteger)idx
{
    CPTLayer *contentLayer   = label.contentLayer;
    CPTPlotArea *thePlotArea = self.plotArea;
    
    if ( contentLayer && thePlotArea ) {
        CGRect plotAreaBounds = thePlotArea.bounds;
        CGPoint anchor        = self.centerAnchor;
        CGPoint centerPoint   = CPTPointMake(plotAreaBounds.origin.x + plotAreaBounds.size.width * anchor.x,
                                             plotAreaBounds.origin.y + plotAreaBounds.size.height * anchor.y);
        
        NSDecimal plotPoint[2];
        [self.plotSpace plotPoint:plotPoint numberOfCoordinates:2 forPlotAreaViewPoint:centerPoint];
        NSDecimalNumber *xValue = [[NSDecimalNumber alloc] initWithDecimal:plotPoint[CPTCoordinateX]];
        NSDecimalNumber *yValue = [[NSDecimalNumber alloc] initWithDecimal:plotPoint[CPTCoordinateY]];
        label.anchorPlotPoint = @[xValue, yValue];
        
        CGFloat currentWidth = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthNormalized recordIndex : idx];
        if ( self.hidden || isnan(currentWidth) ) {
            contentLayer.hidden = YES;
        }
        else {
            CGFloat radialOffset = [(NSNumber *)[self cachedValueForKey:CPTPieChartBindingPieSliceRadialOffsets recordIndex:idx] cgFloatValue];
            CGFloat labelRadius  = self.pieRadius + self.labelOffset + radialOffset;
            
            CGFloat startingWidth = CPTFloat(0.0);
            if ( idx > 0 ) {
                startingWidth = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthSum recordIndex : idx - 1];
            }
            CGFloat labelAngle = [self radiansForPieSliceValue:startingWidth + currentWidth / CPTFloat(2.0)];
            
            
            label.displacement = CPTPointMake( labelRadius * cos(labelAngle), labelRadius * sin(labelAngle) );
            
            /*
            label.displacement=CPTPointMake(cos(labelAngle)<0 ? -2*labelRadius:labelRadius, labelRadius * sin(labelAngle));
            
            NSLog(@"\n\n\nlabelAngle:%f",labelAngle);
            
            NSLog(@"lableDisplacement:(%f,%f)\n\n\n",label.displacement.x,label.displacement.y);
            */
            if ( self.labelRotationRelativeToRadius ) {
                CGFloat rotation = [self normalizedPosition:self.labelRotation + labelAngle];
                if ( ( rotation > CPTFloat(0.25) ) && ( rotation < CPTFloat(0.75) ) ) {
                    rotation -= CPTFloat(0.5);
                }
                
                label.rotation = rotation * CPTFloat(2.0 * M_PI);
            }
            
            contentLayer.hidden = NO;
        }
    }
    else {
        label.anchorPlotPoint = nil;
        label.displacement    = CGPointZero;
    }

}

/// @cond
-(void)positionLabelAnnotation:(CPTPlotSpaceAnnotation *)label forIndex:(NSUInteger)idx
{
    if (self.customizeLabelPosition==NO) {
        [self defaultPositionLabelAnnotation:label forIndex:idx];
    }
    else{
        NSUInteger tail=0;
        if (self.enableSeperator==NO) {
            tail=1;
        }else
            tail=2;
        
       if(idx < self.cachedDataCount-tail){
            return;
        }
        
        if (idx == self.cachedDataCount-tail) {//all annotations are added by now.
            [self.leftLabels removeAllObjects];
            [self.rightLabels removeAllObjects];
            for (NSUInteger i=0; i<=idx; i=i+tail) {
                CGFloat medianAngle=[self medianAngleForPieSliceIndex:i];
                if (medianAngle>=-M_PI_2 && medianAngle<=M_PI_2) {
                    [self.rightLabels addObject:[NSNumber numberWithUnsignedInteger:i]];
                }
                else{
                    [self.leftLabels addObject:[NSNumber numberWithUnsignedInteger:i]];
                }
            }
            self.leftLabels=[[[self.leftLabels reverseObjectEnumerator] allObjects]mutableCopy];
            NSUInteger leftCount=[self.leftLabels count];
            NSUInteger rightCount=[self.rightLabels count];
            NSUInteger annoIdx=0;
            for (NSUInteger i=0; i<self.cachedDataCount; i=i+tail){
                if(self.enableSeperator==YES)
                    annoIdx=i/2;
                else
                    annoIdx=i;
                NSUInteger pos;
                if ((pos=[self.leftLabels indexOfObject:[NSNumber numberWithUnsignedInteger:i]])
                    !=NSNotFound
                    ) {
                    [self customizePositionLabelAnnotation:self.annotations[annoIdx]
                                                  forIndex:i
                                                      left:YES
                                                       pos: pos                  total:leftCount
                                                  ];
                }
                else if ((pos=[self.rightLabels indexOfObject:[NSNumber numberWithUnsignedInteger:i]])!=NSNotFound) {
                    [self customizePositionLabelAnnotation:self.annotations[annoIdx]
                                                  forIndex:i
                                                      left:NO
                                                       pos: pos                  total:rightCount
                     ];
                }

            }
            [self setNeedsDisplay];
            
            }
        
        else
            return;
    /*
    NSLog(@"%@",self.annotations);
    NSLog(@"%d",self.cachedDataCount);
     */
    }
}

/// @endcond

#pragma mark -
#pragma mark Legends

/// @cond

/** @internal
 *  @brief The number of legend entries provided by this plot.
 *  @return The number of legend entries.
 **/
-(NSUInteger)numberOfLegendEntries
{
    [self reloadDataIfNeeded];
    return self.cachedDataCount;
}

/** @internal
 *  @brief The title text of a legend entry.
 *  @param idx The index of the desired title.
 *  @return The title of the legend entry at the requested index.
 **/
-(NSString *)titleForLegendEntryAtIndex:(NSUInteger)idx
{
    NSString *legendTitle = nil;

    id<CPTPieChartDataSource> theDataSource = (id<CPTPieChartDataSource>)self.dataSource;

    if ( [theDataSource respondsToSelector:@selector(legendTitleForPieChart:recordIndex:)] ) {
        legendTitle = [theDataSource legendTitleForPieChart:self recordIndex:idx];
    }
    else {
        legendTitle = [super titleForLegendEntryAtIndex:idx];
    }

    return legendTitle;
}

/** @internal
 *  @brief The styled title text of a legend entry.
 *  @param idx The index of the desired title.
 *  @return The styled title of the legend entry at the requested index.
 **/
-(NSAttributedString *)attributedTitleForLegendEntryAtIndex:(NSUInteger)idx
{
    NSAttributedString *legendTitle = nil;

    id<CPTPieChartDataSource> theDataSource = (id<CPTPieChartDataSource>)self.dataSource;

    if ( [theDataSource respondsToSelector:@selector(attributedLegendTitleForPieChart:recordIndex:)] ) {
        legendTitle = [theDataSource attributedLegendTitleForPieChart:self recordIndex:idx];
    }
    else {
        legendTitle = [super attributedTitleForLegendEntryAtIndex:idx];
    }

    return legendTitle;
}

/// @endcond

#pragma mark -
#pragma mark Responder Chain and User interaction

/// @cond

-(CGFloat)normalizedPosition:(CGFloat)rawPosition
{
    CGFloat result = rawPosition;

    result /= (CGFloat)(2.0 * M_PI);
    result  = fmod( result, CPTFloat(1.0) );
    if ( result < CPTFloat(0.0) ) {
        result += CPTFloat(1.0);
    }

    return result;
}

-(BOOL)angle:(CGFloat)touchedAngle betweenStartAngle:(CGFloat)startingAngle endAngle:(CGFloat)endingAngle
{
    switch ( self.sliceDirection ) {
        case CPTPieDirectionClockwise:
            if ( (touchedAngle <= startingAngle) && (touchedAngle >= endingAngle) ) {
                return YES;
            }
            else if ( ( endingAngle < CPTFloat(0.0) ) && (touchedAngle - CPTFloat(1.0) >= endingAngle) ) {
                return YES;
            }
            break;

        case CPTPieDirectionCounterClockwise:
            if ( (touchedAngle >= startingAngle) && (touchedAngle <= endingAngle) ) {
                return YES;
            }
            else if ( ( endingAngle > CPTFloat(1.0) ) && (touchedAngle + CPTFloat(1.0) <= endingAngle) ) {
                return YES;
            }
            break;
    }
    return NO;
}

/// @endcond

/// @name User Interaction
/// @{

/**
 *  @brief Informs the receiver that the user has
 *  @if MacOnly pressed the mouse button. @endif
 *  @if iOSOnly started touching the screen. @endif
 *
 *
 *  If this plot has a delegate that responds to the
 *  @link CPTPieChartDelegate::pieChart:sliceTouchDownAtRecordIndex: -pieChart:sliceTouchDownAtRecordIndex: @endlink and/or
 *  @link CPTPieChartDelegate::pieChart:sliceTouchDownAtRecordIndex:withEvent: -pieChart:sliceTouchDownAtRecordIndex:withEvent: @endlink
 *  methods, the @par{interactionPoint} is compared with each slice in index order.
 *  The delegate method will be called and this method returns @YES for the first
 *  index where the @par{interactionPoint} is inside a pie slice.
 *  This method returns @NO if the @par{interactionPoint} is outside all of the slices.
 *
 *  @param event The OS event.
 *  @param interactionPoint The coordinates of the interaction.
 *  @return Whether the event was handled or not.
 **/
-(BOOL)pointingDeviceDownEvent:(CPTNativeEvent *)event atPoint:(CGPoint)interactionPoint
{
    CPTGraph *theGraph       = self.graph;
    CPTPlotArea *thePlotArea = self.plotArea;

    if ( !theGraph || !thePlotArea || self.hidden ) {
        return NO;
    }

    id<CPTPieChartDelegate> theDelegate = self.delegate;
    if ( [theDelegate respondsToSelector:@selector(pieChart:sliceTouchDownAtRecordIndex:)] ||
         [theDelegate respondsToSelector:@selector(pieChart:sliceTouchDownAtRecordIndex:withEvent:)] ||
         [theDelegate respondsToSelector:@selector(pieChart:sliceWasSelectedAtRecordIndex:)] ||
         [theDelegate respondsToSelector:@selector(pieChart:sliceWasSelectedAtRecordIndex:withEvent:)] ) {
        CGPoint plotAreaPoint = [theGraph convertPoint:interactionPoint toLayer:thePlotArea];

        NSUInteger idx = [self dataIndexFromInteractionPoint:plotAreaPoint];
        self.pointingDeviceDownIndex = idx;

        if ( idx != NSNotFound ) {
            BOOL handled = NO;

            if ( [theDelegate respondsToSelector:@selector(pieChart:sliceTouchDownAtRecordIndex:)] ) {
                handled = YES;
                [theDelegate pieChart:self sliceTouchDownAtRecordIndex:idx];
            }

            if ( [theDelegate respondsToSelector:@selector(pieChart:sliceTouchDownAtRecordIndex:withEvent:)] ) {
                handled = YES;
                [theDelegate pieChart:self sliceTouchDownAtRecordIndex:idx withEvent:event];
            }

            if ( handled ) {
                return YES;
            }
        }
    }

    return [super pointingDeviceDownEvent:event atPoint:interactionPoint];
}

/**
 *  @brief Informs the receiver that the user has
 *  @if MacOnly released the mouse button. @endif
 *  @if iOSOnly ended touching the screen. @endif
 *
 *
 *  If this plot has a delegate that responds to the
 *  @link CPTPieChartDelegate::pieChart:sliceTouchUpAtRecordIndex: -pieChart:sliceTouchUpAtRecordIndex: @endlink and/or
 *  @link CPTPieChartDelegate::pieChart:sliceTouchUpAtRecordIndex:withEvent: -pieChart:sliceTouchUpAtRecordIndex:withEvent: @endlink
 *  methods, the @par{interactionPoint} is compared with each slice in index order.
 *  The delegate method will be called and this method returns @YES for the first
 *  index where the @par{interactionPoint} is inside a pie slice.
 *  This method returns @NO if the @par{interactionPoint} is outside all of the slices.
 *
 *  If the pie slice being released is the same as the one that was pressed (see
 *  @link CPTPieChart::pointingDeviceDownEvent:atPoint: -pointingDeviceDownEvent:atPoint: @endlink), if the delegate responds to the
 *  @link CPTPieChartDelegate::pieChart:sliceWasSelectedAtRecordIndex: -pieChart:sliceWasSelectedAtRecordIndex: @endlink and/or
 *  @link CPTPieChartDelegate::pieChart:sliceWasSelectedAtRecordIndex:withEvent: -pieChart:sliceWasSelectedAtRecordIndex:withEvent: @endlink
 *  methods, these will be called.
 *
 *  @param event The OS event.
 *  @param interactionPoint The coordinates of the interaction.
 *  @return Whether the event was handled or not.
 **/
-(BOOL)pointingDeviceUpEvent:(CPTNativeEvent *)event atPoint:(CGPoint)interactionPoint
{
    NSUInteger selectedDownIndex = self.pointingDeviceDownIndex;

    self.pointingDeviceDownIndex = NSNotFound;

    CPTGraph *theGraph       = self.graph;
    CPTPlotArea *thePlotArea = self.plotArea;

    if ( !theGraph || !thePlotArea || self.hidden ) {
        return NO;
    }

    id<CPTPieChartDelegate> theDelegate = self.delegate;
    if ( [theDelegate respondsToSelector:@selector(pieChart:sliceTouchUpAtRecordIndex:)] ||
         [theDelegate respondsToSelector:@selector(pieChart:sliceTouchUpAtRecordIndex:withEvent:)] ||
         [theDelegate respondsToSelector:@selector(pieChart:sliceWasSelectedAtRecordIndex:)] ||
         [theDelegate respondsToSelector:@selector(pieChart:sliceWasSelectedAtRecordIndex:withEvent:)] ) {
        CGPoint plotAreaPoint = [theGraph convertPoint:interactionPoint toLayer:thePlotArea];

        NSUInteger idx = [self dataIndexFromInteractionPoint:plotAreaPoint];
        if ( idx != NSNotFound ) {
            BOOL handled = NO;

            if ( [theDelegate respondsToSelector:@selector(pieChart:sliceTouchUpAtRecordIndex:)] ) {
                handled = YES;
                [theDelegate pieChart:self sliceTouchUpAtRecordIndex:idx];
            }
            if ( [theDelegate respondsToSelector:@selector(pieChart:sliceTouchUpAtRecordIndex:withEvent:)] ) {
                handled = YES;
                [theDelegate pieChart:self sliceTouchUpAtRecordIndex:idx withEvent:event];
            }

            if ( idx == selectedDownIndex ) {
                if ( [theDelegate respondsToSelector:@selector(pieChart:sliceWasSelectedAtRecordIndex:)] ) {
                    handled = YES;
                    [theDelegate pieChart:self sliceWasSelectedAtRecordIndex:idx];
                }

                if ( [theDelegate respondsToSelector:@selector(pieChart:sliceWasSelectedAtRecordIndex:withEvent:)] ) {
                    handled = YES;
                    [theDelegate pieChart:self sliceWasSelectedAtRecordIndex:idx withEvent:event];
                }
            }

            if ( handled ) {
                return YES;
            }
        }
    }

    return [super pointingDeviceUpEvent:event atPoint:interactionPoint];
}

/// @}

/// @cond

-(NSUInteger)dataIndexFromInteractionPoint:(CGPoint)point
{
    CPTGraph *theGraph       = self.graph;
    CPTPlotArea *thePlotArea = self.plotArea;

    // Inform delegate if a slice was hit
    if ( !theGraph || !thePlotArea ) {
        return NSNotFound;
    }

    NSUInteger sampleCount = self.cachedDataCount;
    if ( sampleCount == 0 ) {
        return NSNotFound;
    }

    CGRect plotAreaBounds = thePlotArea.bounds;
    CGPoint anchor        = self.centerAnchor;
    CGPoint centerPoint   = CPTPointMake(plotAreaBounds.origin.x + plotAreaBounds.size.width * anchor.x,
                                         plotAreaBounds.origin.y + plotAreaBounds.size.height * anchor.y);
    centerPoint = [self convertPoint:centerPoint fromLayer:thePlotArea];

    CGFloat chartRadius             = self.pieRadius;
    CGFloat chartRadiusSquared      = chartRadius * chartRadius;
    CGFloat chartInnerRadius        = self.pieInnerRadius;
    CGFloat chartInnerRadiusSquared = chartInnerRadius * chartInnerRadius;
    CGFloat dx                      = point.x - centerPoint.x;
    CGFloat dy                      = point.y - centerPoint.y;
    CGFloat distanceSquared         = dx * dx + dy * dy;

    CGFloat theStartAngle = self.startAngle;
    CGFloat theEndAngle   = self.endAngle;
    CGFloat widthFactor;

    CGFloat touchedAngle  = [self normalizedPosition:atan2(dy, dx)];
    CGFloat startingAngle = [self normalizedPosition:theStartAngle];

    switch ( self.sliceDirection ) {
        case CPTPieDirectionClockwise:
            if ( isnan(theEndAngle) || ( 2.0 * M_PI == ABS(theEndAngle - theStartAngle) ) ) {
                widthFactor = CPTFloat(1.0);
            }
            else {
                widthFactor = (CGFloat)(2.0 * M_PI) / ( (CGFloat)(2.0 * M_PI) - ABS(theEndAngle - theStartAngle) );
            }

            for ( NSUInteger currentIndex = 0; currentIndex < sampleCount; currentIndex++ ) {
                // calculate angles for this slice
                CGFloat width = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthNormalized recordIndex : currentIndex];
                if ( isnan(width) ) {
                    continue;
                }

                width /= widthFactor;

                CGFloat endingAngle = startingAngle - width;

                // offset the center point of the slice if needed
                CGFloat offsetTouchedAngle    = touchedAngle;
                CGFloat offsetDistanceSquared = distanceSquared;
                CGFloat radialOffset          = [(NSNumber *)[self cachedValueForKey:CPTPieChartBindingPieSliceRadialOffsets recordIndex:currentIndex] cgFloatValue];
                if ( radialOffset != 0.0 ) {
                    CGPoint offsetCenter;
                    CGFloat medianAngle = CPTFloat(M_PI) * (startingAngle + endingAngle);
                    offsetCenter = CPTPointMake(centerPoint.x + cos(medianAngle) * radialOffset,
                                                centerPoint.y + sin(medianAngle) * radialOffset);

                    dx = point.x - offsetCenter.x;
                    dy = point.y - offsetCenter.y;

                    offsetTouchedAngle    = [self normalizedPosition:atan2(dy, dx)];
                    offsetDistanceSquared = dx * dx + dy * dy;
                }

                // check angles
                BOOL angleInSlice = NO;
                if ( [self angle:touchedAngle betweenStartAngle:startingAngle endAngle:endingAngle] ) {
                    if ( [self angle:offsetTouchedAngle betweenStartAngle:startingAngle endAngle:endingAngle] ) {
                        angleInSlice = YES;
                    }
                    else {
                        return NSNotFound;
                    }
                }

                // check distance
                if ( angleInSlice && (offsetDistanceSquared >= chartInnerRadiusSquared) && (offsetDistanceSquared <= chartRadiusSquared) ) {
                    return currentIndex;
                }

                // save angle for the next slice
                startingAngle = endingAngle;
            }
            break;

        case CPTPieDirectionCounterClockwise:
            if ( isnan(theEndAngle) || (theStartAngle == theEndAngle) ) {
                widthFactor = CPTFloat(1.0);
            }
            else {
                widthFactor = (CGFloat)(2.0 * M_PI) / ABS(theEndAngle - theStartAngle);
            }

            for ( NSUInteger currentIndex = 0; currentIndex < sampleCount; currentIndex++ ) {
                // calculate angles for this slice
                CGFloat width = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthNormalized recordIndex : currentIndex];
                if ( isnan(width) ) {
                    continue;
                }
                width /= widthFactor;

                CGFloat endingAngle = startingAngle + width;

                // offset the center point of the slice if needed
                CGFloat offsetTouchedAngle    = touchedAngle;
                CGFloat offsetDistanceSquared = distanceSquared;
                CGFloat radialOffset          = [(NSNumber *)[self cachedValueForKey:CPTPieChartBindingPieSliceRadialOffsets recordIndex:currentIndex] cgFloatValue];
                if ( radialOffset != 0.0 ) {
                    CGPoint offsetCenter;
                    CGFloat medianAngle = CPTFloat(M_PI) * (startingAngle + endingAngle);
                    offsetCenter = CPTPointMake(centerPoint.x + cos(medianAngle) * radialOffset,
                                                centerPoint.y + sin(medianAngle) * radialOffset);

                    dx = point.x - offsetCenter.x;
                    dy = point.y - offsetCenter.y;

                    offsetTouchedAngle    = [self normalizedPosition:atan2(dy, dx)];
                    offsetDistanceSquared = dx * dx + dy * dy;
                }

                // check angles
                BOOL angleInSlice = NO;
                if ( [self angle:touchedAngle betweenStartAngle:startingAngle endAngle:endingAngle] ) {
                    if ( [self angle:offsetTouchedAngle betweenStartAngle:startingAngle endAngle:endingAngle] ) {
                        angleInSlice = YES;
                    }
                    else {
                        return NSNotFound;
                    }
                }

                // check distance
                if ( angleInSlice && (offsetDistanceSquared >= chartInnerRadiusSquared) && (offsetDistanceSquared <= chartRadiusSquared) ) {
                    return currentIndex;
                }

                // save angle for the next slice
                startingAngle = endingAngle;
            }
            break;
    }

    return NSNotFound;
}

/// @endcond

#pragma mark -
#pragma mark Accessors

/// @cond

-(NSArray *)sliceWidths
{
    return [[self cachedNumbersForField:CPTPieChartFieldSliceWidth] sampleArray];
}

-(void)setSliceWidths:(NSArray *)newSliceWidths
{
    [self cacheNumbers:newSliceWidths forField:CPTPieChartFieldSliceWidth];
    [self updateNormalizedData];
}

-(NSArray *)sliceFills
{
    return [self cachedArrayForKey:CPTPieChartBindingPieSliceFills];
}

-(void)setSliceFills:(NSArray *)newSliceFills
{
    [self cacheArray:newSliceFills forKey:CPTPieChartBindingPieSliceFills];
    [self setNeedsDisplay];
}

-(NSArray *)sliceRadialOffsets
{
    return [self cachedArrayForKey:CPTPieChartBindingPieSliceRadialOffsets];
}

-(void)setSliceRadialOffsets:(NSArray *)newSliceRadialOffsets
{
    [self cacheArray:newSliceRadialOffsets forKey:CPTPieChartBindingPieSliceRadialOffsets];
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

-(void)setPieRadius:(CGFloat)newPieRadius
{
    if ( pieRadius != newPieRadius ) {
        pieRadius = ABS(newPieRadius);
        [self setNeedsDisplay];
        [self repositionAllLabelAnnotations];
    }
}

-(void)setPieInnerRadius:(CGFloat)newPieRadius
{
    if ( pieInnerRadius != newPieRadius ) {
        pieInnerRadius = ABS(newPieRadius);
        [self setNeedsDisplay];
    }
}

-(void)setStartAngle:(CGFloat)newAngle
{
    if ( newAngle != startAngle ) {
        startAngle = newAngle;
        [self setNeedsDisplay];
        [self repositionAllLabelAnnotations];
    }
}

-(void)setEndAngle:(CGFloat)newAngle
{
    if ( newAngle != endAngle ) {
        endAngle = newAngle;
        [self setNeedsDisplay];
        [self repositionAllLabelAnnotations];
    }
}

-(void)setSliceDirection:(CPTPieDirection)newDirection
{
    if ( newDirection != sliceDirection ) {
        sliceDirection = newDirection;
        [self setNeedsDisplay];
        [self repositionAllLabelAnnotations];
    }
}

-(void)setBorderLineStyle:(CPTLineStyle *)newStyle
{
    if ( borderLineStyle != newStyle ) {
        borderLineStyle = [newStyle copy];
        [self setNeedsDisplay];
        [[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
    }
}

-(void)setCenterAnchor:(CGPoint)newCenterAnchor
{
    if ( !CGPointEqualToPoint(centerAnchor, newCenterAnchor) ) {
        centerAnchor = newCenterAnchor;
        [self setNeedsDisplay];
        [self repositionAllLabelAnnotations];
    }
}

-(void)setLabelRotationRelativeToRadius:(BOOL)newLabelRotationRelativeToRadius
{
    if ( labelRotationRelativeToRadius != newLabelRotationRelativeToRadius ) {
        labelRotationRelativeToRadius = newLabelRotationRelativeToRadius;
        [self repositionAllLabelAnnotations];
    }
}

-(void)setLabelRotation:(CGFloat)newRotation
{
    if ( newRotation != self.labelRotation ) {
        [super setLabelRotation:newRotation];
        if ( self.labelRotationRelativeToRadius ) {
            [self repositionAllLabelAnnotations];
        }
    }
}

/// @endcond

@end
