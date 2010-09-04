//
//  MOSTextFieldCell.h
//  Mach-O-scope
//
//  Created by Scott Morrison on 10-09-04.
//  Copyright 2010 Indev Software, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSTextFieldCell :  NSTextFieldCell {
	NSColor * highlightColor;
	
}
@property (retain,nonatomic) NSColor* highlightColor;
@end
