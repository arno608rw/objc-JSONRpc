//
//  AppDelegate.m
//  objc-JSONRpc
//
//  Created by Rasmus Styrk on 8/28/12.
//  Copyright (c) 2012 Rasmus Styrk. All rights reserved.
//

#import "AppDelegate.h"
#import "JSONRPCClient.h"

@implementation AppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Standard stuff
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    
    // RPC Test
    JSONRPCClient *rpc = [[JSONRPCClient alloc] initWithServiceEndpoint:@"http://weatherwatchapp.com/api/index.php"];
    [rpc invoke:@"updateClientWatch" params:nil onCompleted:^(RPCResponse *response) {
        
        NSLog(@"Respone: %@", response);
        NSLog(@"Error: %@", response.error);
        NSLog(@"Result: %@", response.result);
        
    }];
    
    [rpc invoke:@"getClientWatches" params:nil onSuccess:^(RPCResponse *response) {
        
        NSLog(@"Respone: %@", response);
        NSLog(@"Result: %@", response.result);
                                    
                                    
     } onFailure:^(RPCError *error) {
                                    
        NSLog(@"Error: %@", error);
         
    }];
    
    
    [rpc release];
    
    
    return YES;
}

@end
