//
//  MOSTextFieldCell.m
//  Mach-O-scope
//
//  Created by Scott Morrison on 10-09-04.
//  Copyright 2010 Indev Software, Inc. All rights reserved.
//

#import "MOSTextFieldCell.h"


@implementation MOSTextFieldCell
@synthesize highlightColor;

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	if (highlightColor)
	{
		NSRect newFrame = NSInsetRect(cellFrame, -2, 0);
		[highlightColor setFill];
		NSRectFill(newFrame);
		
	}
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}


@end
