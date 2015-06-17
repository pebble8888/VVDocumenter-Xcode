//
//  VVBaseCommenter.m
//  VVDocumenter-Xcode
//
//  Created by 王 巍 on 13-7-17.
//  Copyright (c) 2013年 OneV's Den. All rights reserved.
//
/**
 * @brief C function
 */

#import "VVBaseCommenter.h"
#import "VVArgument.h"
#import "VVDocumenterSetting.h"
#import "NSString+VVSyntax.h"
#import "Logger.h"

@interface VVBaseCommenter()
@property (nonatomic, copy) NSString *space;
@property (nonatomic, assign) BOOL forSwift;
@property (nonatomic, assign) BOOL forSwiftEnum;
@end

@implementation VVBaseCommenter
-(instancetype) initWithIndentString:(NSString *)indent codeString:(NSString *)code
{
    self = [super init];
    if (self) {
        _indent = indent;
        _code = code;
        _arguments = [NSMutableArray array];
        _space = [[VVDocumenterSetting defaultSetting] spacesString];
        _forSwift = NO;
        _forSwiftEnum = NO;
    }
    return self;
}

-(NSString *) paramSymbol {
    return self.forSwift ? @":param:" : @"@param";
}

-(NSString *) returnSymbol {
    return self.forSwift ? @":returns:" : @"@return";
}

-(NSString *) startComment
{
    return [NSString stringWithFormat:@"/**\n%@@brief \n", self.prefixString];
}

-(NSString *) argumentsComment
{
    if (self.arguments.count == 0)
        return @"";
    
    // start of with an empty line
    NSMutableString *result = [NSMutableString stringWithFormat:@""];
    
    int longestNameLength = [[self.arguments valueForKeyPath:@"@max.name.length"] intValue];

    for (VVArgument *arg in self.arguments) {
        NSString *paddedName = [arg.name stringByPaddingToLength:longestNameLength
                                                      withString:@" "
                                                 startingAtIndex:0];
        
        [result appendFormat:@"%@@param (%@)%@ \n", self.prefixString, arg.type, paddedName];
    }
    return result;
}

-(NSString *) returnComment
{
    if (!self.hasReturn) {
        return @"";
    } else {
        return [NSString stringWithFormat:@"%@@return \n", self.prefixString];
    }
}

-(NSString *) sinceComment
{
    //It seems no since attribute for swift? Maybe I am wrong.
    if (!self.forSwift && [[VVDocumenterSetting defaultSetting] addSinceToComments]) {
        return [NSString stringWithFormat:@"%@%@@since <#version number#>\n", self.emptyLine, self.prefixString];
    } else {
        return @"";
    }
}

-(NSString *) endComment
{
    if ([[VVDocumenterSetting defaultSetting] prefixWithSlashes]) {
        return @"";
    } else {
        return [NSString stringWithFormat:@"%@ */",self.indent];
    }
}

-(NSString *) documentForSwift
{
    self.forSwift = YES;
    return [self __document];
}

-(NSString *) documentForSwiftEnum
{
    self.forSwiftEnum = YES;
    self.forSwift = YES;
    return [self __document];
}

-(NSString *) documentForC
{
    self.forSwift = NO;
    return [self __document];
}

-(NSString *) __document
{
    NSString * comment = [NSString stringWithFormat:@"%@%@%@%@%@",
                          [self startComment],
                          [self argumentsComment],
                          [self returnComment],
                          [self sinceComment],
                          [self endComment]];
    
    // The last line of the comment should be adjacent to the next line of code,
    // back off the newline from the last comment component.
    if ([[VVDocumenterSetting defaultSetting] prefixWithSlashes]) {
        return [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        return comment;
    }
}

-(NSString *) document
{
    //This is the default action
    return [self documentForC];
}

-(NSString *) emptyLine
{
    if ([[VVDocumenterSetting defaultSetting] blankLinesBetweenSections]) {
        return [[NSString stringWithFormat:@"%@\n", self.prefixString] vv_stringByTrimEndSpaces];
    } else {
        return @"";
    }
}

-(NSString *) prefixString
{
    if ([[VVDocumenterSetting defaultSetting] prefixWithStar] && !self.forSwift) {
        return [NSString stringWithFormat:@"%@ *%@", self.indent, self.space];
    } else if ([[VVDocumenterSetting defaultSetting] prefixWithSlashes]) {
        return [NSString stringWithFormat:@"%@///%@", self.indent, self.space];
    } else {
        return [NSString stringWithFormat:@"%@ ", self.indent];
    }
}

-(void) parseArgumentsInputArgs:(NSString *)rawArgsCode
{
    [self.arguments removeAllObjects];
    if (rawArgsCode.length == 0) {
        return;
    }

    NSArray *argumentStrings = [rawArgsCode componentsSeparatedByString:@","];
    for (__strong NSString *argumentString in argumentStrings) {
        VVArgument *arg = [[VVArgument alloc] init];
        argumentString = [argumentString vv_stringByReplacingRegexPattern:@"=\\s*\\w*" withString:@""];
        argumentString = [argumentString vv_stringByReplacingRegexPattern:@"\\(" withString:@" "];
        argumentString = [argumentString vv_stringByReplacingRegexPattern:@"\\*" withString:@" "];
        argumentString = [argumentString vv_stringByReplacingRegexPattern:@"\\s+$" withString:@""];
        argumentString = [argumentString vv_stringByReplacingRegexPattern:@"\\s+" withString:@" "];
        NSMutableArray *tempArgs = [[argumentString componentsSeparatedByString:@" "] mutableCopy];
        while ([[tempArgs lastObject] isEqualToString:@" "]) {
            [tempArgs removeLastObject];
        }

        arg.name = [tempArgs lastObject];

        [tempArgs removeLastObject];
        arg.type = [tempArgs componentsJoinedByString:@" "];
        
        DEBUG_LOG(@"arg type: %@", arg.type);
        DEBUG_LOG(@"arg name: %@", arg.name);
        
        [self.arguments addObject:arg];
    }
}

-(BOOL) shouldComment
{
    return YES;
}

@end
