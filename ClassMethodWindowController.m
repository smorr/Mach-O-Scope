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
#import "MOSMethod.h"
#import "DisassemblyWindowController.h"

const NSString * myNibName = @"ClassMethodBrowser";

@interface ClassMethodWindowController()
@property (retain,readwrite) EGODatabase * database;

@end




@implementation ClassMethodWindowController
@synthesize database = _database;
@synthesize pathToDatabase;
@synthesize	methodFilter;
@synthesize symbolFilter,searchContext;
@synthesize showMisses;
@synthesize progressAmount, progressTotal;


-(id)init{
	self = [super initWithWindowNibName:[NSString stringWithString:myNibName]];
	if (self){
		[self addObserver:self forKeyPath:@"searchContext" options:0 context:nil];
		[self addObserver:self forKeyPath:@"showMisses" options:0 context:nil];
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
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	//if ([keyPath isEqualToString:@"searchContext"]){
		[self willChangeValueForKey:@"classes"];
		[self didChangeValueForKey:@"classes"];
	
}

-(void)dealloc{
	[self removeObserver:self forKeyPath:@"searchContext"];
	[self removeObserver:self forKeyPath:@"showMisses"];
	
	symbolFilter = nil;
	methodFilter = nil;
	[super dealloc];
}


-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	SEL action = [menuItem action];
	
	if (action==@selector(disassembleMachO:)) return YES;
	if (action==@selector(openDocument:)) return YES;

	return NO;
}

-(void)setFilterMethodPredicate:(id)dummyType{
	
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
	return methodFilter;
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
		[self willChangeValueForKey:@"classes"];
		id oldString = self.symbolFilter;
		symbolFilter = [aSymbol copy];
		[oldString release];
		[self didChangeValueForKey:@"classes"];
		
	}
}

-(IBAction)cancelImport:(id)sender{
	cancelImport = YES;	
}

-(void)importBundleAtPath:(id)bundlePath{
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: nil //didEndSheet:returnCode:contextInfo:
		  contextInfo: nil];		
	
	[NSThread detachNewThreadSelector:@selector(_backgroundImportBundleAtPath:) toTarget:self withObject:bundlePath];
}

-(void)_backgroundImportBundleAtPath:(id)bundlePath{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSString * tempOtxFile = [NSTemporaryDirectory() stringByAppendingString: [bundlePath lastPathComponent]];

	NSTask * otxTask = [[NSTask  alloc]  init];			
	NSString * pathToOtx = [[NSBundle bundleForClass: [self class]] pathForResource:@"otx" ofType:nil];
	[otxTask setLaunchPath:pathToOtx];
	
	//[[NSApp delegate] saveArchitecture] isEqualToString:@"x86_84"
	[otxTask setArguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"-outFile=%@",tempOtxFile],
						   [NSString stringWithFormat:@"-arch=%@",[[NSApp delegate] saveArchitecture]],
						   bundlePath,nil]];
	[otxTask launch];
	
	[otxTask waitUntilExit];
	
	[otxTask release];
	
	
	NSAutoreleasePool * readFromFilePool = [[NSAutoreleasePool alloc] init];
	NSString * dis = [[NSString alloc] initWithContentsOfFile:tempOtxFile];
	NSArray * disArray = [[dis componentsSeparatedByString:@"\n"] copy];
	[dis release];
	[readFromFilePool release];
	
	NSInteger counter = 0;
	NSMutableDictionary * methodsByClass =[[NSMutableDictionary alloc] init];
	NSString * currentClass = nil;
	NSMutableArray * currentDisassembly = nil;
	NSInteger currentMethodID = 0;
	NSInteger currentOpID = 0;
	
	[self.database dropStructure];
	[self.database createStructure];

	[self.database executeUpdate:@"create temporary table tempOperations (operationID INTEGER PRIMARY KEY,"
	 "methodID integer Key,"
	 "offset integer,"
	 "address text,"
	 "bytes text,"
	 "opcode test,"
	 "data text,"
	 "notes text,"
	 "symbols text,"
	 "UNIQUE (operationID))"];
	NSInteger totalCount = [disArray count];
	[self performSelectorOnMainThread:@selector(updateProgressIndicatorWithCount:)
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0], @"current",
																	[NSNumber numberWithInteger:totalCount], @"total",nil]  
						waitUntilDone:NO];
	
	for (NSString *line in disArray){
		
		if([line length] >0){
			if ([[line substringToIndex:2] isEqualToString:@"+("]){  				// class method
				NSDictionary * info = [[OTXDisassemblyScanner sharedScanner] scanClassMethodName:line];
				currentClass= [info objectForKey:@"className"];
				if (![methodsByClass objectForKey:currentClass]){
					
					
					
					[self.database executeQueryWithParameters:@"insert into Classes (className) values (?)",currentClass,nil];
					EGODatabaseResult* result = [self.database executeQueryWithParameters:@"select * from Classes where className == ?",currentClass,nil];
					if ([result count]){
						NSString * classID = [[result rowAtIndex:0] stringForColumnIndex:0];
						[methodsByClass setObject:[NSDictionary dictionaryWithObjectsAndKeys:classID,@"ID",[NSMutableArray array],@"methods",nil] forKey:currentClass];
					}
					
				}
				
				
				
				currentDisassembly = [NSMutableArray array];
				[[[methodsByClass objectForKey:currentClass] objectForKey:@"methods"] addObject:
				 [NSDictionary dictionaryWithObjectsAndKeys:@"class",@"methodType",
				  [info objectForKey:@"returnType"], @"returnType", 
				  [info objectForKey:@"method"],@"method",
				  line,@"fullName",
				  currentDisassembly,@"disassembly", nil]];
				NSString * classID = [[methodsByClass objectForKey:currentClass] objectForKey:@"ID"];
				currentMethodID++;
				[self.database executeQueryWithParameters:@"insert into Methods (methodID, classID,rawInfo, methodName,MethodType,returnType) values (?,?,?,?,?,?)",[NSNumber numberWithInteger:currentMethodID],classID,line,[info objectForKey:@"method"],@"+",[info objectForKey:@"returnType"],nil];
				
				
				
			}
			else if ([[line substringToIndex:2] isEqualToString:@"-("]){  				// instance method
				NSDictionary * info = [[OTXDisassemblyScanner sharedScanner] scanClassMethodName:line];
				currentClass= [info objectForKey:@"className"];
				if (![methodsByClass objectForKey:currentClass]){
					
					[self.database executeQueryWithParameters:@"insert into Classes (className) values (?)",currentClass,nil];
					EGODatabaseResult* result = [self.database executeQueryWithParameters:@"select ClassID from Classes where className = ?",currentClass,nil];
					NSString * classID = [[result rowAtIndex:0] stringForColumnIndex:0];
					[methodsByClass setObject:[NSDictionary dictionaryWithObjectsAndKeys:classID,@"ID",[NSMutableArray array],@"methods",nil] forKey:currentClass];
					
				}
				
				currentDisassembly = [NSMutableArray array];
				[[[methodsByClass objectForKey:currentClass] objectForKey:@"methods"] addObject:
				 [NSDictionary dictionaryWithObjectsAndKeys:@"instance",@"methodType",
				  [info objectForKey:@"returnType"], @"returnType", 
				  [info objectForKey:@"method"],@"method",
				  line,@"fullName",
				  currentDisassembly,@"disassembly", nil]];
				NSString * classID = [[methodsByClass objectForKey:currentClass] objectForKey:@"ID"];
				currentMethodID++;
				[self.database executeQueryWithParameters:@"insert into Methods (methodID, classID,rawInfo, methodName,MethodType,returnType) values (?,?,?,?,?,?)",[NSNumber numberWithInteger:currentMethodID],classID,line,[info objectForKey:@"method"],@"-",[info objectForKey:@"returnType"],nil];
				
				
			}
			else if ([[line substringToIndex:3] isEqualToString:@"___"]){ // block invoke!
				// eg    ___+[Library libraryIDForRemoteID:inRemoteMailbox:]_block_invoke_1:
				
			}
			else if ([[line substringToIndex:1] isEqualToString:@"_"]){// c function call
				//eg _GetDebugLogLevel
			}
			
			else if ([[line substringToIndex:1] isEqualToString:@" "]|| [[line substringToIndex:1] isEqualToString:@"\t"]){				
				if (currentDisassembly){
					NSDictionary * opDict = [[OTXDisassemblyScanner sharedScanner] scanDisassemblyLine:line];
					[currentDisassembly addObject: opDict];
					currentOpID++;
					[self.database 
					 executeQueryWithParameters:@"insert into tempOperations (operationID, methodID, offset,address,bytes,opcode,data,symbols) values (?,?,?,?,?,?,?,?)",[NSNumber numberWithInteger:currentOpID],
					 [NSNumber numberWithInteger:currentMethodID],
					 [opDict objectForKey:@"offset"],
					 [opDict objectForKey:@"address"],
					 [opDict objectForKey:@"bytes"],
					 [opDict objectForKey:@"operation"],
					 [opDict objectForKey:@"data"],
					 [opDict objectForKey:@"symbols"],
					 nil];
					
				}
			}
		}
		//if (counter  > 2500)break;
		if (++counter % 10000==0) 		{
			[self performSelectorOnMainThread:@selector(updateProgressIndicatorWithCount:)
								   withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:counter], @"current",
											   [NSNumber numberWithInteger:totalCount], @"total",nil]  
								waitUntilDone:NO];
			
			NSLog (@"%ld",counter);
			[self willChangeValueForKey:@"classes"];
			[self.database executeUpdate:@"insert into Operations select * from tempOperations "];
			[self didChangeValueForKey:@"classes"];
			[self.database executeUpdate:@"drop table tempOperations"];
			[self.database executeUpdate:@"create temporary table tempOperations (operationID INTEGER PRIMARY KEY,"
											 "methodID integer Key,"
											 "offset integer,"
											 "address text,"
											 "bytes text,"
											 "opcode test,"
											 "data text,"
											 "notes text,"
											 "symbols text,"
											 "UNIQUE (operationID))"];
			
		}
		if (cancelImport) break;
	}
	[self willChangeValueForKey:@"classes"];
	[self.database executeUpdate:@"insert into Operations select * from tempOperations "];
	[self didChangeValueForKey:@"classes"];
	[self.database executeUpdate:@"drop table tempOperations"];
	
	[disArray release];
	[self performSelectorOnMainThread:@selector(importComplete)
						   withObject:nil  
						waitUntilDone:NO];
	
	[pool release];
	
	
	
}

-(void)openDisassemblyWindowForMethodID:(NSInteger)methodId{

	EGODatabaseResult * dbResult = [self.database executeQueryWithParameters:@"select * from Methods where methodID = ?",[NSNumber numberWithInteger:methodId],nil];
	if ([dbResult count]){
		for (EGODatabaseRow * row in dbResult){
			MOSMethod * method = [[MOSMethod alloc] initWithResultRow:row];
			method.delegate = self.database;
			DisassemblyWindowController * disWindowController = [[DisassemblyWindowController alloc] initWithMethod:method];
			
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
}

-(void)importComplete{
	[NSApp endSheet:progressSheet];
	[progressSheet orderOut:self];
}

-(NSArray*)classes{
	id result =  [self.database classes];
	if (!result) return [NSMutableArray array];
	return result;
	
}


@end

