//
//  ClassMethodWindowController.h
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

#import <Cocoa/Cocoa.h>
#import "MOSDatabase.h"

@interface ClassMethodWindowController : NSWindowController <NSTableViewDelegate> {
	MOSDatabase * _database;
	NSString * pathToDatabase;
	NSString * methodFilter;
	NSString * symbolFilter;
	NSInteger searchContext;
	NSInteger showMisses;
	NSInteger progressAmount;
	NSInteger progressTotal;
	IBOutlet NSWindow * progressSheet;
	BOOL cancelImport;
	NSMutableArray * childWindows;
	

}
@property (retain,readonly) EGODatabase * database;
@property (copy) NSString * pathToDatabase;
@property (copy) NSString * methodFilter;
@property (copy) NSString * symbolFilter;
@property (assign) NSInteger searchContext;
@property (assign) NSInteger showMisses;
@property (assign) NSInteger progressAmount;
@property (assign) NSInteger progressTotal;

-(IBAction)cancelImport:(id)sender;
-(IBAction)openDocument:(id)sender;
-(IBAction)disassembleMachO:(id)sender;
-(NSArray*)classes;
@end
