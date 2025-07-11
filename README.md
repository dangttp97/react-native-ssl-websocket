# react-native-ssl-websocket

SSL Pinning capable WebSocket library for React Native (Android & iOS)

## Installation

```sh
npm install react-native-ssl-websocket
```

or

```sh
yarn add react-native-ssl-websocket
```

## Usage

```js
import { SSLWebSocket } from 'react-native-ssl-websocket';

const ws = new SSLWebSocket(
  'wss://your-server.com:port',
  'BASE64_PUBLIC_KEY' // Lấy từ script get_public_key.sh, SHA256(SPKI) Base64 ở depth=0
);

ws.onopen = () => {
  console.log('WebSocket opened');
  ws.send({ hello: 'world' });
};

ws.onmessage = (event) => {
  console.log('Received message:', event);
};

ws.onerror = (event) => {
  console.error('WebSocket error:', event);
};

ws.onclose = (event) => {
  console.log('WebSocket closed:', event);
};

// Kết nối
ws.connect();

// Đóng kết nối (khi cần)
// ws.close();
```

### Public Key Pinning

- Dùng script `scripts/get_public_key.sh` để lấy SHA256(SPKI) Base64 của server (dòng base64 đầu tiên, ứng với depth=0 aka server/leaf cert).
- Dán chuỗi này vào tham số thứ 2 khi khởi tạo `SSLWebSocket`.
- Nếu server đổi certificate nhưng giữ nguyên public key thì vẫn kết nối được.
- Nếu không khớp, kết nối sẽ bị huỷ ngay khi bắt tay SSL.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
