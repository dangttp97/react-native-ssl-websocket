#import "SslWebsocket.h"
#import <React/RCTEventEmitter.h>

@interface SslWebsocket() <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property (nonatomic, strong) NSString *expectedPublicKey;
@end

@implementation SslWebsocket
RCT_EXPORT_MODULE()

// Example method
// See // https://reactnative.dev/docs/native-modules-ios
RCT_EXPORT_METHOD(connect:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSString *urlString = options[@"url"];
    NSString *publicKey = options[@"publicKey"];
    if (!urlString || !publicKey) {
        reject(@"invalid_args", @"url and publicKey are required", nil);
        return;
    }
    self.expectedPublicKey = publicKey;
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    self.webSocketTask = [session webSocketTaskWithURL:url];
    [self.webSocketTask resume];
    resolve(nil);
}

RCT_EXPORT_METHOD(connectTest:(NSString *)urlString
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if (!urlString) {
        reject(@"invalid_args", @"url is required", nil);
        return;
    }
    
    NSLog(@"🔗 iOS: Starting test connection to %@", urlString);
    
    // Test connection without SSL pinning
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    self.webSocketTask = [session webSocketTaskWithURL:url];
    [self.webSocketTask resume];
    resolve(nil);
}

- (void)URLSession:(NSURLSession *)session
        didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
          completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0);
    SecKeyRef publicKey = SecCertificateCopyKey(serverCert);
    if (publicKey) {
        CFDataRef keyData = SecKeyCopyExternalRepresentation(publicKey, NULL);
        if (keyData) {
            NSData *data = (__bridge NSData *)keyData;
            NSString *serverKeyBase64 = [data base64EncodedStringWithOptions:0];
            if ([serverKeyBase64 isEqualToString:self.expectedPublicKey]) {
                NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            } else {
                NSString *errorMsg = @"Public key pinning failure";
                [self sendEventWithName:@"SslWebsocketOnError" data:errorMsg];
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
            CFRelease(keyData);
        } else {
            NSString *errorMsg = @"Failed to extract public key data";
            [self sendEventWithName:@"SslWebsocketOnError" data:errorMsg];
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
        CFRelease(publicKey);
    } else {
        NSString *errorMsg = @"Failed to extract public key";
        [self sendEventWithName:@"SslWebsocketOnError" data:errorMsg];
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"SslWebsocketOnOpen", @"SslWebsocketOnMessage", @"SslWebsocketOnError", @"SslWebsocketOnClose"];
}

- (void)sendEventWithName:(NSString *)name data:(id)data {
  [self sendEventWithName:name body:@{ @"data": data ?: [NSNull null] }];
}

RCT_EXPORT_METHOD(send:(NSString *)message
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (self.webSocketTask) {
    NSURLSessionWebSocketMessage *msg = [[NSURLSessionWebSocketMessage alloc] initWithString:message];
    [self.webSocketTask sendMessage:msg completionHandler:^(NSError * _Nullable error) {
      if (error) {
        [self sendEventWithName:@"SslWebsocketOnError" data:error.localizedDescription];
        reject(@"send_error", error.localizedDescription, error);
      } else {
        resolve(@(YES));
      }
    }];
  } else {
    reject(@"not_connected", @"WebSocket is not connected", nil);
  }
}

RCT_EXPORT_METHOD(close:(NSInteger)code
                  reason:(NSString *)reason
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (self.webSocketTask) {
    [self.webSocketTask cancelWithCloseCode:code reason:[reason dataUsingEncoding:NSUTF8StringEncoding]];
    self.webSocketTask = nil;
    resolve(nil);
  } else {
    reject(@"not_connected", @"WebSocket is not connected", nil);
  }
}

// WebSocket event handlers
- (void)listenForMessages {
  if (!self.webSocketTask) return;
  [self.webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
    if (error) {
      [self sendEventWithName:@"SslWebsocketOnError" data:error.localizedDescription];
      self.webSocketTask = nil;
      return;
    }
    if (message) {
      if (message.type == NSURLSessionWebSocketMessageTypeString) {
        [self sendEventWithName:@"SslWebsocketOnMessage" data:message.string];
      }
      // Binary message có thể xử lý thêm nếu cần
    }
    [self listenForMessages];
  }];
}

// Gọi listenForMessages khi kết nối thành công
- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *)protocol {
  NSLog(@"🔗 iOS: WebSocket opened, emitting SslWebsocketOnOpen event");
  [self sendEventWithName:@"SslWebsocketOnOpen" data:nil];
  [self listenForMessages];
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason {
  NSString *reasonStr = reason ? [[NSString alloc] initWithData:reason encoding:NSUTF8StringEncoding] : @"";
  NSLog(@"🔒 iOS: WebSocket closed with code %ld, reason: %@", (long)closeCode, reasonStr);
  [self sendEventWithName:@"SslWebsocketOnClose" data:reasonStr];
  self.webSocketTask = nil;
}

RCT_EXPORT_METHOD(testEventEmitter:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"🧪 iOS: Testing event emitter manually");
    [self sendEventWithName:@"SslWebsocketOnOpen" data:@"test_event"];
    resolve(@"Event emitted");
}

- (void)addListener:(NSString *)eventName {
  NSLog(@"🔗 iOS: Adding listener for event: %@", eventName);
}
- (void)removeListeners:(double)count {
  NSLog(@"🔗 iOS: Removing listeners: %f", count);
} 

// Optional: báo cho RN rằng module này cần giữ kết nối
+ (BOOL)requiresMainQueueSetup {
  return YES;
}

@end
