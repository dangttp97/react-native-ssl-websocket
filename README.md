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
  'BASE64_PUBLIC_KEY' // Obtained from get_public_key.sh script, SHA256(SPKI) Base64 at depth=0
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

// Connect
ws.connect();

// Close the connection (when needed)
// ws.close();
```

### Public Key Pinning

- Use the script `scripts/get_public_key.sh` to obtain the SHA256(SPKI) Base64 of your server (the first base64 line, corresponding to depth=0 aka server/leaf cert).
- Paste this string as the second parameter when initializing `SSLWebSocket`.
- If the server changes its certificate but keeps the same public key, the connection will still succeed.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
