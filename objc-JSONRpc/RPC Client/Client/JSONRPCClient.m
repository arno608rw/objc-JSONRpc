//
//  RPCJSONClient.m
//  objc-JSONRpc
//
//  Created by Rasmus Styrk on 8/28/12.
//  Copyright (c) 2012 Rasmus Styrk. All rights reserved.
//

#import "JSONRPCClient.h"
#import "JSONKit.h"

@implementation JSONRPCClient

@synthesize serviceEndpoint = _serviceEndpoint;
@synthesize requests = _requests;
@synthesize requestData = _requestData;

- (id) initWithServiceEndpoint:(NSString*) endpoint
{
    self = [super init];
    
    if(self)
    {
        self.serviceEndpoint = endpoint;
        self.requests = [[[NSMutableDictionary alloc] init] autorelease];
        self.requestData = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    return self;
}

- (void) dealloc
{
    [_serviceEndpoint release];
    [_requests release];
    [_requestData release];
    
    [super dealloc];
}

#pragma mark - Handle result

- (void) handleResult:(NSDictionary*)result
{
    NSString *requestId = [result objectForKey:@"id"];
    NSDictionary *error = [result objectForKey:@"error"];
    NSString *version = [result objectForKey:@"version"];
    
    if(requestId)
    {
        RPCRequest *request = [self.requests objectForKey:requestId];
        
        RPCResponse *response = [[RPCResponse alloc] init];
        response.id = requestId;
        response.version = version;
        
        if(error)
        {
            if(error != nil && [error isKindOfClass:[NSDictionary class]])
            {
                response.error = [[[RPCError alloc] initWithCode:[[error objectForKey:@"code"] intValue]
                                                         message:[error objectForKey:@"message"]
                                                            data:[error objectForKey:@"data"]] autorelease];
            }
        }
        else
            response.result = [result objectForKey:@"result"];
        
        if(request.callback)
            request.callback([response autorelease]);
        
        [self.requests removeObjectForKey:requestId];
    }
}

#pragma mark - URL Connection delegates -

- (void) postData:(NSData*)data
{
    NSMutableURLRequest *serviceRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.serviceEndpoint]];
    [serviceRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [serviceRequest setValue:@"objc-JSONRpc/1.0" forHTTPHeaderField:@"User-Agent"];
    
    [serviceRequest setValue:[NSString stringWithFormat:@"%i", data.length] forHTTPHeaderField:@"Content-Length"];
    [serviceRequest setHTTPMethod:@"POST"];
    [serviceRequest setHTTPBody:data];
    
#ifndef __clang_analyzer__
    NSURLConnection *serviceEndpointConnection = [[NSURLConnection alloc] initWithRequest:serviceRequest delegate:self];
#endif
    
    NSMutableData *rData = [[NSMutableData alloc] init];
    [self.requestData setObject:rData forKey:[NSNumber numberWithInt:(int)serviceEndpointConnection]];
    [rData release];
    [serviceRequest release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSMutableData *rdata = [self.requestData objectForKey: [NSNumber numberWithInt:(int)connection]];
    [rdata setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSMutableData *rdata = [self.requestData objectForKey: [NSNumber numberWithInt:(int)connection]];
    [rdata appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSMutableData *data = [self.requestData objectForKey: [NSNumber numberWithInt:(int)connection]];
    
    if(data.length > 0)
    {
        NSError *jsonError = nil;
        id result = [data objectFromJSONDataWithParseOptions:JKParseOptionNone error:&jsonError];
        
        if(jsonError != nil)
            NSLog(@"%@", [[RPCError alloc] initWithCode:RPCParseError]);
        else if(!result)
            NSLog(@"%@", [RPCError errorWithCode:RPCServerError]);
        else
        {
            // Single call
            if([result isKindOfClass:[NSDictionary class]])
                [self handleResult:result];
            // Multicall
            else if ([result isKindOfClass:[NSArray class]])
            {
                for(NSDictionary *r in result)
                    [self handleResult:r];
            }
            else
                NSLog(@"%@", [RPCError errorWithCode:RPCServerError]);
        }
    }
 
    [self.requestData removeObjectForKey: [NSNumber numberWithInt:(int)connection]];
    [connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", [RPCError errorWithCode:RPCNetworkError]);
    
    [self.requestData removeObjectForKey: [NSNumber numberWithInt:(int)connection]];
    [connection release];
}

@end















