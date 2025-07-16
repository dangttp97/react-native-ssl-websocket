#import "SslWebsocket.h"
#import "CryptographyUtils.h"
#import "URLSessionHandler.h"
#import <Foundation/Foundation.h>

@interface SslWebsocket() <URLSessionHandlerDelegate>
@property (nonatomic, strong) URLSessionHandler *handler;
@property (nonatomic, assign) BOOL hasListeners;
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
    [self sendEventWithName:@"onError" body:@{@"data": @"Invalid arguments - url and publicKey are required"}];
    return;
  }

  self.handler = [[URLSessionHandler alloc] initWithURL:url publicKey:publicKey delegate:self];
  [self.handler connectWebSocket];
}

/**
 * Send message to WebSocket server
 * @param message Message to send (will be converted to JSON if needed)
 */
RCT_EXPORT_METHOD(send:(NSString *)message)
{
  [self.handler send:message];
}

/**
 * Close WebSocket connection
 */
RCT_EXPORT_METHOD(close)
{
  [self.handler close];
}

///**
// * Add event listener (for React Native event emitter compatibility)
// */
//RCT_EXPORT_METHOD(addListener:(NSString *)eventName)
//{
//  NSLog(@"👂 iOS: Adding listener for event: %@", eventName);
//  if (!self.hasListeners) {
//    [self startObserving];
//  }
//}
//
///**
// * Remove event listeners (for React Native event emitter compatibility)
// */
//RCT_EXPORT_METHOD(removeListeners:(double)count)
//{
//  NSLog(@"👂 iOS: Removing %f listeners", count);
//  if (self.hasListeners) {
//    [self stopObserving];
//  }
//}

#pragma mark - URLSessionHandlerDelegate

// Helper function to convert object to JSON string
- (NSString *)jsonStringFromObject:(id)obj {
  if (!obj) return @"";
  if ([obj isKindOfClass:[NSString class]]) return obj;
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];
  if (!jsonData || error) {
    NSLog(@"❌ iOS: Failed to serialize JSON: %@", error);
    return @"";
  }
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)onOpen {
  NSLog(@"✅ iOS: WebSocket opened via delegate");
  if (self.hasListeners) {
    [self sendEventWithName:@"onOpen" body:[self jsonStringFromObject:@{}]];
  } else {
    NSLog(@"⚠️ iOS: onOpen event but no listeners registered");
  }
}

- (void)onMessage:(NSString *)message {
  NSLog(@"📨 iOS: Received message via delegate: %@", message);
  if (self.hasListeners) {
    [self sendEventWithName:@"onMessage" body:[self jsonStringFromObject:message]];
  } else {
    NSLog(@"⚠️ iOS: onMessage event but no listeners registered");
  }
}

- (void)onError:(NSString *)error {
  NSLog(@"❌ iOS: Error via delegate: %@", error);
  if (self.hasListeners) {
    [self sendEventWithName:@"onError" body:[self jsonStringFromObject:error]];
  } else {
    NSLog(@"⚠️ iOS: onError event but no listeners registered");
  }
}

- (void)onClosed:(NSDictionary *)data {
  NSLog(@"🔒 iOS: WebSocket closed via delegate");
  if (self.hasListeners) {
    [self sendEventWithName:@"onClosed" body:[self jsonStringFromObject:data]];
  } else {
    NSLog(@"⚠️ iOS: onClosed event but no listeners registered");
  }
}

#pragma mark - React Native Module Configuration

/**
 * Start observing events (called when JS adds listeners)
 */
- (void)startObserving {
  self.hasListeners = YES;
  NSLog(@"👂 iOS: Started observing events");
}

/**
 * Stop observing events (called when JS removes listeners)
 */
- (void)stopObserving {
  self.hasListeners = NO;
  NSLog(@"👂 iOS: Stopped observing events");
}

/**
 * Supported events for React Native
 */
- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onOpen", @"onMessage", @"onError", @"onClosed", @"onClosing"];
}

/**
 * Indicate that this module requires main queue setup
 */
+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
