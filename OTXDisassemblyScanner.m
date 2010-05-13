//
//  OTXDisassemblyScanner.m
//  otxProcessor
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
#import "OTXDisassemblyScanner.h"


@implementation OTXDisassemblyScanner


static OTXDisassemblyScanner *_sharedScanner = nil;

+ (OTXDisassemblyScanner*)sharedScanner
{
    @synchronized(self) {
        if (_sharedScanner == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return _sharedScanner;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (_sharedScanner == nil) {
            _sharedScanner = [super allocWithZone:zone];
            return _sharedScanner;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
} 

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}


-(NSDictionary *) scanClassMethodName:(NSString *) line{
	NSScanner * lineScanner = [NSScanner scannerWithString:line];
	NSString * returnType = nil;
	[lineScanner scanUpToString:@"(" intoString:nil];
	[lineScanner scanUpToString:@"[" intoString:&returnType];
	[lineScanner scanString:@"[" intoString:nil];
	NSString *className = nil;
	[lineScanner scanUpToString:@" " intoString:&className];
	[lineScanner scanString:@" " intoString:nil];
	NSString *methodName = nil;
	[lineScanner scanUpToString:@"]" intoString:&methodName];
	
	NSDictionary *resultDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  returnType,@"returnType",className, @"className", methodName, @"method", nil];
	return resultDictionary;
}

-(NSDictionary *)scanDisassemblyLine:(NSString *)line{
	NSScanner * lineScanner = [NSScanner scannerWithString:line];
	[lineScanner scanUpToString:@"+" intoString:nil];
	//[lineScanner scanString:@"+" intoString:nil];
	NSString * offset = nil;
	[lineScanner scanUpToString:@" " intoString:&offset];
	//[lineScanner scanString:@"\t" intoString:nil];
	
	NSString * address = nil;
	[lineScanner scanUpToString:@"  " intoString:&address];
	//[lineScanner scanString:@"  " intoString:nil];
	
	NSString * bytes = nil;
	NSString * op = nil;
	NSString * data = nil;
	NSString * note = nil;
	[lineScanner scanUpToString:@" " intoString:&bytes];
	[lineScanner scanUpToString:@" " intoString:&op];
	[lineScanner scanUpToString:@" " intoString:&data];
	[lineScanner scanUpToString:@"  " intoString:&note];
	
	if (!data) data=@"";
	if (!note) note = @"";
	
	//NSString * resultString = [NSString stringWithFormat:@"o:%@ a:%@ b:%@ oo:%@ d:%@ n:%@",offset,address,bytes,op,data,note];
	//NSString * resultString = [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\t%@",offset,address,bytes,op,data,note];
	
	NSDictionary *resultDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInteger:[offset integerValue]],@"offset",
									  address, @"address", 
									  bytes, @"bytes", 
									  op, @"operation",
									  data, @"data",
									  note, @"symbols", nil];
	
	return resultDictionary;
}


@end
