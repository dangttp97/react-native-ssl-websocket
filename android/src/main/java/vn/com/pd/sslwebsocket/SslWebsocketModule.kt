// File: SslWebsocketModule.kt
package vn.com.pd.sslwebsocket

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import vn.com.pd.sslwebsocket.logger.Logger
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager

class SslWebsocketModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private var webSocket: WebSocket? = null
  private var listenerCount = 0

  override fun getName(): String = NAME

  @ReactMethod
  fun connect(options: ReadableMap, promise: Promise) {
    val url = options.getString("url")
    val publicKeyBase64 = options.getString("publicKey")

    if (url.isNullOrBlank() || publicKeyBase64.isNullOrBlank()) {
      promise.reject("invalid_args", "url and publicKey are required")
      return
    }

    try {
      val trustManager = PublicKeyTrustManager(publicKeyBase64)
      val sslContext = SSLContext.getInstance("TLS").apply {
        init(null, arrayOf<TrustManager>(trustManager), null)
      }

      val client = OkHttpClient.Builder()
        .sslSocketFactory(sslContext.socketFactory, trustManager)
        .build()

      val request = Request.Builder().url(url).build()
      client.newWebSocket(request, createWebSocketListener())

      promise.resolve(null)
    } catch (e: Exception) {
      Logger.instance.error("❌ Android: SSL setup error: %s", e.message ?: "unknown", data = e)
      sendEvent("SslWebsocketOnError", e.message ?: "SSL setup error")
      promise.reject("ssl_error", e)
    }
  }

  @ReactMethod
  fun send(message: ReadableMap, promise: Promise) {
    try {
      val jsonObject = JSONObject(message.toHashMap())
      val jsonString = jsonObject.toString()

      val scheme = webSocket?.request()?.url?.scheme // sẽ là "wss" hoặc "ws"
      Logger.instance.debug("📤 Sending message $jsonString, websocket scheme: $scheme")


      webSocket?.let {
        val success = it.send(jsonString)
        promise.resolve(success)
      } ?: promise.reject("not_connected", "WebSocket is not connected")
    } catch (e: Exception) {
      Logger.instance.error("❌ Failed to send message", e)
      promise.reject("send_error", e)
    }
  }

  @ReactMethod
  fun close(code: Int, reason: String?, promise: Promise) {
    webSocket?.let {
      it.close(code, reason ?: "")
      promise.resolve(null)
    } ?: promise.reject("not_connected", "WebSocket is not connected")
  }

  @ReactMethod
  fun addListener(eventName: String) {
    listenerCount += 1
  }


  @ReactMethod
  fun removeListeners(count: Int) {
    listenerCount -= count
    if (listenerCount <= 0) {
      listenerCount = 0
    }
  }

  private fun createWebSocketListener(): WebSocketListener {
    return object : WebSocketListener() {
      override fun onOpen(webSocket: WebSocket, response: Response) {
        if (response.code == 101) {
          Logger.instance.debug(
            "🔗 WebSocket opened %s", response
          )
          this@SslWebsocketModule.webSocket = webSocket
          sendEvent("SslWebsocketOnOpen", null)
        }
      }

      override fun onMessage(webSocket: WebSocket, text: String) {
        Logger.instance.debug("📨 Android: Received message: %s", text)
        sendEvent("SslWebsocketOnMessage", text)
      }

      override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        Logger.instance.error("❌ Android: WebSocket failure: %s", t.message ?: "unknown", data = t)
        sendEvent("SslWebsocketOnError", t.message ?: "Unknown error")
      }

      override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
        Logger.instance.debug("🔒 Android: WebSocket closing with code %d, reason: %s", code, reason)
        sendEvent("SslWebsocketOnClose", reason)
      }

      override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
        Logger.instance.debug("🔒 Android: WebSocket closed with code %d, reason: %s", code, reason)
        sendEvent("SslWebsocketOnClose", reason)
        this@SslWebsocketModule.webSocket = null
      }
    }
  }

  private fun sendEvent(event: String, data: Any?) {
    Logger.instance.debug("🔥 Emitting event $event with data: $data")
    val reactContext = this.reactApplicationContext
    if (reactContext.hasActiveCatalystInstance()) {
      reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        .emit(event, data)
    } else {
      Logger.instance.warn("⚠️ React context not ready, drop event $event")
    }
  }

  companion object {
    const val NAME = "SslWebsocket"
  }
}
