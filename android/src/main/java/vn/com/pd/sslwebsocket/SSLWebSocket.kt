package vn.com.pd.sslwebsocket

import android.os.Handler
import android.os.Looper
import com.facebook.react.bridge.ReactApplicationContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import javax.net.ssl.SSLContext

class SSLWebSocket(private val url: String, private val publicKey: String, private val listener:
WebSocketListener) {
  private lateinit var ws: WebSocket;
  private lateinit var client: OkHttpClient
  private var retryCount: Int = 0

  fun connect() {
    val trustManager = PublicKeyTrustManager(publicKey)
    val sslContext = SSLContext.getInstance("TLS").apply {
      init(null, arrayOf(trustManager), null)
    }
    client = OkHttpClient.Builder().sslSocketFactory(sslContext.socketFactory, trustManager).build()
    val request = Request.Builder().url(url).build()
    ws = client.newWebSocket(request, object : WebSocketListener() {
      override fun onOpen(webSocket: WebSocket, response: Response) {
        retryCount = 0
        listener.onOpen(webSocket, response)
      }

      override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        listener.onFailure(webSocket, t, response)
        retryCount++
        Handler(Looper.getMainLooper()).postDelayed({
          connect()
        }, (1000L * retryCount).coerceAtMost(10000L))
      }

      override fun onMessage(webSocket: WebSocket, text: String) {
        listener.onMessage(webSocket, text)
      }

      override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
        listener.onClosing(webSocket, code, reason)
      }

      override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
        listener.onClosed(webSocket, code, reason)
      }
    })
  }

  fun send(message: String) {
    ws.send(message)
  }

  fun close() {
    ws.close(1000, null)
  }
}
