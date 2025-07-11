#import "SslWebsocket.h"
#import <React/RCTEventEmitter.h>
#import <CommonCrypto/CommonDigest.h>

@interface SslWebsocket() <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property (nonatomic, strong) NSString *expectedPublicKey;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, strong) NSTimer *retryTimer;
@property BOOL hasListeners;
@end

@implementation SslWebsocket

RCT_EXPORT_MODULE()

#pragma mark - React Native Module Methods

/**
 * Connect to WebSocket server with SSL pinning
 * @param url WebSocket server URL
 * @param publicKey Expected public key in base64 format for SSL pinning
 */
RCT_EXPORT_METHOD(connect:(NSString *)url publicKey:(NSString *)publicKey)
{
  NSLog(@"🔗 iOS: Connecting to WebSocket server: %@", url);
  
  if (!url || !publicKey) {
    NSLog(@"❌ iOS: Invalid arguments - url and publicKey are required");
    [self sendEventWithName:@"onError" data:@"Invalid arguments - url and publicKey are required"];
    return;
  }
  
  self.urlString = url;
  self.expectedPublicKey = publicKey;
  self.retryCount = 0;
  
  [self connectWebSocket];
}

/**
 * Send message to WebSocket server
 * @param message Message to send (will be converted to JSON if needed)
 */
RCT_EXPORT_METHOD(send:(NSString *)message)
{
  if (!self.webSocketTask) {
    NSLog(@"❌ iOS: Cannot send message - WebSocket not connected");
    [self sendEventWithName:@"onError" data:@"WebSocket not connected"];
    return;
  }
  
  NSLog(@"📤 iOS: Sending message: %@", message);
  
  NSURLSessionWebSocketMessage *msg = [[NSURLSessionWebSocketMessage alloc] initWithString:message];
  [self.webSocketTask sendMessage:msg completionHandler:^(NSError * _Nullable error) {
    if (error) {
      NSLog(@"❌ iOS: Failed to send message: %@", error.localizedDescription);
      [self sendEventWithName:@"onError" data:error.localizedDescription];
    } else {
      NSLog(@"✅ iOS: Message sent successfully");
    }
  }];
}

/**
 * Close WebSocket connection
 */
RCT_EXPORT_METHOD(close)
{
  NSLog(@"🔒 iOS: Closing WebSocket connection");
  
  if (self.webSocketTask) {
    [self.webSocketTask cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:[@"Normal closure" dataUsingEncoding:NSUTF8StringEncoding]];
    self.webSocketTask = nil;
  }
  
  // Cancel retry timer if active
  if (self.retryTimer) {
    [self.retryTimer invalidate];
    self.retryTimer = nil;
  }
  
  [self sendEventWithName:@"onClosed" data:nil];
}

/**
 * Add event listener (for React Native event emitter compatibility)
 */
RCT_EXPORT_METHOD(addListener:(NSString *)eventName)
{
  NSLog(@"👂 iOS: Adding listener for event: %@", eventName);
}

/**
 * Remove event listeners (for React Native event emitter compatibility)
 */
RCT_EXPORT_METHOD(removeListeners:(double)count)
{
  NSLog(@"👂 iOS: Removing %f listeners", count);
}

#pragma mark - WebSocket Connection Management

/**
 * Establish WebSocket connection with SSL pinning
 */
- (void)connectWebSocket
{
  NSLog(@"🔗 iOS: Establishing WebSocket connection to: %@", self.urlString);
  
  NSURL *url = [NSURL URLWithString:self.urlString];
  if (!url) {
    NSLog(@"❌ iOS: Invalid URL: %@", self.urlString);
    [self sendEventWithName:@"onError" data:@"Invalid URL"];
    return;
  }
  
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
  self.webSocketTask = [session webSocketTaskWithURL:url];
  [self.webSocketTask resume];
}

/**
 * Handle connection retry with exponential backoff
 */
- (void)retryConnection
{
  if (self.retryCount >= 5) {
    NSLog(@"❌ iOS: Max retry attempts reached");
    [self sendEventWithName:@"onError" data:@"Max retry attempts reached"];
    return;
  }
  
  self.retryCount++;
  NSTimeInterval delay = MIN(1000.0 * self.retryCount, 10000.0) / 1000.0; // Max 10 seconds
  
  NSLog(@"🔄 iOS: Retrying connection in %.1f seconds (attempt %ld)", delay, (long)self.retryCount);
  
  self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(connectWebSocket) userInfo:nil repeats:NO];
}

#pragma mark - SSL Certificate Pinning

/**
 * Handle SSL certificate challenge with public key pinning
 */
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
  NSLog(@"🔐 iOS: Handling SSL certificate challenge");
  
  SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
  SecCertificateRef serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0);
  
  CFIndex certCount = SecTrustGetCertificateCount(serverTrust);
  for (CFIndex i = 0; i < certCount; i++) {
    SecCertificateRef cert = SecTrustGetCertificateAtIndex(serverTrust, i);
    CFStringRef summary = SecCertificateCopySubjectSummary(cert);
    NSLog(@"🔎 iOS: Cert %ld: %@", (long)i, summary);
    CFRelease(summary);
  }
  
  SecKeyRef publicKey = SecCertificateCopyKey(serverCert);
  if (!publicKey) {
    NSLog(@"❌ iOS: Failed to extract public key");
    [self sendEventWithName:@"onError" data:@"Failed to extract public key"];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    return;
  }
  
  CFErrorRef error = NULL;
  CFDataRef publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error);
  if (!publicKeyData) {
    NSLog(@"❌ iOS: Cannot extract raw public key: %@", error);
    [self sendEventWithName:@"onError" data:@"Failed to extract raw public key"];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    CFRelease(publicKey);
    return;
  }
  
  NSData *rawKey = (__bridge NSData *)publicKeyData;
  
  // Prefix cho RSA 2048 (nếu server dùng RSA)
  const unsigned char rsa2048SPKIPrefix[] = {
    0x30, 0x82, 0x01, 0x22,  // SEQUENCE
    0x30, 0x0d,
    0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01,  // OID: rsaEncryption
    0x05, 0x00,             // NULL
    0x03, 0x82, 0x01, 0x0f, 0x00  // BIT STRING (unused bits = 0)
  };
  
  NSMutableData *spkiData = [NSMutableData dataWithBytes:rsa2048SPKIPrefix length:sizeof(rsa2048SPKIPrefix)];
  [spkiData appendData:rawKey];
  
  // SHA256
  uint8_t hash[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(spkiData.bytes, (CC_LONG)spkiData.length, hash);
  NSData *hashData = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
  NSString *serverKeyHashBase64 = [hashData base64EncodedStringWithOptions:0];
  
  NSLog(@"🔐 iOS: Server SPKI SHA256 base64: %@", serverKeyHashBase64);
  NSLog(@"🔐 iOS: Expected SPKI SHA256 base64: %@", self.expectedPublicKey);
  
  if ([serverKeyHashBase64 isEqualToString:self.expectedPublicKey]) {
    NSLog(@"✅ iOS: Public key pinning successful (SPKI match)");
    NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
  } else {
    NSLog(@"❌ iOS: Public key pinning failed");
    [self sendEventWithName:@"onError" data:@"Public key pinning failure"];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
  }
  
  CFRelease(publicKeyData);
  CFRelease(publicKey);
  
}


#pragma mark - WebSocket Event Handlers

/**
 * Handle WebSocket connection opened
 */
- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *)protocol
{
  NSLog(@"✅ iOS: WebSocket connection opened successfully");
  self.retryCount = 0; // Reset retry count on successful connection
  
  [self sendEventWithName:@"onOpen" data:nil];
  [self listenForMessages];
}

/**
 * Handle WebSocket connection closed
 */
- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason
{
  NSString *reasonStr = reason ? [[NSString alloc] initWithData:reason encoding:NSUTF8StringEncoding] : @"";
  NSLog(@"🔒 iOS: WebSocket closed with code %ld, reason: %@", (long)closeCode, reasonStr);
  
  self.webSocketTask = nil;
  [self sendEventWithName:@"onClosed" data:@{@"code": @(closeCode), @"reason": reasonStr ?: @""}];
}

/**
 * Handle WebSocket connection failure
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  if (error) {
    NSLog(@"❌ iOS: WebSocket connection failed: %@", error.localizedDescription);
    [self sendEventWithName:@"onError" data:error.localizedDescription];
    
    // Retry connection if it's a network error
    if (error.code == NSURLErrorNetworkConnectionLost ||
        error.code == NSURLErrorTimedOut ||
        error.code == NSURLErrorCannotConnectToHost) {
      [self retryConnection];
    }
  }
}

/**
 * Listen for incoming WebSocket messages
 */
- (void)listenForMessages
{
  if (!self.webSocketTask) {
    NSLog(@"❌ iOS: Cannot listen for messages - WebSocket not connected");
    return;
  }
  
  [self.webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
    if (error) {
      NSLog(@"❌ iOS: Error receiving message: %@", error.localizedDescription);
      [self sendEventWithName:@"onError" data:error.localizedDescription];
      self.webSocketTask = nil;
      return;
    }
    
    if (message) {
      if (message.type == NSURLSessionWebSocketMessageTypeString) {
        NSLog(@"📨 iOS: Received message: %@", message.string);
        [self sendEventWithName:@"onMessage" data:message.string];
      } else if (message.type == NSURLSessionWebSocketMessageTypeData) {
        NSLog(@"📨 iOS: Received binary message");
        NSString *base64Data = [message.data base64EncodedStringWithOptions:0];
        [self sendEventWithName:@"onMessage" data:base64Data];
      }
    }
    
    // Continue listening for more messages
    [self listenForMessages];
  }];
}

#pragma mark - Event Emitter

/**
 * Supported events for React Native
 */
- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onOpen", @"onMessage", @"onError", @"onClosed"];
}

- (void)startObserving {
  self.hasListeners = YES;
}

- (void)stopObserving {
  self.hasListeners = NO;
}

/**
 * Send event to React Native with proper data format
 */
- (void)sendEventWithName:(NSString *)name data:(id)data
{
  if (!self.hasListeners) {
    NSLog(@"⚠️ iOS: Tried to emit '%@' but no JS listeners are attached yet", name);
    [self sendEventWithName:name body:nil];
    return;
  }
  
  NSLog(@"📡 iOS: Emitting event '%@' with data: %@", name, data);
  
  if (data) {
    [self sendEventWithName:name body:@{@"data": data}];
  } else {
    [self sendEventWithName:name body:nil];
  }
}

#pragma mark - React Native Module Configuration

/**
 * Indicate that this module requires main queue setup
 */
+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
