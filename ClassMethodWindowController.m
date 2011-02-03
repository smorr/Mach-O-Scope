//
//  ClassMethodWindowController.m
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

#import "ClassMethodWindowController.h"
#import "OTXDisassemblyScanner.h"
#import "MOSClass.h"
#import "MOSMethod.h"
#import "MOSOperation.h"

#import "MOSTextFieldCell.h"

#import "DisassemblyWindowController.h"

NSString * myNibName = @"ClassMethodBrowser";

@interface ClassMethodWindowController()
@property (retain,readwrite) MOSDatabase * database;
@property (retain) OTXDisassemblyScanner * currentScanner;
@end




@implementation ClassMethodWindowController
@synthesize database = _database;
@synthesize pathToDatabase;
@dynamic	methodFilter;
@synthesize symbolFilter,searchContext;
@synthesize showMisses;
@synthesize progressAmount, progressTotal;
@synthesize currentScanner;
@synthesize currentClassSelection;
@synthesize currentMethodSelection;
@synthesize operationsTable;
@synthesize	operationsController;
@synthesize highlightedCells;

static NSColor *_static_yellowHighlight = 0;
static NSColor *_static_greenHighlight = 0;

+(void)load{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	_static_yellowHighlight = [[NSColor colorWithCalibratedRed:0.9 green:0.6 blue:0.6 alpha:1.0] retain];
	_static_greenHighlight = [[NSColor colorWithCalibratedRed:0.6 green:0.9 blue:0.6 alpha:1.0] retain];
	[pool release];
}


-(id)init{
	self = [super initWithWindowNibName:[NSString stringWithString:myNibName]];
	if (self){
		[self addObserver:self forKeyPath:@"searchContext" options:0 context:nil];
		[self addObserver:self forKeyPath:@"showMisses" options:0 context:nil];
		highlightedCells = [[NSMutableArray alloc] init];
	}
	return self;
}
-(id)initWithDatabasePath:(NSString*)aPath{
	self = [self init];
	if (self){
		self.database = [[MOSDatabase alloc] initWithPath:aPath andDelegate:self];
	}
	return self;
}

-(void)dealloc{
	[self removeObserver:self forKeyPath:@"searchContext"];
	[self removeObserver:self forKeyPath:@"showMisses"];
	
	[symbolFilter release];
	[methodFilter release];
	[currentScanner release];
	[highlightedCells release];
	[operationsController release];
	[super dealloc];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	//if ([keyPath isEqualToString:@"searchContext"]){
	[self willChangeValueForKey:@"classes"];
	[self didChangeValueForKey:@"classes"];
	
}


-(NSArray*)classes{
	
	id result =  [self.database classes];
	
	if (!result) return [NSMutableArray array];
	return result;
	
}


-(void)setFilterMethodPredicate:(id)dummyType{
	// implemented for binding purposes
}

-(NSPredicate *)filterMethodPredicate
{
	if (methodFilter && [methodFilter length]>0){
		NSPredicate * aPredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@" ,@"rawInfo",methodFilter];
		return aPredicate;
	}
	return [NSPredicate predicateWithValue:YES];
}
-(NSString *)methodFilter
{
	// atomic return;
	return [[methodFilter retain] autorelease];
}



-(void) setMethodFilter:(NSString *)aFilterString
{
	
	if (methodFilter != aFilterString){
		[self willChangeValueForKey:@"filterMethodPredicate"];//
		id oldString = methodFilter;
		methodFilter = [aFilterString copy];
		[oldString release];
		[self didChangeValueForKey:@"filterMethodPredicate"];//
	}

}

-(NSString *)symbolFilter
{
	return symbolFilter;
}

-(void) setSymbolFilter:(NSString*)aSymbol{
	if (aSymbol != self.symbolFilter){
				
		if ([[classesController selectedObjects] count]){
			self.currentClassSelection = [classesController selectedObjects];
		}	
		if ([[methodsController selectedObjects] count]){
			self.currentMethodSelection = [methodsController selectedObjects];
		}	
		
		[self willChangeValueForKey:@"classes"];
		id oldString = self.symbolFilter;
		symbolFilter = [aSymbol copy];
		[oldString release];
		[self didChangeValueForKey:@"classes"];
		
		if ([self.currentClassSelection count]){
			NSArray * arrangedObjects =[classesController arrangedObjects];
			MOSClass* selectedClass = [self.currentClassSelection objectAtIndex:0];
			for (MOSClass* aClass in arrangedObjects){
				if (aClass.classID ==selectedClass.classID){
					[classesController setSelectedObjects:[NSArray arrayWithObject:aClass]];
					if ([self.currentMethodSelection count]){
						MOSMethod * selectedMethod = [self.currentMethodSelection objectAtIndex:0];
						for (MOSMethod * aMethod in [methodsController arrangedObjects]){
							if (aMethod.methodID  == selectedMethod.methodID){
								[methodsController setSelectedObjects:[NSArray arrayWithObject:aMethod]];
								 break;
							}
						}
					
					break;
					} // if currentMethodSelection.count
				} // if classid = classid
			} // for
		} // if
	} // if aSymbol
}

-(IBAction)cancelImport:(id)sender{
	self.currentScanner.cancelImport = YES;	
}

-(void)importBundleAtPath:(id)bundlePath{
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: nil //didEndSheet:returnCode:contextInfo:
		  contextInfo: nil];		
	
	self.currentScanner = [[OTXDisassemblyScanner alloc] initWithDelegate:self bundle:bundlePath andDatabase:self.database];
	[NSThread detachNewThreadSelector:@selector(_backgroundImportBundle) toTarget:self.currentScanner withObject:nil];
	
}
-(void)importOtxAtPath:(id)otxPath{
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: nil //didEndSheet:returnCode:contextInfo:
		  contextInfo: nil];		
	
	self.currentScanner = [[OTXDisassemblyScanner alloc] initWithDelegate:self bundle:otxPath andDatabase:self.database];
	[NSThread detachNewThreadSelector:@selector(_backgroundImportOtx) toTarget:self.currentScanner withObject:nil];
	
}


-(void)openDisassemblyWindowForMethodID:(NSInteger)methodId{

	EGODatabaseResult * dbResult = [self.database executeQueryWithParameters:@"select * from Methods where methodID = ?",[NSNumber numberWithInteger:methodId],nil];
	if ([dbResult count]){
		for (EGODatabaseRow * row in dbResult){
			MOSMethod * method = [[MOSMethod alloc] initWithResultRow:row];
			method.delegate = self.database;
			DisassemblyWindowController * disWindowController = [[DisassemblyWindowController alloc] initWithMethod:method];
			//FIXME: The window controller should be dealt with properly and not just leaked
#pragma unused(disWindowController);
			
			[method release];
		}
	}
}



-(NSString *)progressLabel{
	return [NSString stringWithFormat:@"Processing line %ld of %ld",self.progressAmount,self.progressTotal];
}

-(void)updateProgressIndicatorWithCount:(NSDictionary*)status{
	[self willChangeValueForKey:@"progressLabel"];
	self.progressAmount = [[status objectForKey:@"current"] integerValue];
	self.progressTotal = [[status objectForKey:@"total"] integerValue];
	[self didChangeValueForKey:@"progressLabel"];
	
	// force an update of the classes property so the UI will update accordingly
	[self willChangeValueForKey:@"classes"];
	[self didChangeValueForKey:@"classes"];
}

-(void)importCompleteWithResult:(NSNumber *) result{
	[NSApp endSheet:progressSheet];
	[progressSheet orderOut:self];
	self.currentScanner = nil;
	
	// force an update of the classes property so the UI will update accordingly
	[self willChangeValueForKey:@"classes"];
	[self didChangeValueForKey:@"classes"];

}




-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	SEL action = [menuItem action];
	
	if (action==@selector(disassembleMachO:)) return YES;
	if (action==@selector(openDocument:)) return YES;
	
	return NO;
}

-(void)doubleClickMethod:(id)sender{
	[self openDisassemblyWindowForMethodID:[sender integerValue]];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(MOSTextFieldCell*)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
	if (![aCell respondsToSelector:@selector(setHighlightColor:)]) return;

	[aCell setHighlightColor:nil];

	if (aTableView == self.operationsTable){
		MOSOperation* repObj = [[operationsController arrangedObjects] objectAtIndex:rowIndex] ;
		[aCell setRepresentedObject: repObj];
		
		if ( [repObj operationContainsString:[self symbolFilter] inFields:kDataField | kSymbolsField | kNotesField]){
			
			if (![[aTableView selectedRowIndexes] containsIndex:rowIndex]){
				[aCell setHighlightColor:_static_yellowHighlight];
				return;
			}
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
					    NSTableColumn* addressColumn = [sender  tableColumnWithIdentifier:columnIdentifier];
						
						
						
						
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
					    [(NSTableView*)sender selectRow:count byExtendingSelection:NO];
						[(NSTableView*)sender scrollRowToVisible:count];
						break;
					}
				}
			}
		}
	}
}
-(IBAction)saveSymbols:(id)sender
{
	NSString* createViewQuery = @"create view operations_by_address_desc as select * from operations order by address desc;";
	NSString* query = @"select Methods.methodName, operations_by_address_desc.address from operations_by_address_desc inner join Methods on operations_by_address_desc.methodId = Methods.methodId group by Methods.methodId;";
	NSString* dropViewQuery = @"drop view operations_by_address_desc;";

	[self.database executeQueryWithParameters:createViewQuery,nil];
	EGODatabaseResult * dbResult = [self.database executeQueryWithParameters:query,nil];
	[self.database executeQueryWithParameters:dropViewQuery,nil];
	
	if ([dbResult count]){
		NSMutableString* file = [NSMutableString string];
		for (EGODatabaseRow * row in dbResult)
		{
			[file appendFormat:@"%@ %@\n",[row.columnData objectAtIndex:1],[row.columnData objectAtIndex:0]];
		}
		NSString* path = [[self.database.databasePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[[self.database.databasePath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"symbols"]];
		[file writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
	else
	{
		NSRunAlertPanel(@"Error", @"No Results", @"Ok", nil, nil);
	}
}

-(IBAction)openDocument:(id)sender
{
	NSLog(@"to be implemented");
}
-(IBAction)disassembleMachO:(id)sender
{
	NSLog(@"to be implemented");
}

-(IBAction)openNewDissamblyWindow:(id)sender
{
	NSLog(@"to be implemented");
}

@end


