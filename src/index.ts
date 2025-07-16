import { NativeModules, NativeEventEmitter } from 'react-native';

const SslWebsocketNative = NativeModules.SslWebsocket;

export class SSLWebSocket {
  url: string;
  publicKeyBase64: string;
  private emitter: NativeEventEmitter;

  // WebSocket readyState constants
  static CONNECTING = 0;
  static OPEN = 1;
  static CLOSING = 2;
  static CLOSED = 3;

  readyState: number = SSLWebSocket.CLOSED;

  // The handlers can be reassigned from outside
  onopen: ((event: any) => void) | null = null;
  onmessage: ((event: any) => void) | null = null;
  onerror: ((event: any) => void) | null = null;
  onclose: ((event: any) => void) | null = null;

  constructor(url: string, publicKeyBase64: string) {
    this.url = url;
    this.publicKeyBase64 = publicKeyBase64;
    this.emitter = new NativeEventEmitter(NativeModules.SslWebsocket);

    this.emitter.addListener('onOpen', (event) => {
      this.readyState = SSLWebSocket.OPEN;
      if (this.onopen) this.onopen(event);
    });
    this.emitter.addListener('onMessage', (event) => {
      if (this.onmessage) this.onmessage(event);
    });
    this.emitter.addListener('onError', (event) => {
      this.readyState = SSLWebSocket.CLOSED;
      if (this.onerror) this.onerror(event);
    });
    this.emitter.addListener('onClosed', (event) => {
      this.readyState = SSLWebSocket.CLOSED;
      if (this.onclose) this.onclose(event);
    });
    this.emitter.addListener('onClosing', (_event) => {
      this.readyState = SSLWebSocket.CLOSING;
    });
  }

  private destruct() {
    this.emitter.removeAllListeners('onOpen');
    this.emitter.removeAllListeners('onMessage');
    this.emitter.removeAllListeners('onError');
    this.emitter.removeAllListeners('onClosed');
    this.emitter.removeAllListeners('onClosing');
  }

  connect() {
    this.readyState = SSLWebSocket.CONNECTING;
    SslWebsocketNative.connect(this.url, this.publicKeyBase64);
  }

  send(message: any) {
    if (this.readyState !== SSLWebSocket.OPEN) {
      throw new Error('WebSocket is not open');
    }
    SslWebsocketNative.send(JSON.stringify(message));
  }

  close() {
    this.readyState = SSLWebSocket.CLOSING;
    SslWebsocketNative.close();
    this.destruct();
  }
}
