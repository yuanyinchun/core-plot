//
//  CPTZoom.m
//  CorePlot-CocoaTouch
//
//  Created by yuanyinchun on 1/3/15.
//
//

#import "CPTZoom.h"
#import "CPTGraph.h"

@implementation CPTZoom

#pragma mark -
#pragma mark Responder Chain and User interaction
-(BOOL)pointingDeviceDownEvent:(CPTNativeEvent *)event atPoint:(CGPoint)interactionPoint
{
    
    CPTGraph *theGraph = self.graph;
    
    if ( !theGraph || self.hidden ) {
        return NO;
    }
    
    id<CPTZoomDelegate> theDelegate = self.delegate;
    if ([theDelegate respondsToSelector:@selector(zoomTouchedDown:)]) {
        CGPoint point = [theGraph convertPoint:interactionPoint toLayer:self];
        if ( CGRectContainsPoint(self.bounds, point) ) {
            [theDelegate zoomTouchedDown:self];
            return YES;
        }
    }
    return [super pointingDeviceDownEvent:event atPoint:interactionPoint];
}

-(BOOL)pointingDeviceUpEvent:(UIEvent *)event atPoint:(CGPoint)interactionPoint
{
    CPTGraph *theGraph = self.graph;
    
    if ( !theGraph || self.hidden ) {
        return NO;
    }
    id<CPTZoomDelegate> theDelegate = self.delegate;
    
    if ([theDelegate respondsToSelector:@selector(zoomTouchedUp:)] ||
        [theDelegate respondsToSelector:@selector(zoomDidSelected:)]
        ) {
        CGPoint point = [theGraph convertPoint:interactionPoint toLayer:self];
        if ( CGRectContainsPoint(self.bounds, point) ) {
            BOOL handled=NO;
            if ([theDelegate respondsToSelector:@selector(zoomTouchedUp:)]) {
                handled=YES;
                [theDelegate zoomTouchedUp:self];
            }
            if ([theDelegate respondsToSelector:@selector(zoomDidSelected:)]) {
                handled=YES;
                [theDelegate zoomDidSelected:self];
            }
            if (handled) {
                return YES;
            }
        }
    }
    return [super pointingDeviceDownEvent:event atPoint:interactionPoint];
}


@end
