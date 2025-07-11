import { NativeModules, NativeEventEmitter } from 'react-native';

const SslWebsocketNative = NativeModules.SslWebsocket;

export class SSLWebSocket {
  url: string;
  publicKeyBase64: string;
  private emitter: NativeEventEmitter;

  // Các handler có thể bị gán lại từ bên ngoài
  onopen: ((event: any) => void) | null = null;
  onmessage: ((event: any) => void) | null = null;
  onerror: ((event: any) => void) | null = null;
  onclose: ((event: any) => void) | null = null;

  constructor(url: string, publicKeyBase64: string) {
    this.url = url;
    // Auto-convert PKCS#8 to PKCS#1 if needed
    this.publicKeyBase64 = publicKeyBase64;
    console.log('publicKeyBase64', publicKeyBase64);
    this.emitter = new NativeEventEmitter(NativeModules.SslWebsocket);

    this.emitter.addListener('onOpen', (event) => {
      if (this.onopen) this.onopen(event);
    });
    this.emitter.addListener('onMessage', (event) => {
      if (this.onmessage) this.onmessage(event);
    });
    this.emitter.addListener('onError', (event) => {
      if (this.onerror) this.onerror(event);
    });
    this.emitter.addListener('onClosed', (event) => {
      if (this.onclose) this.onclose(event);
    });
  }

  private destruct() {
    this.emitter.removeAllListeners('onOpen');
    this.emitter.removeAllListeners('onMessage');
    this.emitter.removeAllListeners('onError');
    this.emitter.removeAllListeners('onClosed');
  }

  connect() {
    SslWebsocketNative.connect(this.url, this.publicKeyBase64);
  }

  send(message: any) {
    SslWebsocketNative.send(JSON.stringify(message));
  }

  close() {
    SslWebsocketNative.close();
    this.destruct();
  }
}
