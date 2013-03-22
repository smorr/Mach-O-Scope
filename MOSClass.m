//
//  MOSClass.m
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
#import "MOSClass.h"
#import "MOSDatabase.h"
#import "EGODatabaseResult.h"
#import "EGODatabaseRow.h"

@implementation MOSClass
@synthesize classID, className, name, delegate,classDump;

+(NSInteger)currentVersion{
	return 3;
}
//+(BOOL)createSqliteTableForDatabase:(MOSDatabase*)database{	
//	[database executeUpdateWithParameters:@"insert into properties (key,value) values (?, ?) ",@"methodsVersion",[NSNumber numberWithInteger:[self currentVersion]],nil];
//	if ([database hadError]) {
//		NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
//		return NO;
//	} 
//	
//	[database executeUpdate:@"create table Methods (methodID INTEGER PRIMARY KEY, classID integer Key, rawInfo text, methodName text, methodType text, returnType text, notes text, UNIQUE (methodID))"];
//	
//	if ([database hadError]) {
//		NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
//		return NO;
//	} 
//	return YES;
//}




+(NSInteger)persistenceVersionForDatabase:(MOSDatabase*)database{
	EGODatabaseResult * result = [database executeQueryWithParameters:@"select value from properties where key = ?",@"classesVersion",nil];
	if ([result count]){
		return [[result rowAtIndex:0] intForColumn:@"value"];
	}
	return -1;
}

+(BOOL)updateTableIfNecessaryForDatabase:(MOSDatabase*)database{
	NSInteger oldVersion = [self persistenceVersionForDatabase:database];
	NSInteger currentVersion = [self currentVersion];
    BOOL updateSuccessful = YES;
	if (oldVersion < currentVersion){
		[database executeUpdate:@"alter table Classes add classDump text"];
     		if ([database hadError]) {
			NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
			updateSuccessful = NO;
            
		} 
		if (oldVersion ==-1){
			[database executeUpdateWithParameters:@"insert into properties (key,value) values (?, ?) ",@"classesVersion",[NSNumber numberWithInteger:currentVersion],nil];
			if ([database hadError]) {
				NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
				return NO;
			} 
		}
		else{
			[database executeUpdateWithParameters:@"update properties set value=? where key=?",[NSNumber numberWithInteger:currentVersion],@"classesVersion",nil];
			if ([database hadError]) {
				NSLog(@"Err %d: %@", [database lastErrorCode], [database lastErrorMessage]);
				return NO;
			} 
			
		}
	}
	return updateSuccessful;
}



+ (NSArray *)classesForDatabase:(MOSDatabase*)database{
	EGODatabaseResult * classesResult = [database executeQuery:@"select * from Classes"];
	NSMutableArray * classes = [[NSMutableArray alloc] initWithCapacity:[classesResult count]];
	for (EGODatabaseRow* row in classesResult){
		MOSClass * classObject = [[MOSClass alloc] initWithID: [[row stringForColumn:@"classID"] integerValue] andName: [row stringForColumn:@"className"]];
		[classObject setDelegate:database];
        [classObject setClassDump: [row stringForColumn:@"classDump"]];
		[classes addObject:classObject];
		[classObject release];
	}
	return [classes autorelease];
}

+ (NSArray *)classesForDatabase:(MOSDatabase*)database searchingFor:(NSString*) aSymbol inContext:(NSInteger) context{
	if(!aSymbol || [aSymbol length]==0){
		return [self classesForDatabase:database];
	}
	if (context==kSymbolSearch){
		NSString * formattedSymbol =[NSString stringWithFormat:@"%%%@%%",aSymbol];
		EGODatabaseResult * classesResult = [database executeQueryWithParameters:@"select * from classes where classID in (select classID from methods where methodID in (select methodID from operations where symbols like ?))",formattedSymbol,nil];
		NSMutableArray * classes = [[NSMutableArray alloc] initWithCapacity:[classesResult count]];
		for (EGODatabaseRow* row in classesResult){
			MOSClass * classObject = [[MOSClass alloc] initWithID: [[row stringForColumn:@"classID"] integerValue] andName: [row stringForColumn:@"className"]];
			[classObject setDelegate:  database];
            [classObject setClassDump: [row stringForColumn:@"classDump"]];
            [classes addObject:classObject];
			[classObject release];
		}
		return [classes autorelease];
	}
	if (context==kMethodNameSearch){
		NSString * formattedSymbol =[NSString stringWithFormat:@"%%%@%%",aSymbol];
		EGODatabaseResult * classesResult = [database executeQueryWithParameters:@"select * from classes where classID in (select classID from methods where methodName like ?)",formattedSymbol,nil];
		NSMutableArray * classes = [[NSMutableArray alloc] initWithCapacity:[classesResult count]];
		for (EGODatabaseRow* row in classesResult){
			MOSClass * classObject = [[MOSClass alloc] initWithID: [[row stringForColumn:@"classID"] integerValue] andName: [row stringForColumn:@"className"]];
            [classObject setClassDump: [row stringForColumn:@"classDump"]];
            [classObject setDelegate:  database];
			[classes addObject:classObject];
			[classObject release];
		}
		return [classes autorelease];
		
	}
    
    if (context==kAddressSearch){
        NSString * formattedSymbol =[NSString stringWithFormat:@"%%%@%%",aSymbol];
		EGODatabaseResult * classesResult = [database executeQueryWithParameters:@"select * from classes where classID in (select classID from methods where methodID in (select methodID from operations where address like ?))",formattedSymbol,nil];
		NSMutableArray * classes = [[NSMutableArray alloc] initWithCapacity:[classesResult count]];
		for (EGODatabaseRow* row in classesResult){
			MOSClass * classObject = [[MOSClass alloc] initWithID: [[row stringForColumn:@"classID"] integerValue] andName: [row stringForColumn:@"className"]];
			[classObject setDelegate:  database];
            [classObject setClassDump: [row stringForColumn:@"classDump"]];
            [classes addObject:classObject];
			[classObject release];
		}
		return [classes autorelease];


        
    }
	return nil;
}

-(id)initWithID:(NSInteger) aClassID andName:(NSString*) aName{
	self = [super init];
	if (self){
		self.classID = aClassID;
		self.className = aName;
	}
	return self;
}

-(id)methods{
	return [self.delegate methodsForClassID:self.classID];
	
}

-(NSFont *)displayFont{
    return [NSFont fontWithName: @"Monaco" size:9.0];
    
}

-(void)dealloc{
	self.className = nil;
	[super dealloc];
}
-(id)copyWithZone:(NSZone *)zone{
	MOSClass * aCopy = [[MOSClass allocWithZone:zone] initWithID:self.classID andName:self.className];
	aCopy.delegate = self.delegate;
	return aCopy;
}

+ (NSArray *)classesForDatabase:(MOSDatabase*)database whoseMethodsReferToSymbol:(NSString*) aSymbol
{
	NSLog(@"needs to be implemented: %s",__PRETTY_FUNCTION__);
	return [NSArray array];
}
@end
