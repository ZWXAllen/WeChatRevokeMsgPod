//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  WeChatRevokeMsgPod.m
//  WeChatRevokeMsgPod
//
//  Created by allen on 2017/8/4.
//  Copyright (c) 2017年 allen. All rights reserved.
//

#import "WeChatRevokeMsgPod.h"
#import "CaptainHook.h"
#import <UIKit/UIKit.h>

CHDeclareClass(CMessageMgr);



CHOptimizedMethod(1, self, void, CMessageMgr, onRevokeMsg, id, arg1){
    
    
    Ivar nsFromUsrIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsFromUsr");
    id m_nsFromUsr = object_getIvar(arg1, nsFromUsrIvar);
    
    Ivar nsContentIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsContent");
    NSString *m_nsContent = object_getIvar(arg1, nsContentIvar);
    
    Ivar nsToUsrIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsToUsr");
    NSString *m_nsToUsr = object_getIvar(arg1, nsToUsrIvar);
    
    
    
    if ([m_nsContent rangeOfString:@"<session>"].location == NSNotFound) { return; }
    if ([m_nsContent rangeOfString:@"<replacemsg>"].location == NSNotFound) { return; }
    
    NSString *(^parseSession)() = ^NSString *() {
        NSUInteger startIndex = [m_nsContent rangeOfString:@"<session>"].location + @"<session>".length;
        NSUInteger endIndex = [m_nsContent rangeOfString:@"</session>"].location;
        NSRange range = NSMakeRange(startIndex, endIndex - startIndex);
        return [m_nsContent substringWithRange:range];
    };
    
    NSString *(^parseSenderName)() = ^NSString *() {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<!\\[CDATA\\[(.*?)撤回了一条消息\\]\\]>" options:NSRegularExpressionCaseInsensitive error:nil];
        
        NSRange range = NSMakeRange(0, m_nsContent.length);
        NSTextCheckingResult *result = [regex matchesInString:m_nsContent options:0 range:range].firstObject;
        if (result.numberOfRanges < 2) { return nil; }
        
        return [m_nsContent substringWithRange:[result rangeAtIndex:1]];
    };
    
    id classCMessageWrap = [objc_getClass("CMessageWrap") performSelector:@selector(alloc)];;
    id msgWrap = [classCMessageWrap performSelector:@selector(initWithMsgType:) withObject:0x2710];
    
    
    [msgWrap performSelector:@selector(setM_nsFromUsr:) withObject:m_nsFromUsr];
    [msgWrap performSelector:@selector(setM_nsToUsr:) withObject:m_nsToUsr];
    
    NSString *name = parseSenderName();
    NSString *sendContent = [NSString stringWithFormat:@"%@ 想撤回消息并亲了你一口！", name ? name : m_nsFromUsr];
    
    
    Ivar nsuiCreateTimeIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_uiCreateTime");
    NSString *m_uiCreateTime = object_getIvar(arg1, nsuiCreateTimeIvar);
    
    [msgWrap performSelector:@selector(setM_uiStatus:) withObject:@(0x4)];
    [msgWrap performSelector:@selector(setM_nsContent:) withObject:sendContent];
    [msgWrap performSelector:@selector(setM_uiCreateTime:) withObject:m_uiCreateTime];
    
    
    [self AddLocalMsg:parseSession() MsgWrap:msgWrap fixTime:0x1 NewMsgArriveNotify:0x0];
}



//所有被hook的类和函数放在这里的构造函数中
CHConstructor
{
    @autoreleasepool
    {
        CHLoadLateClass(CMessageMgr);
        CHHook(1, CMessageMgr, onRevokeMsg);
        
    }
}

