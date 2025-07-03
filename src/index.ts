import {
  NativeModules,
  type EmitterSubscription,
  NativeEventEmitter,
} from 'react-native';

export const SslWebsocketNative = NativeModules.SslWebsocket;

export type SslWebsocketOptions = {
  url: string;
  publicKey: string; // base64
};

type EventType = 'open' | 'message' | 'error' | 'close';

const eventMap = {
  open: 'SslWebsocketOnOpen',
  message: 'SslWebsocketOnMessage',
  error: 'SslWebsocketOnError',
  close: 'SslWebsocketOnClose',
};

export class SSLWebSocket {
  private listeners: Partial<Record<EventType, EmitterSubscription>> = {};
  private options: SslWebsocketOptions;
  private sslWebsocketEmitter: NativeEventEmitter;

  constructor(options: SslWebsocketOptions) {
    this.options = options;
    this.sslWebsocketEmitter = new NativeEventEmitter(SslWebsocketNative);
  }

  async connect() {
    await SslWebsocketNative.connect(this.options);
  }

  async testEventEmitter() {
    await SslWebsocketNative.testEventEmitter();
  }

  async send(message: any) {
    return SslWebsocketNative.send(message);
  }

  async close(code = 1000, reason = '') {
    return SslWebsocketNative.close(code, reason);
  }

  on(event: EventType, listener: (event: any) => void) {
    const nativeEvent = eventMap[event];
    const subscription = this.sslWebsocketEmitter.addListener(
      nativeEvent,
      listener
    );
    this.listeners[event] = subscription;
  }

  off(event: EventType) {
    this.listeners[event]?.remove();
    delete this.listeners[event];
  }
}
