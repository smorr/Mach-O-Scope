//
//  MOSMethod.h
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
#import "EGODatabaseRow.h"
@interface MOSMethod : NSObject {
	NSString * rawInfo;
	NSString * methodName;
	NSInteger  methodID;
	NSString * methodType;
	NSString * returnType;
	NSString * notes;
	
	NSColor * highlightColor;
	
	id delegate;
}
@property (assign) id delegate;
@property (assign) NSInteger  methodID;
@property (copy) NSString *rawInfo;
@property (copy) NSString *methodName;
@property (copy) NSString *methodType;
@property (copy) NSString *returnType;
@property (copy) NSString *notes;
@property (assign) NSColor * highlightColor;
+(NSString*)createTableSqlStatement;

-(id)initWithResultRow:(EGODatabaseRow *) resultRow;


@end

@interface MOSMethod (database)
+(NSArray *)methodsInDatabase: (MOSDatabase *) database forClassID:(NSInteger)classID searchingFor:(NSString*) aSymbol inContext:(NSInteger) context;
+(NSArray *)methodsInDatabase: (MOSDatabase *) database forClassID:(NSInteger)classID;
+(BOOL)createSqliteTableForDatabase:(MOSDatabase*)database;
+(NSInteger)currentVersion;
+(NSInteger)persistenceVersionForDatabase:(MOSDatabase*)database;
+(BOOL)updateTableIfNecessaryForDatabase:(MOSDatabase*)database;
@end

