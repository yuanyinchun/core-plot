//
//  CPTZoom.h
//  CorePlot-CocoaTouch
//
//  Created by yuanyinchun on 1/3/15.
//
//

#import "CPTTextLayer.h"

@class CPTTextLayer;

@protocol CPTZoomDelegate <NSObject>

@optional

-(void)zoomTouchedDown:(CPTTextLayer *)textLayer;
-(void)zoomTouchedUp:(CPTTextLayer *)textLayer;
-(void)zoomDidSelected:(CPTTextLayer *)textLayer;

@end

@interface CPTZoom : CPTTextLayer



@end
