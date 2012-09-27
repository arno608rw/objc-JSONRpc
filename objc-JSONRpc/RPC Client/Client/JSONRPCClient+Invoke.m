//
//  JSONRPCClient+Invoke.m
//  objc-JSONRpc
//
//  Created by Rasmus Styrk on 9/16/12.
//  Copyright (c) 2012 Rasmus Styrk. All rights reserved.
//

#import "JSONRPCClient+Invoke.h"

@implementation JSONRPCClient (Invoke)

- (NSString *) invoke:(RPCRequest*) request onCompleted:(RPCRequestCallback)callback
{
    request.callback =  callback;
    
    RPCError *error = nil;
    NSData *payload = [self serializeRequest:request error:&error];
    
    if(callback != nil && error != nil)
        callback([RPCResponse responseWithError:error]);
    else
    {
        NSMutableURLRequest *serviceRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.serviceEndpoint]];
        [serviceRequest setValue:[self contentType] forHTTPHeaderField:@"Content-Type"];
        [serviceRequest setValue:@"objc-JSONRpc/1.0" forHTTPHeaderField:@"User-Agent"];
        
        [serviceRequest setValue:[NSString stringWithFormat:@"%i", payload.length] forHTTPHeaderField:@"Content-Length"];
        [serviceRequest setHTTPMethod:@"POST"];
        [serviceRequest setHTTPBody:payload];
        
#ifndef __clang_analyzer__
        NSURLConnection *serviceEndpointConnection = [[NSURLConnection alloc] initWithRequest:serviceRequest delegate:self];
#endif

        [self.requests setObject:request forKey:[NSNumber numberWithInt:(int)serviceEndpointConnection]];

        [serviceRequest release];
    }
    
    [callback release];
    
    return request.id;
}

- (NSString *) invoke:(NSString *)method params:(id)params onCompleted:(RPCRequestCallback)callback
{
    RPCRequest *request = [[RPCRequest alloc] init];
    request.method = method;
    request.params = params;
    
    if(request.id == nil)
        request.id = [[NSNumber numberWithInt:arc4random()] stringValue];
    
    return [self invoke:[request autorelease] onCompleted:callback];
}

- (NSString *) invoke:(NSString*) method params:(id) params onSuccess:(RPCSuccessCallback)successCallback onFailure:(RPCFailedCallback)failedCallback
{
    return [self invoke:method params:params onCompleted:^(RPCResponse *response) {
        
        if(response.error)
            failedCallback(response.error);
        else
            successCallback(response);
    }];
}
@end
