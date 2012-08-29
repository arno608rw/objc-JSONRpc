//
//  RPCBaseClient.m
//  objc-JSONRpc
//
//  Created by Rasmus Styrk on 8/28/12.
//  Copyright (c) 2012 Rasmus Styrk. All rights reserved.
//

#import "BaseRPCClient.h"
#import "BaseRPCClient+InvokeMethods.h"

@implementation BaseRPCClient
@synthesize serviceEndpoint = _serviceEndpoint;
@synthesize connections = _connections;
@synthesize callbacks = _callbacks;

#pragma mark - Initializing

- (id) initWithServiceEndpoint:(NSString*) endpoint
{
    self = [super init];
    
    if(self)
    {
        self.serviceEndpoint = endpoint;
        self.connections = [[[NSMutableDictionary alloc] init] autorelease];
        self.callbacks = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    return self;
}

- (void) dealloc
{
    [_serviceEndpoint release];
    [_connections release];
    [_callbacks release];
    
    [super dealloc];
}

#pragma mark - Helper methods

- (NSData*) serializeRequest:(RPCRequest *)request error:(RPCError **) error
{
#if DEBUG
    NSLog(@"SerializeRequest is not handled.");
#endif

    *error = [RPCError errorWithCode:RPCInvalidParams];
    
    return [NSData data];
}

- (id) parseResult:(NSData*) data error:(RPCError **) error
{
#if DEBUG
    NSLog(@"parseResult is not handled.");
#endif
    
    *error = [RPCError errorWithCode:RPCParseError];
    
    return nil;
}

- (NSString*) contentType
{
#if DEBUG
    NSLog(@"contentType is not handled.");
#endif
    
    return @"";
}

#pragma mark - URL Connection delegates -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    RPCResponse *rpcresponse = [self.connections objectForKey: [NSNumber numberWithInt:(int)connection]];
    [rpcresponse.data setLength:0];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    RPCResponse *rpcresponse = [self.connections objectForKey: [NSNumber numberWithInt:(int)connection]];
    [rpcresponse.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    RPCResponse *rpcresponse = [self.connections objectForKey: [NSNumber numberWithInt:(int)connection]];
    RPCCompletedCallback callback = [self.callbacks objectForKey: [NSNumber numberWithInt:(int)connection]];
    
    RPCError *error = nil;
    id result = [self parseResult:rpcresponse.data error:&error];
    
    if(error != nil)
        rpcresponse.error = error;
    else
    {
        rpcresponse.error = nil;
        rpcresponse.result = result;
    }
        
    callback(rpcresponse);
    
    [self.connections removeObjectForKey: [NSNumber numberWithInt:(int)connection]];
    [self.callbacks removeObjectForKey: [NSNumber numberWithInt:(int)connection]];
    [connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    RPCResponse *rpcresponse = [self.connections objectForKey: [NSNumber numberWithInt:(int)connection]];
    RPCCompletedCallback callback = [self.callbacks objectForKey: [NSNumber numberWithInt:(int)connection]];
        
    rpcresponse.error = [RPCError errorWithCode:RPCNetworkError];
    callback(rpcresponse);
    
    [self.connections removeObjectForKey: [NSNumber numberWithInt:(int)connection]];
    [self.callbacks removeObjectForKey: [NSNumber numberWithInt:(int)connection]];
    [connection release];
}

@end
