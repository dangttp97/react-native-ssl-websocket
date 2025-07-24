# react-native-ssl-websocket

A WebSocket library for React Native (Android & iOS) with SSL Pinning support.

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
  'BASE64_PUBLIC_KEY' // Obtain this using the get_public_key.sh script; use the SHA256(SPKI) Base64 at depth=0
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

// Close the connection when needed
// ws.close();
```

### Public Key Pinning

- Use the `scripts/get_public_key.sh` script to obtain the SHA256(SPKI) Base64 of your server certificate (the first base64 line, corresponding to depth=0, i.e., the server/leaf certificate).
- Paste this string as the second parameter when initializing `SSLWebSocket`.
- If the server changes its certificate but keeps the same public key, the connection will still succeed.

### Important Notes

- The library can receive any kind of object, array, or string. The JS bridge will serialize them to JSON strings.
- The native side will only receive and send strings to the JS side. If you need a JSON object, you should parse the string yourself.
- In Node.js WebSocket, the data is a server response object. In this library, you will receive the raw object sent from the server.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
