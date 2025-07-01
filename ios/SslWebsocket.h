
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNSslWebsocketSpec.h"

@interface SslWebsocket : NSObject <NativeSslWebsocketSpec>
#else
#import <React/RCTBridgeModule.h>

@interface SslWebsocket : NSObject <RCTBridgeModule>
#endif

@end
