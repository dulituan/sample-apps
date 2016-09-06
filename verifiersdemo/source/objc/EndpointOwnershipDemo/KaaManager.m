/**
 *  Copyright 2014-2016 CyberVision, Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#import "KaaManager.h"

@interface ConcreteClientStateDelegate () <KaaClientStateDelegate>

@end

@implementation ConcreteClientStateDelegate

- (void)onStarted{
    NSLog(@"Kaa client started");
}
- (void)onStartFailureWithException:(NSException *)exception {
    NSLog(@"Kaa client startup failure. %@", exception);
}
- (void)onPaused {
    NSLog(@"Kaa client paused");
}
- (void)onPauseFailureWithException:(NSException *)exception {
    NSLog(@"Kaa client pause failure. %@", exception);
}
- (void)onResume{
    NSLog(@"Kaa client resumed");
}
- (void)onResumeFailureWithException:(NSException *)exception {
    NSLog(@"Kaa client resume failure. %@", exception);
}
- (void)onStopped {
    NSLog(@"Kaa client stopped");
}
- (void)onStopFailureWithException:(NSException *)exception {
    NSLog(@"Kaa client stop failure. %@", exception);
}

@end

@interface KaaManager () <ConfigurationDelegate>

@property (nonatomic, strong) volatile id<KaaClient> kaaClient;
@property (nonatomic, strong) KAAKaaVerifiersTokens *verifiersTokens;

@end

@implementation KaaManager

/**
 * Returns shared instance of KaaManager class.
 */

+ (KaaManager *)sharedInstance {
    static KaaManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[KaaManager alloc] init];
        manager.kaaClient = [KaaClientFactory clientWithContext:[[DefaultKaaPlatformContext alloc] init] stateDelegate:[[ConcreteClientStateDelegate alloc] init]];
        manager.verifiersTokens = [manager.kaaClient getConfiguration];
    });
    return manager;
}

- (void)attachUser:(User *)user delegate:(id<UserAttachDelegate>)delegate {
    NSLog(@"Attaching user...");
    [self.kaaClient attachUserWithVerifierToken:[self getKaaVerifiersTokenForUser:user] userId:user.userId accessToken:user.token delegate:delegate];
}

/**
 * Detach the endpoint from the user.
 */

- (void)detachEndpoitWithDelegate:(id<OnDetachEndpointOperationDelegate>)delegate {
    NSLog(@"Detaching endpoint with key hash %@", [self.kaaClient getEndpointKeyHash]);
    EndpointKeyHash *keyHash = [[EndpointKeyHash alloc] initWithKeyHash:[self.kaaClient getEndpointKeyHash]];
    [self.kaaClient detachEndpointWithKeyHash:keyHash delegate:delegate];
}

- (NSString *)getKaaVerifiersTokenForUser:(User *)user {
    switch (user.network) {
        case AuthorizedNetworkFacebook:
            return self.verifiersTokens.facebookKaaVerifierToken.data;
            break;
            
        case AuthorizedNetworkTwitter:
            return self.verifiersTokens.twitterKaaVerifierToken.data;
            break;
            
        case AuthorizedNetworkGoogle:
            return self.verifiersTokens.googleKaaVerifierToken.data;
            break;
            
        default:
            break;
    }
}

#pragma mark - ConfigurationDelegate

- (void)onConfigurationUpdate:(KAAKaaVerifiersTokens *)configuration {
    self.verifiersTokens = configuration;
}

@end
