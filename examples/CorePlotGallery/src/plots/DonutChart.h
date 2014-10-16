#import "PlotItem.h"

@interface DonutChart : PlotItem<CPTPlotSpaceDelegate, CPTPlotDataSource, CPTAnimationDelegate>
{
    @private
    NSArray *plotData;
}
@property(nonatomic,strong) NSArray *myPlotData;
@property(nonatomic,strong) NSDictionary *myColor;
@end
