//
//  NSString+VVTextGetter.m
//  VVDocumenter-Xcode
//
//  Created by 王 巍 on 14-7-31.
//  Copyright (c) 2014年 OneV's Den. All rights reserved.
//

#import "NSString+VVTextGetter.h"
#import "VVTextResult.h"

@implementation NSString (VVTextGetter)

-(VVTextResult *) vv_textResultOfCurrentLineCurrentLocation:(NSInteger)location
{
    NSInteger curseLocation = location;
    NSRange range = NSMakeRange(0, curseLocation);
    NSRange thisLineRange = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:range];
    
    NSString *line = nil;
    if (thisLineRange.location != NSNotFound) {
        NSRange lineRange = NSMakeRange(thisLineRange.location + 1, curseLocation - thisLineRange.location - 1);
        if (lineRange.location < [self length] && NSMaxRange(lineRange) < [self length]) {
            line = [self substringWithRange:lineRange];
            return [[VVTextResult alloc] initWithRange:lineRange string:line];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}


-(VVTextResult *) vv_textResultOfPreviousLineCurrentLocation:(NSInteger)location
{
    NSInteger curseLocation = location;
    NSRange range = NSMakeRange(0, curseLocation);
    NSRange thisLineRange = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:range];
    
    NSString *line = nil;
    if (thisLineRange.location != NSNotFound) {
        range = NSMakeRange(0, thisLineRange.location);
        NSRange previousLineRange = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:range];
        
        if (previousLineRange.location != NSNotFound) {
            NSRange lineRange = NSMakeRange(previousLineRange.location + 1, thisLineRange.location - previousLineRange.location);
            if (lineRange.location < [self length] && NSMaxRange(lineRange) < [self length]) {
                line = [self substringWithRange:lineRange];
                return [[VVTextResult alloc] initWithRange:lineRange string:line];
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

-(VVTextResult *) vv_textResultOfNextLineCurrentLocation:(NSInteger)location
{
    NSInteger curseLocation = location;
    NSRange range = NSMakeRange(curseLocation, self.length - curseLocation);
    NSRange thisLineRange = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:range];
    
    NSString *line = nil;
    if (thisLineRange.location != NSNotFound) {
        range = NSMakeRange(thisLineRange.location + 1, self.length - thisLineRange.location - 1);
        NSRange nextLineRange = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:range];
        
        if (nextLineRange.location != NSNotFound) {
            NSRange lineRange = NSMakeRange(thisLineRange.location + 1, NSMaxRange(nextLineRange) - NSMaxRange(thisLineRange));
            if (lineRange.location < [self length] && NSMaxRange(lineRange) < [self length]) {
                line = [self substringWithRange:lineRange];
                return [[VVTextResult alloc] initWithRange:lineRange string:line];
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

-(VVTextResult *) vv_textResultUntilNextString:(NSString *)findString currentLocation:(NSInteger)location
{
    NSInteger curseLocation = location;
    
    NSRange range = NSMakeRange(curseLocation, self.length - curseLocation);
    NSRange nextLineRange = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:range];
    NSRange rangeToString = [self rangeOfString:findString options:0 range:range];
    
    NSString *line = nil;
    if (nextLineRange.location != NSNotFound && rangeToString.location != NSNotFound && nextLineRange.location <= rangeToString.location) {
        NSRange lineRange = NSMakeRange(nextLineRange.location + 1, rangeToString.location - nextLineRange.location);
        if (lineRange.location < [self length] && NSMaxRange(lineRange) < [self length]) {
            line = [self substringWithRange:lineRange];
            return [[VVTextResult alloc] initWithRange:lineRange string:line];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

-(VVTextResult *) vv_textResultMatchPartWithPairOpenString:(NSString *)open
                                            closeString:(NSString *)close
                                        currentLocation:(NSInteger)location
{
    return [self textResultWithPairOpenString:open closeString:close currentLocation:location extractMatch:YES];
}

-(VVTextResult *) vv_textResultWithPairOpenString:(NSString *)open
                                   closeString:(NSString *)close
                               currentLocation:(NSInteger)location
{
    return [self textResultWithPairOpenString:open closeString:close currentLocation:location extractMatch:NO];
}

-(VVTextResult *) textResultWithPairOpenString:(NSString *)open
                                   closeString:(NSString *)close
                               currentLocation:(NSInteger)location
                                  extractMatch:(BOOL)extract
{
    // Find all content from current positon to the last paired scope. Useful when pairing `{}` or `()`
    NSInteger curseLocation = location;
    
    NSRange range = NSMakeRange(curseLocation, self.length - curseLocation);
    
    // searchRange will be updated to new range later, for search the next open/close token.
    NSRange searchRange = range;
    
    NSInteger openCount = 0;
    NSInteger closeCount = 0;
    
    NSRange nextOpenRange = [self rangeOfString:open options:0 range:searchRange];
    NSRange nextCloseRange = [self rangeOfString:close options:0 range:searchRange];
    
    NSRange firstOpenRange = nextOpenRange;
    
    // Not even open. Early return
    if (nextOpenRange.location == NSNotFound || nextCloseRange.location == NSNotFound || nextCloseRange.location < nextOpenRange.location) {
        return nil;
    }
    
    openCount++;
    
    // Update the search range: from current token to the end.
    searchRange = NSMakeRange(nextOpenRange.location + 1, self.length - nextOpenRange.location - 1);
    
    // Try to find the scope by pairing open and close count
    NSRange targetRange = NSMakeRange(0,0);
    while (openCount != closeCount) {
        // Get next open and close token location
        nextOpenRange = [self rangeOfString:open options:0 range:searchRange];
        nextCloseRange = [self rangeOfString:close options:0 range:searchRange];
        
        // No new close token. This scope will not close.
        if (nextCloseRange.location == NSNotFound) {
            return nil;
        }
        
        if (nextOpenRange.location < nextCloseRange.location) {
            targetRange = nextOpenRange;
            openCount++;
        } else {
            targetRange = nextCloseRange;
            closeCount++;
        }
        
        // Update the search range: from current token to the end.
        searchRange = NSMakeRange(targetRange.location + 1, self.length - targetRange.location - 1);
    }
    
    NSRange resultRange;
    if (extract) {
        resultRange = NSMakeRange(firstOpenRange.location, targetRange.location - firstOpenRange.location + 1);
    } else {
        // Extract the code need to be documented. From next line to the matched scope end.
        NSRange nextLineRange = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:range];
        resultRange = NSMakeRange(nextLineRange.location + 1, targetRange.location - nextLineRange.location);
    }
    
    if (resultRange.location < [self length] && NSMaxRange(resultRange) < [self length]) {
        NSString *result = [self substringWithRange:resultRange];
        return [[VVTextResult alloc] initWithRange:resultRange string:result];
    } else {
        return nil;
    }
    
}
@end
