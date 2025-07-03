# react-native-ssl-websocket

SSL Pinning capable WebSocket library for React Native (Android & iOS)

## Installation

```sh
npm install react-native-ssl-websocket
```

## Usage

```js
import { SSLWebSocket } from 'react-native-ssl-websocket';

const ws = new SSLWebSocket({
  url: 'wss://your-server',
  publicKey: 'BASE64_PUBLIC_KEY', // lấy từ server, encode base64
});

ws.on('open', () => {
  ws.send('Hello from React Native!');
});
ws.on('message', (msg) => {
  console.log('Received:', msg);
});
ws.on('error', (err) => {
  console.error('WebSocket error:', err);
});
ws.on('close', (reason) => {
  console.log('WebSocket closed:', reason);
});

// Kết nối
await ws.connect();

// Đóng kết nối
await ws.close();
```

### Public Key Pinning
- Bạn cần lấy public key của server (dạng base64, không phải PEM/certificate).
- Nếu server đổi certificate nhưng giữ nguyên public key thì vẫn kết nối được.
- Nếu không khớp, kết nối sẽ bị huỷ ngay khi bắt tay SSL.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
