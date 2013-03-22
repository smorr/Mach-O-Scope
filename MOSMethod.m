//
//  MOSMethod.m
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

#import "MOSMethod.h"
#import "ClassMethodWindowController.h"

@implementation MOSMethod
@synthesize rawInfo,methodID, methodName,methodType, returnType, notes;
@synthesize highlightColor;
@synthesize delegate;


static NSColor * _Static_greyColor;
static NSColor * _Static_blackColor;

+(void)load{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	_Static_greyColor = [[NSColor colorWithDeviceWhite:0.8 alpha:1.0] retain];
	_Static_blackColor = [[NSColor blackColor] retain];
	[pool release];
}

-(id)initWithResultRow:(EGODatabaseRow *) resultRow{
	self = [super init];
	if (self){
		self.rawInfo = [resultRow stringForColumn:@"rawInfo"];
		self.methodID = [resultRow intForColumn:@"methodID"];
		self.methodName = [resultRow stringForColumn:@"methodName"];
		self.methodType = [resultRow stringForColumn:@"methodType"];
		self.returnType = [resultRow stringForColumn:@"returnType"];
		self.notes = [resultRow stringForColumn:@"notes"];
		[self addObserver:self forKeyPath:@"notes" options:0 context:0];

		
	}
	return self;
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self.delegate executeUpdateWithParameters:@"update Methods set notes = ? where methodID = ?",self.notes, [NSNumber numberWithInteger:self.methodID],nil];
	if ([self.delegate hadError]) {
		NSLog(@"Err %d: %@", [self.delegate lastErrorCode], [self.delegate lastErrorMessage]);
	} 
}
-(id)operations{
	return [self.delegate operationsForMethodID:self.methodID];	
}

-(void)dealloc{
	[self removeObserver:self forKeyPath:@"notes"];
	self.rawInfo = nil;
	self.methodName = nil;
	self.methodType = nil;
	self.returnType = nil;
	self.notes = nil;
	self.highlightColor = nil;
	[super dealloc];
}
-(id)copyWithZone:(NSZone *)zone{
	MOSMethod * aCopy = [[MOSMethod allocWithZone:zone] init];
	if (aCopy){
		aCopy.rawInfo = self.rawInfo;
		aCopy.methodName = self.methodName;
		aCopy.methodID = self.methodID;
		aCopy.delegate = self.delegate;
		aCopy.methodType = self.methodType;
		aCopy.returnType = self.returnType;
		aCopy.notes = self.notes;
		aCopy.highlightColor = self.highlightColor;
		
		[aCopy addObserver:aCopy forKeyPath:@"notes" options:0 context:0];
	}
	return aCopy;
}

+(NSString*)createTableSqlStatement
{
	NSLog(@"needs to be implemented: %s",__PRETTY_FUNCTION__);
	return @"";
}
@end

@implementation MOSMethod (database)

+(NSInteger)currentVersion{
	return 3;
}
+(BOOL)createSqliteTableForDatabase:(MOSDatabase*)database{	
	[database executeUpdateWithParameters:@"insert into properties (key,value) values (?, ?) ",@"methodsVersion",[NSNumber numberWithInteger:[self currentVersion]],nil];
	if ([database hadError]) {
		NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
		return NO;
	} 
	
	[database executeUpdate:@"create table Methods (methodID INTEGER PRIMARY KEY, classID integer Key, rawInfo text, methodName text, methodType text, returnType text, notes text, UNIQUE (methodID))"];
	
	if ([database hadError]) {
		NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
		return NO;
	} 
	return YES;
}




+(NSInteger)persistenceVersionForDatabase:(MOSDatabase*)database{
	EGODatabaseResult * result = [database executeQueryWithParameters:@"select value from properties where key = ?",@"methodsVersion",nil];
	if ([result count]){
		return [[result rowAtIndex:0] intForColumn:@"value"];
	}
	return -1;
}

+(BOOL)updateTableIfNecessaryForDatabase:(MOSDatabase*)database{
	NSInteger oldVersion = [self persistenceVersionForDatabase:database];
	NSInteger currentVersion = [self currentVersion];
	if (oldVersion < currentVersion){
		[database executeUpdate:@"alter table Methods add notes text"];
		if ([database hadError]) {
			NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
			return NO;
		} 
		if (oldVersion ==-1){
			[database executeUpdateWithParameters:@"insert into properties (key,value) values (?, ?) ",@"methodsVersion",[NSNumber numberWithInteger:currentVersion],nil];
			if ([database hadError]) {
				NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
				return NO;
			} 
		}
		else{
			[database executeUpdateWithParameters:@"update properties set value=? where key=?",[NSNumber numberWithInteger:currentVersion],@"methodsVersion",nil];
			if ([database hadError]) {
				NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
				return NO;
			} 
			
		}
	}
	return YES;
}
+(NSArray *)methodsInDatabase: (MOSDatabase *) database forClassID:(NSInteger)classID searchingFor:(NSString*) aSymbol inContext:(NSInteger) context{
	if(!aSymbol || [aSymbol length]==0){
		return [self methodsInDatabase:database forClassID:classID];
	}
	
	if (context == kSymbolSearch){
		
		
		NSString * formattedSymbol =[NSString stringWithFormat:@"%%%@%%",aSymbol];
		
		EGODatabaseResult * methodresult = [database executeQueryWithParameters:@"select methodID,rawInfo from methods where classid = ? and methodid in (select methodID from operations where symbols like ? )",[NSNumber numberWithInteger:classID],formattedSymbol,nil];
		if ([database.delegate showMisses]){
			NSMutableSet * highlightedMethods = [[NSMutableSet alloc] initWithCapacity:[methodresult count]];
			
			for (id row in methodresult){
				[highlightedMethods addObject:[row stringForColumn:@"methodID"]];
			}
			
			EGODatabaseResult * result = [database executeQueryWithParameters:@"select * from Methods where classID=?",[NSNumber numberWithInteger:classID]  ,nil];
			NSMutableArray * methods = [[NSMutableArray alloc] initWithCapacity:[result count]];
			NSMutableArray * nonHighlightedMethods = [[NSMutableArray alloc] initWithCapacity:[result count]];
			for (id row in result){
				MOSMethod* methodObject =[[MOSMethod alloc] initWithResultRow: row];
				if ([highlightedMethods containsObject:[row stringForColumn:@"methodID"]])	{
					[methodObject setHighlightColor:_Static_blackColor];
					[methods addObject:methodObject];
				}
				else{
					
					[methodObject setHighlightColor:_Static_greyColor];
					[nonHighlightedMethods addObject:methodObject];
				}
				[methodObject setDelegate:  database];
				
				[methodObject release];
			}
			[highlightedMethods release];
			[methods addObjectsFromArray:nonHighlightedMethods];
			[nonHighlightedMethods release];
			return [methods autorelease];
		}
		else{
			NSMutableArray * methods = [[NSMutableArray alloc] initWithCapacity:[methodresult count]];

			for (id row in methodresult){
				MOSMethod* methodObject =[[MOSMethod alloc] initWithResultRow: row];
				[methodObject setHighlightColor:_Static_blackColor];
				[methodObject setDelegate:  database];
				[methods addObject:methodObject];
				[ methodObject release];
			}
			return [methods autorelease];
		}
	}
	if (context == kMethodNameSearch){
		NSString * formattedSymbol =[NSString stringWithFormat:@"%%%@%%",aSymbol];
		
		EGODatabaseResult * methodresult = [database executeQueryWithParameters:@"select methodID,rawInfo from methods where classid = ? and methodName like ?",[NSNumber numberWithInteger:classID],formattedSymbol,nil];
		
		
		if ([database.delegate showMisses]){
			NSMutableSet * highlightedMethods = [[NSMutableSet alloc] initWithCapacity:[methodresult count]];
			
			for (id row in methodresult){
				[highlightedMethods addObject:[row stringForColumn:@"methodID"]];
			}
			
			EGODatabaseResult * result = [database executeQueryWithParameters:@"select * from Methods where classID=?",[NSNumber numberWithInteger:classID]  ,nil];
			NSMutableArray * methods = [[NSMutableArray alloc] initWithCapacity:[result count]];
			NSMutableArray * nonHighlightedMethods = [[NSMutableArray alloc] initWithCapacity:[result count]];
			for (id row in result){
				MOSMethod* methodObject =[[MOSMethod alloc] initWithResultRow: row];
				if ([highlightedMethods containsObject:[row stringForColumn:@"methodID"]])	{
					[methodObject setHighlightColor:_Static_blackColor];
					[methods addObject:methodObject];
				}
				else{
					[methodObject setHighlightColor:_Static_greyColor];
					[nonHighlightedMethods addObject:methodObject];
				}
				[methodObject setDelegate:  database];
				
				[methodObject release];
			}
			[highlightedMethods release];
			[methods addObjectsFromArray:nonHighlightedMethods];
			[nonHighlightedMethods release];
			return [methods autorelease];
		}
		else{
			NSMutableArray * methods = [[NSMutableArray alloc] initWithCapacity:[methodresult count]];
			
			for (id row in methodresult){
				MOSMethod* methodObject =[[MOSMethod alloc] initWithResultRow: row];
				[methodObject setHighlightColor:_Static_blackColor];
				[methodObject setDelegate:  database];
				[methods addObject:methodObject];
				[methodObject release];
			}
			return [methods autorelease];
		}
		
	}
    if (context == kAddressSearch){
		
		
		NSString * formattedSymbol =[NSString stringWithFormat:@"%%%@%%",aSymbol];
		
		EGODatabaseResult * methodresult = [database executeQueryWithParameters:@"select methodID,rawInfo from methods where classid = ? and methodid in (select methodID from operations where address like ? )",[NSNumber numberWithInteger:classID],formattedSymbol,nil];
		if ([database.delegate showMisses]){
			NSMutableSet * highlightedMethods = [[NSMutableSet alloc] initWithCapacity:[methodresult count]];
			
			for (id row in methodresult){
				[highlightedMethods addObject:[row stringForColumn:@"methodID"]];
			}
			
			EGODatabaseResult * result = [database executeQueryWithParameters:@"select * from Methods where classID=?",[NSNumber numberWithInteger:classID]  ,nil];
			NSMutableArray * methods = [[NSMutableArray alloc] initWithCapacity:[result count]];
			NSMutableArray * nonHighlightedMethods = [[NSMutableArray alloc] initWithCapacity:[result count]];
			for (id row in result){
				MOSMethod* methodObject =[[MOSMethod alloc] initWithResultRow: row];
				if ([highlightedMethods containsObject:[row stringForColumn:@"methodID"]])	{
					[methodObject setHighlightColor:_Static_blackColor];
					[methods addObject:methodObject];
				}
				else{
					
					[methodObject setHighlightColor:_Static_greyColor];
					[nonHighlightedMethods addObject:methodObject];
				}
				[methodObject setDelegate:  database];
				
				[methodObject release];
			}
			[highlightedMethods release];
			[methods addObjectsFromArray:nonHighlightedMethods];
			[nonHighlightedMethods release];
			return [methods autorelease];
		}
		else{
			NSMutableArray * methods = [[NSMutableArray alloc] initWithCapacity:[methodresult count]];
            
			for (id row in methodresult){
				MOSMethod* methodObject =[[MOSMethod alloc] initWithResultRow: row];
				[methodObject setHighlightColor:_Static_blackColor];
				[methodObject setDelegate:  database];
				[methods addObject:methodObject];
				[ methodObject release];
			}
			return [methods autorelease];
		}
	}

	return nil;
}

+(NSArray *)methodsInDatabase: (MOSDatabase *) database forClassID:(NSInteger)classID{
	
	EGODatabaseResult * result = [database executeQueryWithParameters:@"select Methods.* from Methods where  Methods.classID = ?",[NSNumber numberWithInteger:classID],nil];
	NSMutableArray * methods = [[NSMutableArray alloc] initWithCapacity:[result count]];
	for (id row in result){
		MOSMethod* methodObject =[[MOSMethod alloc] initWithResultRow: row];

		[methodObject setDelegate:  database];
		[methods addObject:methodObject];
		[methodObject release];
	}
	return [methods autorelease];
}

@end
