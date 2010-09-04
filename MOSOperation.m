//
//  MOSOperation.m
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

#import "MOSOperation.h"
#import "MOSDatabase.h"

@implementation MOSOperation
@synthesize operationID, methodID, offset;
@synthesize address, bytes, opCode, data,notes,symbols, delegate;


+(NSString*)createTableSqlStatement{
	return @"create table Operations (operationID INTEGER PRIMARY KEY,"
	"methodID integer Key,"
	"offset integer,"
	"address text,"
	"bytes text,"
	"opcode test,"
	"data text,"
	"notes text,"
	"symbols text,"
	"UNIQUE (operationID))";
	
}

-(id)initWithResultRow:(EGODatabaseRow *)resultRow{
	self= [super init];
	if (self){
		self.operationID	= [resultRow intForColumn:@"operationID"];
		self.methodID		= [resultRow intForColumn:@"methodID"];
		self.offset			= [resultRow intForColumn:@"offset"];
		self.address		= [resultRow stringForColumn:@"address"];
		self.bytes			= [resultRow stringForColumn:@"bytes"];
		self.opCode			= [resultRow stringForColumn:@"opcode"];
		self.data			= [resultRow stringForColumn:@"data"];
		self.notes			= [resultRow stringForColumn:@"notes"];
		self.symbols		= [resultRow stringForColumn:@"symbols"];
		[self addObserver:self forKeyPath:@"notes" options:0 context:0];
	}
	return self;
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self.delegate executeUpdateWithParameters:@"update Operations set notes = ? where operationID = ?",self.notes, [NSNumber numberWithInteger:self.operationID],nil];
	if ([self.delegate hadError]) {
		NSLog(@"Err %d: %@", [self.delegate lastErrorCode], [self.delegate lastErrorMessage]);
	} 
}
-(void)dealloc{
	[self removeObserver:self forKeyPath:@"notes"];
	self.operationID	=	0;
	self.methodID		=	0;
	self.offset			=	0;
	self.address		=	nil;
	self.bytes			=	nil;
	self.opCode			=	nil;
	self.data			=	nil;
	self.notes			=	nil;
	self.symbols		=	nil;
	[super dealloc];
	
}


-(id)copyWithZone:(NSZone*)aZone{
	MOSOperation	* aCopy = [[MOSOperation allocWithZone:aZone] init];
	if (aCopy){
		aCopy.operationID	=self.operationID;
		aCopy.methodID		=self.methodID	;
		aCopy.offset		=self.offset	;		
		aCopy.address		=self.address	;
		aCopy.bytes			=self.bytes		;
		aCopy.opCode		=self.opCode	;	
		aCopy.data			=self.data		;
		aCopy.notes			=self.notes		;
		aCopy.symbols		=self.symbols	;
		
		[aCopy addObserver:aCopy forKeyPath:@"notes" options:0 context:0];
	}
	return aCopy;
	
}

-(BOOL)operationContainsString:(NSString*)searchString inFields:(NSInteger)fields{
	if (!searchString) return NO;
	
	if (fields & kSymbolsField && [self.symbols rangeOfString:searchString options:NSCaseInsensitiveSearch].location !=NSNotFound)
		return YES;
	if (fields & kDataField && [self.data rangeOfString:searchString options:NSCaseInsensitiveSearch].location !=NSNotFound)
		return YES;
	if (fields & kAddressField && [self.address rangeOfString:searchString options:NSCaseInsensitiveSearch].location !=NSNotFound)
		return YES;
	if (fields & kNotesField && [self.notes rangeOfString:searchString options:NSCaseInsensitiveSearch].location !=NSNotFound)
		return YES;

		
	return NO;
}
@end
