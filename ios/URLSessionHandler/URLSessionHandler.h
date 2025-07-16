@protocol URLSessionHandlerDelegate <NSObject>
- (void)onOpen;
- (void)onMessage:(NSString *)message;
- (void)onError:(NSString *)error;
- (void)onClosed:(NSDictionary *)data;
@end

@interface URLSessionHandler : NSObject
- (instancetype)initWithURL:(NSString *)url publicKey:(NSString *)publicKey delegate:(id<URLSessionHandlerDelegate>)delegate;
- (void)connectWebSocket;
- (void) send:(NSString *) message;
- (void) close;
@end
