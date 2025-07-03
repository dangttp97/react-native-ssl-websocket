/* eslint-disable react-native/no-inline-styles */
import { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  Button,
  ScrollView,
  NativeEventEmitter,
  NativeModules,
} from 'react-native';
import { SSLWebSocket } from '../../src/index';

const WS_URL = 'wss://consumer-test-socket.finviet.com.vn:6868';
// Thay thế bằng public key thực của server
const PUBLIC_KEY_BASE64 =
  'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAj1der5MeuE6MJRBYg22XSyEryDk9sy+30Q0NSccVAQg8O7Xst+TBzQ/U3d5tbnfQ7wsQoRgk2mVWWPUnDuqFQOsUBLrspQYxD7ypHIlydF6tBoqr/Lkf0rW8eKGRR1dMt/YTSLS416pQVhr9DxUGvIxaY9LgtIeqxIpENfTJkUC+9oZpLtI4HOHKZkx+X6EokjvdEAOF4D8C4MH+iPzDhVO8pIWLE6rDPxPZ512dN7Lai3AmcN8XLi7IB3MFPc1UXbOEhrBojHb214HeXrrOaFGB97DXALyn0XUBAjuJKAcrPMcydHxQkIOvOzzI9KmQ6gCM9Mnna4koqQr5DSdhdwIDAQAB';

export default function App() {
  const [log, setLog] = useState<string[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [ws, setWs] = useState<SSLWebSocket | null>(null);

  const addLog = (msg: string) => {
    console.log(msg);
    setLog((prev) => [new Date().toLocaleTimeString() + ': ' + msg, ...prev]);
  };

  useEffect(() => {
    const websocket = new SSLWebSocket({
      url: WS_URL,
      publicKey: PUBLIC_KEY_BASE64,
    });
    setWs(websocket);

    const eventEmitter = new NativeEventEmitter(NativeModules.SslWebsocket);
    eventEmitter.addListener('SslWebsocketOnOpen', () => {
      addLog('WebSocket opened');
      setIsConnected(true);
      setIsConnecting(false);
    });
    eventEmitter.addListener('SslWebsocketOnMessage', (msg: string) => {
      addLog('Message received: ' + msg);
    });
    eventEmitter.addListener('SslWebsocketOnError', (err: string) => {
      addLog('Error: ' + err);
    });
    eventEmitter.addListener(
      'SslWebsocketOnClose',
      (event: { code?: string; reason?: string }) => {
        const code = event && event.code !== undefined ? event.code : '';
        const reason = event && event.reason !== undefined ? event.reason : '';
        addLog('Closed: ' + code + ' ' + reason);
        setIsConnected(false);
        setIsConnecting(false);
      }
    );

    websocket.on('open', () => {
      addLog('WebSocket opened');
      setIsConnected(true);
      setIsConnecting(false);
      websocket.send('Hello');
    });

    websocket.on('message', (msg: string) => {
      addLog('Message received: ' + msg);
    });

    websocket.on('error', (err: string) => {
      addLog('Error: ' + err);
      setIsConnected(false);
      setIsConnecting(false);
    });

    websocket.on('close', (event: any) => {
      // Try to extract code and reason if available, otherwise fallback
      const code = event && event.code !== undefined ? event.code : '';
      const reason = event && event.reason !== undefined ? event.reason : '';
      addLog('Closed: ' + code + ' ' + reason);
      setIsConnected(false);
      setIsConnecting(false);
    });

    return () => {
      websocket.close();
    };
  }, []);

  const handleConnect = async () => {
    setIsConnecting(true);
    await ws?.connect();
    setIsConnecting(false);
  };

  const handleSend = async () => {
    await ws?.send({
      event: 'message',
      data: {
        platform: 'ios',
        model: 'iPhone',
        osversion: '17.4',
        device_id: 'FEE9A272-6AB5-4577-B6F2-4D41ADB96D25',
        timeout: 60000,
        appversion: '2.2.13',
        trace_source: 'CONSUMER',
        cmdtype: 3005,
        clearPinOnSuccess: true,
        pin: '222222',
        handler: 'logIn',
        device: 'iPhone15,4',
        fcm_token:
          'dbK4AUnXPEmLj060T_PEbL:APA91bFbEaJe8ioXjLPr1165ndymCQzuFMf8eoS7PIdrugx3_KOcqaaP8ZnsQrbiGcS7zWxYY5vjzP1kI4Sv7FpUIbbiXe9FYAGEbPldX_mqSd3An1LzdlI',
        initiator: '0937168210',
        reqid: 1751516408108,
        reqtime: 1751516407913,
      },
    });
  };

  const handleClose = async () => {
    await ws?.close();
    setIsConnected(false);
  };

  const renderSeparator = () => <View style={{ height: 10 }} />;

  return (
    <View style={styles.container}>
      <Text style={styles.status}>
        Status:{' '}
        {isConnecting
          ? 'Connecting...'
          : isConnected
            ? 'Connected'
            : 'Disconnected'}
      </Text>
      {renderSeparator()}
      <Button
        title="Connect"
        onPress={handleConnect}
        disabled={isConnecting || isConnected}
      />
      {renderSeparator()}
      <Button
        title="Send Message"
        onPress={handleSend}
        disabled={!isConnected}
      />
      {renderSeparator()}
      <Button title="Close" onPress={handleClose} disabled={!isConnected} />
      {renderSeparator()}
      <ScrollView style={{ flex: 1, width: '100%' }}>
        {log.map((l: string, i: number) => (
          <Text key={i} style={styles.logText}>
            {l}
          </Text>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
  },
  status: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  logText: {
    fontSize: 12,
    marginBottom: 2,
  },
});
