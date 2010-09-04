//
//  MOSDatabase.m
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

#import "MOSDatabase.h"

const NSInteger structureVersion = 1;
#import "MOSClass.h"
#import "MOSMethod.h"
#import "MOSOperation.h"

@implementation MOSDatabase
@synthesize delegate;

static NSColor * _Static_greyColor;
static NSColor * _Static_blackColor;
static NSColor * _Static_mediumGreyColor;
static NSColor * _Static_redColor;

+(void)load{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	_Static_mediumGreyColor = [[NSColor colorWithDeviceWhite:0.5 alpha:1.0] retain];
	_Static_greyColor = [[NSColor colorWithDeviceWhite:0.8 alpha:1.0] retain];
	_Static_blackColor = [[NSColor blackColor] retain];
	_Static_redColor = [[NSColor redColor] retain];
	[pool release];
}


-(BOOL)dropStructure{
	[self executeUpdate:@"drop table Classes"];
	[self executeUpdate:@"drop table Methods"];
	[self executeUpdate:@"drop table Operations"];
	[self executeUpdate:@"drop table properties"];
	return YES;
}
-(NSString*)databaseName{
	return [[self databasePath]	lastPathComponent];
}

-(NSArray *)classes{
	return [MOSClass classesForDatabase:self searchingFor: [self.delegate symbolFilter] inContext:[self.delegate searchContext]];

}

-(NSArray *)methodsForClassID:(NSInteger)classID{
	return [MOSMethod methodsInDatabase:self forClassID:classID searchingFor:[self.delegate symbolFilter] inContext:[self.delegate searchContext]];
	
}
-(NSArray *)operationsForMethodID:(NSInteger)methodID{
	
	EGODatabaseResult * result = [self executeQueryWithParameters:@"select * from Operations where methodid = ?",[NSNumber numberWithInteger:methodID],nil];
	NSMutableArray * operations = [[NSMutableArray alloc] initWithCapacity:[result count]];
	for (id row in result){
		MOSOperation* operationObject =[[MOSOperation alloc] initWithResultRow:row];
		[operations addObject:operationObject];
		[operationObject release];
	}
	return [operations autorelease];
	
}


-(BOOL)updateStructuresIfNecessary{
	return [MOSMethod updateTableIfNecessaryForDatabase:self];
}
-(BOOL)createStructure{
	
	[self executeUpdateWithParameters:@"create table properties (ROWID INTEGER PRIMARY KEY, key text, value text, UNIQUE (key))",nil];
	if ([self hadError]) {
		NSLog(@"Err %d: %@", [self lastErrorCode], [self lastErrorMessage]);
		return NO;
	} 
	[self executeUpdateWithParameters:@"insert into properties (key, value) values (?, ?)",@"version",[NSNumber numberWithInteger:structureVersion],nil];
	if ([self hadError]) {
		NSLog(@"Err %d: %@", [self lastErrorCode], [self lastErrorMessage]);
		return NO;
	} 
	
	[self executeUpdateWithParameters:@"create table Classes (classID INTEGER PRIMARY KEY, className text, categoryName text, UNIQUE (classID))",nil];
	if ([self hadError]) {
		NSLog(@"Err %d: %@", [self lastErrorCode], [self lastErrorMessage]);
		return NO;
	} 
	
	
	if (![MOSMethod createSqliteTableForDatabase:self]){
		return NO;
	} 
	
	[self executeUpdate:[MOSOperation createTableSqlStatement]];
	
	if ([self hadError]) {
		NSLog(@"Err %d: %@", [self lastErrorCode], [self lastErrorMessage]);
		return NO;
	} 
	
	
	if(![self tableExists:@"properties"]){
		return NO;
	}
	return YES;

}

-(id)initWithPath:(NSString *)aPath andDelegate:(id)anObject{
	self = [super initWithPath:aPath];
	if (self){
		if (![self open]) {
			NSLog(@"Could not open databaseForPath:%@",aPath);
			[self release];
			self = nil;
			return 0;
		}
		self.delegate = anObject;
		if(![self tableExists:@"properties"]){
			[self createStructure];
		}
		else{
			[self updateStructuresIfNecessary];
		}
		
	}
	return self;
}
@end
