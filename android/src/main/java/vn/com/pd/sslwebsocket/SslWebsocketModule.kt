// File: SslWebsocketModule.kt
package vn.com.pd.sslwebsocket

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import vn.com.pd.sslwebsocket.logger.Logger

class SslWebsocketModule(private val reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {
  private var listenerCount: Int = 0

  override fun getName(): String = NAME
  companion object {
    const val NAME = "SslWebsocket"
  }

  private lateinit var ws: SSLWebSocket

  @ReactMethod
  fun connect(url: String, publicKey: String){
    Logger.instance.debug("NATIVE: Connect to WS server")
    val listener = SSLWebSocketListener(reactContext)
    this.ws = SSLWebSocket(url, publicKey, listener)

    this.ws.connect()
  }

  @ReactMethod
  fun close(){
    Logger.instance.debug("NATIVE: Closing connection to WS server")
    this.ws.close()
  }

  @ReactMethod
  fun send(message: String){
    Logger.instance.debug("NATIVE: Send data: $message to WS server")
    this.ws.send(message)
  }

  @ReactMethod
  fun addListener(eventName: String) {
    Logger.instance.debug("NATIVE: Listener added")

    if (listenerCount == 0) {
    }

    listenerCount += 1
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    Logger.instance.debug("NATIVE: Listener removed")

    listenerCount -= count
    if (listenerCount == 0) {
      this.ws.close()
    }
  }
}
