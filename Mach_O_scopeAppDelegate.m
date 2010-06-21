//
//  Mach_O_scopeAppDelegate.m
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

#import "Mach_O_scopeAppDelegate.h"
@implementation Mach_O_scopeAppDelegate
@synthesize saveArchitecture;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	windowControllers = [[NSMutableArray alloc] init];
	self.saveArchitecture =@"i386";
}

-(IBAction)disassembleWithOtx:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	NSArray * pathsToSearch = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory,0, YES);
	
	if ([pathsToSearch count]){	
		[openPanel setDirectoryURL:[NSURL fileURLWithPath: [pathsToSearch objectAtIndex:0] isDirectory:NO]];
	}
	
	[openPanel beginWithCompletionHandler:^(NSInteger result){
		if(result ==NSFileHandlingPanelOKButton){
			
			NSString * otxPath =  [[[openPanel URLs] objectAtIndex:0] path];
			
			[self performSelector:@selector(setSaveDatabaseForOtxFile:) withObject:otxPath afterDelay:0 ];
			
			
		}
	} ];	
}
-(IBAction)disassembleMachO:(id)sender{
	
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	NSArray * pathsToSearch = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory,0, YES);
	
	if ([pathsToSearch count]){	
		[openPanel setDirectoryURL:[NSURL fileURLWithPath: [pathsToSearch objectAtIndex:0] isDirectory:NO]];
	}
	
	[openPanel beginWithCompletionHandler:^(NSInteger result){
		if(result ==NSFileHandlingPanelOKButton){
						
			NSString * bundlePath =  [[[openPanel URLs] objectAtIndex:0] path];
			
			[self performSelector:@selector(setSaveDatabaseForInputFile:) withObject:bundlePath afterDelay:0 ];
			

			}
	} ];
}

-(IBAction)setArchitecture:(id)sender{
	self.saveArchitecture = [sender titleOfSelectedItem];
}


-(void)setSaveDatabaseForInputFile:(id)bundlePath   
{
	if (!bundlePath) return;
	
	NSSavePanel	* savePanel = [NSSavePanel savePanel];
	[savePanel setPrompt:@"Save"];
	[savePanel setNameFieldStringValue:[[bundlePath lastPathComponent] stringByAppendingString:@".machoData"]];
	[savePanel setAccessoryView:saveAccessoryView];
	[savePanel beginWithCompletionHandler:^(NSInteger result){
		if (result == NSFileHandlingPanelOKButton){
			NSString * dataFilePath =  [[savePanel URL]  path];
			
			ClassMethodWindowController* initialController = [[ClassMethodWindowController alloc] initWithDatabasePath:dataFilePath];
			[windowControllers addObject: initialController];
			
			[initialController showWindow:nil];
			[initialController performSelector:@selector(importBundleAtPath:) withObject:bundlePath afterDelay:0];
			[initialController release];
		}
	}];
	
}

-(void)setSaveDatabaseForOtxFile:(id)otxPath   
{
	if (!otxPath) return;
	
	NSSavePanel	* savePanel = [NSSavePanel savePanel];
	[savePanel setPrompt:@"Save"];
	[savePanel setNameFieldStringValue:[[otxPath lastPathComponent] stringByAppendingString:@".machoData"]];
	[savePanel setAccessoryView:saveAccessoryView];
	[savePanel beginWithCompletionHandler:^(NSInteger result){
		if (result == NSFileHandlingPanelOKButton){
			NSString * dataFilePath =  [[savePanel URL]  path];
			
			ClassMethodWindowController* initialController = [[ClassMethodWindowController alloc] initWithDatabasePath:dataFilePath];
			[windowControllers addObject: initialController];
			
			[initialController showWindow:nil];
			[initialController performSelector:@selector(importOtxAtPath:) withObject:otxPath afterDelay:0];
			[initialController release];
		}
	}];
	
}

-(IBAction)openDocument:(id)sender{
	
	
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	
	[openPanel beginWithCompletionHandler:^(NSInteger result){
		if(result ==NSFileHandlingPanelOKButton){
			NSString * resultPath =  [[[openPanel URLs] objectAtIndex:0] path];
			
			ClassMethodWindowController* initialController = [[ClassMethodWindowController alloc] initWithDatabasePath:resultPath];
			[windowControllers addObject: initialController];
			[initialController showWindow:nil];
			[initialController release];
			
			
		}
	} ];
	
	
}


-(IBAction)saveSymbols:(id)sender
{
	[[[NSApp mainWindow] windowController] saveSymbols:sender];
}


@end
