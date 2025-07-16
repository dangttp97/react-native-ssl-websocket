#import "URLSessionHandler.h"
#import "CryptographyUtils.h"

@interface URLSessionHandler() <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property (nonatomic, strong) NSString *expectedPublicKey;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, strong) NSTimer *retryTimer;
@property (nonatomic, weak) id<URLSessionHandlerDelegate> delegate;
@end

@implementation URLSessionHandler

- (instancetype)initWithURL:(NSString *)url publicKey:(NSString *)publicKey delegate:(id<URLSessionHandlerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.urlString = url;
        self.expectedPublicKey = publicKey;
        self.delegate = delegate;
        self.retryCount = 0;
        self.retryTimer = nil;
        self.webSocketTask = nil;
    }
    return self;
}

/**
 * Establish WebSocket connection with SSL pinning
 */
- (void)connectWebSocket
{
  NSLog(@"🔗 iOS: Establishing WebSocket connection to: %@", self.urlString);
  
  NSURL *url = [NSURL URLWithString:self.urlString];
  if (!url) {
    NSLog(@"❌ iOS: Invalid URL: %@", self.urlString);
    [self.delegate onError:@"Invalid URL"];
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
    [self.delegate onError:@"Max retry attempts reached"];
    return;
  }
  
  self.retryCount++;
  NSTimeInterval delay = MIN(1000.0 * self.retryCount, 10000.0) / 1000.0; // Max 10 seconds
  
  NSLog(@"🔄 iOS: Retrying connection in %.1f seconds (attempt %ld)", delay, (long)self.retryCount);
  
  self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(connectWebSocket) userInfo:nil repeats:NO];
}

#pragma mark - URLSession methods

- (void) send:(NSString *) message{
  if (!self.webSocketTask) {
    NSLog(@"❌ iOS: Cannot send message - WebSocket not connected");
    [self.delegate onError:@"WebSocket not connected"];
    return;
  }
  
  NSLog(@"📤 iOS: Sending message: %@", message);
  
  NSURLSessionWebSocketMessage *msg = [[NSURLSessionWebSocketMessage alloc] initWithString:message];
  [self.webSocketTask sendMessage:msg completionHandler:^(NSError * _Nullable error) {
    if (error) {
      NSLog(@"❌ iOS: Failed to send message: %@", error.localizedDescription);
      [self.delegate onError:error.localizedDescription];
    } else {
      NSLog(@"✅ iOS: Message sent successfully");
    }
  }];
}

-(void) close{
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
  
  [self.delegate onClosed:nil];
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
  
  // Lấy public key bằng CryptographyUtils
  SecKeyRef publicKey = [CryptographyUtils publicKeyFromCertificate:serverCert];
  if (!publicKey) {
    NSLog(@"❌ iOS: Failed to extract public key");
    [self.delegate onError:@"Failed to extract public key"];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    return;
  }
  // Lấy raw key
  CFErrorRef error = NULL;
  CFDataRef publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error);
  if (!publicKeyData) {
    NSLog(@"❌ iOS: Cannot extract raw public key: %@", error);
    [self.delegate onError:@"Failed to extract raw public key"];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    CFRelease(publicKey);
    return;
  }
  NSData *rawKey = (__bridge NSData *)publicKeyData;
  // SHA256 hash bằng CryptographyUtils
  NSData *hashData = [CryptographyUtils sha256FromData:rawKey];
  NSString *serverKeyHashBase64 = [CryptographyUtils base64FromData:hashData];
  NSLog(@"🔐 iOS: Server SPKI SHA256 base64: %@", serverKeyHashBase64);
  NSLog(@"🔐 iOS: Expected SPKI SHA256 base64: %@", self.expectedPublicKey);
  
  // So sánh cert bằng CryptographyUtils
  if ([CryptographyUtils compareCertificate:serverCert withExpectedBase64:self.expectedPublicKey]) {
    NSLog(@"✅ iOS: Public key pinning successful (SPKI match)");
    NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
  } else {
    NSLog(@"❌ iOS: Public key pinning failed");
    [self.delegate onError:@"Public key pinning failure"];
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
  
  [self.delegate onOpen];
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
  [self.delegate onClosed:@{@"code": @(closeCode), @"reason": reasonStr ?: @""}];
}

/**
 * Handle WebSocket connection failure
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  if (error) {
    NSLog(@"❌ iOS: WebSocket connection failed: %@", error.localizedDescription);
    [self.delegate onError:error.localizedDescription];
    
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
      [self.delegate onError:error.localizedDescription];
      self.webSocketTask = nil;
      return;
    }
    
    if (message) {
      if (message.type == NSURLSessionWebSocketMessageTypeString) {
        NSLog(@"📨 iOS: Received message: %@", message.string);
        [self.delegate onMessage:message.string];
      } else if (message.type == NSURLSessionWebSocketMessageTypeData) {
        NSLog(@"📨 iOS: Received binary message");
        NSString *base64Data = [CryptographyUtils base64FromData:message.data];
        [self.delegate onMessage:base64Data];
      }
    }
    
    // Continue listening for more messages
    [self listenForMessages];
  }];
}

@end
