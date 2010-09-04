//
//  MOSsymbolsTextFieldCell.m
//  Mach-O-scope
//
//  Created by Scott Morrison on 10-05-08.
//  Copyright 2010 Indev Software, Inc. All rights reserved.
//

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     1. Redistributions of source code must retain the above copyright
//          notice, this list of conditions and the following disclaimer.
//     2. Redistributions in binary form must reproduce the above copyright
//          notice, this list of conditions and the following disclaimer in the
//          documentation and/or other materials provided with the distribution.
//     3. Neither the name of Indev Software nor the
//          names of its contributors may be used to endorse or promote products
//          derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY INDEV SOFTWARE ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL INDEV SOFTWARE BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MOSsymbolsTextFieldCell.h"

#import "EGODatabaseResult.h"
#import "EGODatabaseRow.h"
#import "MOSDatabase.h"

#import "ClassMethodWindowController.h"

@implementation MOSsymbolsTextFieldCell
-(void)findMethod:(id)sender{
	
	ClassMethodWindowController * windowController = (ClassMethodWindowController*)[[[(MOSsymbolsTextFieldCell*)[[sender menu] delegate] controlView] window] delegate];
	if ([windowController respondsToSelector:@selector(openDisassemblyWindowForMethodID:)]){
		[windowController openDisassemblyWindowForMethodID:[sender tag]];
	}
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	return YES;	
}
- (void)menuNeedsUpdate:(NSMenu *)menu{
	[menu setAutoenablesItems:YES];
	MOSDatabase * db = [(ClassMethodWindowController*)[[[self controlView] window] delegate] database];
	[menu removeAllItems];
	EGODatabaseResult * dbResult = [db executeQueryWithParameters:@"select rawInfo,methodID from Methods where methodName = ?",[self stringValue],nil];
	if ([dbResult count]){
		for (EGODatabaseRow * row in dbResult){
			NSMenuItem * item = [menu addItemWithTitle:[row stringForColumn:@"rawInfo"] action:@selector(findMethod:) keyEquivalent:@""];
			[item setTarget:self];
			[item setTag:[row intForColumn:@"methodID"]];
			[item setEnabled:YES];
		}
	}
	else{
		[menu addItemWithTitle:@"No methods matching symbol" action:nil keyEquivalent:@""];
	}
	NSLog(@"	menuNeedsUpdate %@",menu);
	
}
@end
