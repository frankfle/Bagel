//
// Copyright (c) 2018 Bagel (https://github.com/yagiz/Bagel)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BagelBrowser.h"
#import "BagelConfiguration.h"

@implementation BagelBrowser

- (instancetype)initWithConfiguration:(BagelConfiguration*)configuration
{
    self = [super init];

    if (self) {
        self.configuration = configuration;
        self.connections = [[NSMutableArray alloc] init];
        self.readyConnections = [[NSMutableArray alloc] init];
        [self startBrowsing];
    }

    return self;
}

- (void)startBrowsing
{
    if (self.connections) {
        [self.connections removeAllObjects];
    } else {
        self.connections = [[NSMutableArray alloc] init];
    }

    if (self.readyConnections) {
        [self.readyConnections removeAllObjects];
    } else {
        self.readyConnections = [[NSMutableArray alloc] init];
    }

    if (self.services) {
        [self.services removeAllObjects];
    } else {
        self.services = [[NSMutableArray alloc] init];
    }

    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [self.serviceBrowser setDelegate:self];
#if TARGET_OS_SIMULATOR || TARGET_OS_OSX
    [self connectToLocal];
#else
    [self.serviceBrowser searchForServicesOfType:self.configuration.netserviceType inDomain:self.configuration.netserviceDomain];
#endif
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)serviceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing
{
    [self.services addObject:service];

    [service setDelegate:self];
    [service resolveWithTimeout:30.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)serviceBrowser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing
{
    [self.services removeObject:service];
}

- (void)netServiceDidResolveAddress:(NSNetService*)service
{
    [self connectWithService:service];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *,NSNumber *> *)errorDict
{
    NSLog(@"netService didNotResolve - %@", errorDict);
}

- (BOOL)connectToLocal
{
    nw_endpoint_t endpoint = nw_endpoint_create_host("127.0.0.1", "43435");
    nw_parameters_t parameters = nw_parameters_create_secure_tcp(
        NW_PARAMETERS_DISABLE_PROTOCOL,
        NW_PARAMETERS_DEFAULT_CONFIGURATION
    );

    nw_connection_t connection = nw_connection_create(endpoint, parameters);
    [self startConnection:connection];

    return YES;
}

- (BOOL)connectWithService:(NSNetService*)service
{
    NSString* host = [service hostName];
    NSString* port = [NSString stringWithFormat:@"%ld", (long)[service port]];

    if (!host) {
        return NO;
    }

    nw_endpoint_t endpoint = nw_endpoint_create_host([host UTF8String], [port UTF8String]);
    nw_parameters_t parameters = nw_parameters_create_secure_tcp(
        NW_PARAMETERS_DISABLE_PROTOCOL,
        NW_PARAMETERS_DEFAULT_CONFIGURATION
    );

    nw_connection_t connection = nw_connection_create(endpoint, parameters);
    [self startConnection:connection];

    return YES;
}

- (void)startConnection:(nw_connection_t)connection
{
    [self.connections addObject:connection];

    __weak typeof(self) weakSelf = self;

    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
        if (state == nw_connection_state_ready) {
            if (![weakSelf.readyConnections containsObject:connection]) {
                [weakSelf.readyConnections addObject:connection];
            }
        } else if (state == nw_connection_state_failed || state == nw_connection_state_cancelled) {
            [weakSelf removeConnection:connection];
        }
    });

    nw_connection_set_queue(connection, dispatch_get_main_queue());
    nw_connection_start(connection);
}

- (void)removeConnection:(nw_connection_t)connection
{
    nw_connection_cancel(connection);
    [self.connections removeObject:connection];
    [self.readyConnections removeObject:connection];
}

- (void)sendPacket:(BagelRequestPacket*)packet
{
    NSError *error;
    NSData* packetData = [NSJSONSerialization dataWithJSONObject:[packet toJSON] options:0 error:&error];

    if (error) {
        NSLog(@"Bagel -> Error: %@", error.localizedDescription);
        return;
    }

    if (packetData) {

        NSMutableData* buffer = [[NSMutableData alloc] init];

        uint64_t headerLength = [packetData length];
        [buffer appendBytes:&headerLength length:sizeof(uint64_t)];
        [buffer appendBytes:[packetData bytes] length:[packetData length]];

        dispatch_data_t sendData = dispatch_data_create(
            [buffer bytes],
            [buffer length],
            dispatch_get_main_queue(),
            DISPATCH_DATA_DESTRUCTOR_DEFAULT
        );

        for (nw_connection_t connection in self.readyConnections) {
            nw_connection_send(connection, sendData, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, false, ^(nw_error_t error) {
                if (error) {
                    NSLog(@"Bagel -> Send error: %@", error);
                }
            });
        }

    }
}

- (void)socketDidDisconnect:(nw_connection_t)connection withError:(NSError*)error
{
    [self removeConnection:connection];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)aBrowser didNotSearch:(NSDictionary*)userInfo
{
    [self resetAndBrowse];
}

- (void)resetAndBrowse
{
    [self.serviceBrowser stop];
    self.serviceBrowser = nil;

    [self startBrowsing];
}

@end
