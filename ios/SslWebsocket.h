#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNSslWebsocketSpec.h"

@interface SslWebsocket : RCTEventEmitter <NativeSslWebsocketSpec, RCTBridgeModule>
#else

@interface SslWebsocket : RCTEventEmitter <RCTBridgeModule>
#endif

@end
