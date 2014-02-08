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
#import "Logger.h"

@interface VVBaseCommenter()
@property (nonatomic, copy) NSString *space;
@end

@implementation VVBaseCommenter
-(id) initWithIndentString:(NSString *)indent codeString:(NSString *)code
{
    self = [super init];
    if (self) {
        self.indent = indent;
        self.code = code;
        self.arguments = [NSMutableArray array];
        self.space = [[VVDocumenterSetting defaultSetting] spacesString];
    }
    return self;
}

-(NSString *) startComment
{
    return [NSString stringWithFormat:@"%@/**\n%@@brief \n", self.indent, self.prefixString];
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
    if ([[VVDocumenterSetting defaultSetting] addSinceToComments]) {
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

-(NSString *) document
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

-(NSString *) emptyLine
{
    return [NSString stringWithFormat:@"%@\n", self.prefixString];
}

-(NSString *) prefixString
{
    if ([[VVDocumenterSetting defaultSetting] prefixWithStar]) {
        return [NSString stringWithFormat:@"%@ *%@", self.indent, self.space];
    } else if ([[VVDocumenterSetting defaultSetting] prefixWithSlashes]) {
        return [NSString stringWithFormat:@"%@///%@", self.indent, self.space];
    } else {
        return [NSString stringWithFormat:@"%@ ", self.indent];
    }
}

-(void) parseArguments
{
    [self.arguments removeAllObjects];
    NSArray * braceGroups = [self.code vv_stringsByExtractingGroupsUsingRegexPattern:@"\\(([^\\^][^\\(\\)]*)\\)"];
    if (braceGroups.count > 0) {
        NSString *argumentGroupString = braceGroups[0];
        NSArray *argumentStrings = [argumentGroupString componentsSeparatedByString:@","];
        for (__strong NSString *argumentString in argumentStrings) {
            VVArgument *arg = [[VVArgument alloc] init];
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

}
@end
