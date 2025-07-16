/* eslint-disable react-native/no-inline-styles */
import { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  Button,
  ScrollView,
  SafeAreaView,
} from 'react-native';
import { SSLWebSocket } from '../../src/index';

const WS_URL = '<your-ws-url>';
// Replace with your server's actual public key
const PUBLIC_KEY_BASE64 = '<your-server-public-key>';

export default function App() {
  const [log, setLog] = useState<string[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [ws, setWs] = useState<SSLWebSocket | null>(null);

  const addLog = (msg: string) => {
    // console.log(msg);
    setLog((prev) => [new Date().toLocaleTimeString() + ': ' + msg, ...prev]);
  };

  useEffect(() => {
    const websocket = new SSLWebSocket(WS_URL, PUBLIC_KEY_BASE64);

    listenEvents(websocket);
    // eventListen();

    setWs(websocket);

    return () => {
      websocket.close();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // const eventListen = () => {
  //   const eventListener = new NativeEventEmitter(NativeModules.SslWebsocket);
  //   eventListener.addListener('onOpen', () => {
  //     addLog(
  //       `WebSocket opened in ${WS_URL} with public key ${PUBLIC_KEY_BASE64}`
  //     );
  //     setIsConnected(true);
  //     setIsConnecting(false);
  //   });
  //   eventListener.addListener('onMessage', (event: any) => {
  //     addLog(`Received message: ${event}`);
  //   });
  //   eventListener.addListener('onError', (data) => {
  //     addLog(`WebSocket error: ${data}`);
  //   });
  //   eventListener.addListener('onClosing', (data) => {
  //     addLog(`WebSocket closing: ${data}`);
  //     setIsConnected(false);
  //     setIsConnecting(false);
  //   });
  //   eventListener.addListener('onClosed', (data) => {
  //     addLog(`WebSocket closed: ${data}`);
  //     setIsConnected(false);
  //     setIsConnecting(false);
  //   });
  // };

  const listenEvents = (websocket: SSLWebSocket) => {
    websocket.onopen = () => {
      addLog('WebSocket opened');
      setIsConnected(true);
      setIsConnecting(false);
    };

    websocket.onmessage = (event) => {
      addLog(`Received message: ${event}`);
    };

    websocket.onerror = (event) => {
      addLog(`WebSocket error: ${event}`);
    };

    websocket.onclose = (event) => {
      addLog(`WebSocket closing: ${event}`);
      setIsConnected(false);
      setIsConnecting(false);
    };
  };

  const handleConnect = async () => {
    setIsConnecting(true);
    await ws?.connect();
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
    <SafeAreaView style={styles.container}>
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
    </SafeAreaView>
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
