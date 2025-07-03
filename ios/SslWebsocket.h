#import <React/RCTBridgeModule.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNSslWebsocketSpec.h"

@interface SslWebsocket
    : RCTEventEmitter <NativeSslWebsocketSpec, RCTBridgeModule>
#else
#import <React/RCTEventEmitter.h>

@interface SslWebsocket : RCTEventEmitter <RCTBridgeModule>
#endif

@end
