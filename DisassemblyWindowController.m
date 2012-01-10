//
//  DisassemblyWindowController.m
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

#import "DisassemblyWindowController.h"
#import "MOSTextFieldCell.h"
#import "MOSOperation.h"

@implementation DisassemblyWindowController
@synthesize method;
@synthesize database;
@synthesize searchTerm;
@synthesize operationsTable;
@synthesize operationsController;
@synthesize highlightedCells;

static NSColor *_static_redHighlight = 0;
static NSColor *_static_greenHighlight = 0;

+(void)load{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	_static_redHighlight = [[NSColor colorWithCalibratedRed:0.9 green:0.6 blue:0.6 alpha:1.0] retain];
	_static_greenHighlight = [[NSColor colorWithCalibratedRed:0.6 green:0.9 blue:0.6 alpha:1.0] retain];
	[pool release];
}

-(id)init{
	self = [super initWithWindowNibName:[NSString stringWithString:@"DisassemblyWindow"]];
	if (self){
		[self showWindow:self];
		highlightedCells = [[NSMutableArray alloc] init];
	}
	return self;
}

-(id)initWithMethod:(MOSMethod*)aMethod{
	self = [self init];
	if (self){
		self.method =aMethod;
		if (aMethod.delegate)
			self.database = aMethod.delegate;
	}
	return self;
	
}

-(void)dealloc{
	[database release];
	[method release];
	[searchTerm release];
	[operationsController release];
	[highlightedCells release];
	[super dealloc];
}

-(void)openDisassemblyWindowForMethodID:(NSInteger)methodId{
	
	EGODatabaseResult * dbResult = [self.database executeQueryWithParameters:@"select * from Methods where methodID = ?",[NSNumber numberWithInteger:methodId],nil];
	if ([dbResult count]){
		for (EGODatabaseRow * row in dbResult){
			MOSMethod * methodToLoad = [[MOSMethod alloc] initWithResultRow:row];
			methodToLoad.delegate = self.database;
			DisassemblyWindowController * disWindowController = [[DisassemblyWindowController alloc] initWithMethod:methodToLoad];
			//FIXME: The window controller should be dealt with properly and not just leaked
#pragma unused(disWindowController)
			
			[methodToLoad release];
		}
	}
}

-(void)awakeFromNib{
	[self.operationsTable setDoubleAction:@selector(doubleClickedTableView:)];
	
}
-(IBAction)search:(id)sender{
	[self setSearchTerm:[sender stringValue]];
	[self.operationsTable reloadData];
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(MOSTextFieldCell*)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
	if (![aCell respondsToSelector:@selector(setHighlightColor:)]) return;
	
	[aCell setHighlightColor:nil];
	
	MOSOperation* repObj = [[self.operationsController arrangedObjects] objectAtIndex:rowIndex] ;
	[aCell setRepresentedObject: repObj];
	
	if ([repObj operationContainsString:[self searchTerm] inFields:[[aTableColumn identifier] integerValue]]){
		if (![[aTableView selectedRowIndexes] containsIndex:rowIndex]){
			[aCell setHighlightColor:_static_redHighlight];
			return;
		}
	}
	
	if ([self.highlightedCells count]){
		NSDictionary *columnRowDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
											 [aTableColumn identifier],@"column",[NSNumber numberWithInteger:rowIndex],@"row",nil]  ;
		if ([self.highlightedCells containsObject:columnRowDictionary]){
			[aCell setHighlightColor:_static_greenHighlight];
		}
	}
	
}

-(IBAction)clickedTableView:(id)sender{
	NSInteger clickedRow = [sender clickedRow];
	NSInteger clickedColumn = [sender clickedColumn];
	if (clickedColumn>=0){
		if ([[[[sender tableColumns] objectAtIndex:clickedColumn] identifier] integerValue ] == kDataField){
			
			
			NSArray *oldHighlights = [NSArray arrayWithArray:self.highlightedCells];
			[self.highlightedCells removeAllObjects];
			for (NSDictionary * columnRowDictionary in oldHighlights){
				NSInteger addressColumnIndex = [sender columnWithIdentifier: [columnRowDictionary objectForKey:@"column"]];
				NSInteger rowIndex = [[columnRowDictionary objectForKey:@"row"] integerValue];
				[(NSTableView*)sender reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex: 
															   rowIndex] 
												columnIndexes:[NSIndexSet indexSetWithIndex: addressColumnIndex]];
			}					
			
			
			MOSOperation* repObj = [[self.operationsController arrangedObjects] objectAtIndex:clickedRow];
			if ([repObj.opCode hasPrefix:@"j"]){
				NSString *jumpAddress = [repObj.data substringFromIndex:2];
				NSArray * allOps = [self.operationsController arrangedObjects];
				NSInteger count = [allOps count];
				while (count--){
					if ([[(MOSOperation*)[allOps objectAtIndex:count] address] isEqualToString:jumpAddress]){
						
						NSString * columnIdentifier = [NSString stringWithFormat:@"%ld",kAddressField];
						NSInteger addressColumnIndex = [sender columnWithIdentifier: columnIdentifier];
					    //NSTableColumn* addressColumn = [sender  tableColumnWithIdentifier:columnIdentifier];
						
						
						
						
						[self.highlightedCells addObject:[NSDictionary dictionaryWithObjectsAndKeys:
														  columnIdentifier,@"column",[NSNumber numberWithInteger:count],@"row",nil]];
						
						[(NSTableView*)sender reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:count] 
														columnIndexes:[NSIndexSet indexSetWithIndex: addressColumnIndex]];
						
						[(NSTableView*)sender scrollRowToVisible:count];
						break;
					}
				}
			}
		}
	}
}
-(IBAction)doubleClickedTableView:(id)sender{
	NSInteger clickedRow = [sender clickedRow];
	NSInteger clickedColumn = [sender clickedColumn];
	if (clickedColumn>=0){
		if ([[[[sender tableColumns] objectAtIndex:clickedColumn] identifier] integerValue ] == kDataField){
			MOSOperation* repObj = [[self.operationsController arrangedObjects] objectAtIndex:clickedRow];
			if ([repObj.opCode hasPrefix:@"j"]){
				NSString *jumpAddress = [repObj.data substringFromIndex:2];
				NSArray * allOps = [self.operationsController arrangedObjects];
				NSInteger count = [allOps count];
				while (count--){
					if ([[(MOSOperation*)[allOps objectAtIndex:count] address] isEqualToString:jumpAddress]){
					    [(NSTableView*)sender selectRowIndexes:[NSIndexSet indexSetWithIndex:count] byExtendingSelection:NO];
						[(NSTableView*)sender scrollRowToVisible:count];
						break;
					}
				}
			}
		}
	}
}

-(IBAction)insertToken:(id)sender{

	
}
@end
