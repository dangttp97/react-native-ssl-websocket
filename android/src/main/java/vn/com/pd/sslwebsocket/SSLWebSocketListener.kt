package vn.com.pd.sslwebsocket

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.google.gson.Gson
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import vn.com.pd.sslwebsocket.logger.Logger
import vn.com.pd.sslwebsocket.models.Event

class SSLWebSocketListener(private val reactContext: ReactApplicationContext) :
  WebSocketListener() {
  override fun onOpen(webSocket: WebSocket, response: Response) {
    super.onOpen(webSocket, response)
    emitEvent(Event.OPEN, null)
  }

  override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
    super.onClosed(webSocket, code, reason)
    val responseObj = object {
      val code = code
      val reason = reason
    }

    emitEvent(Event.CLOSED, responseObj)
  }

  override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
    super.onFailure(webSocket, t, response)

    val responseObj = object {
      val err = t
      val response = response
    }

    emitEvent(Event.FAILURE, responseObj)
  }

  override fun onMessage(webSocket: WebSocket, text: String) {
    super.onMessage(webSocket, text)
    emitEvent(Event.MESSAGE, text)
  }

  override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
    super.onClosing(webSocket, code, reason)

    val responseObj = object {
      val code = code
      val reason = reason
    }

    emitEvent(Event.CLOSING, responseObj)
  }

  private fun emitEvent(event: Event, data: Any?) {
    Logger.instance.debug("Emitting event with name: ${event.eventName} and data: $data")

    val jsModule = reactContext.getJSModule(
      DeviceEventManagerModule.RCTDeviceEventEmitter::class
        .java
    )
    var dataStr = ""

    if(data is String){
      dataStr = data
    } else{
      dataStr = Gson().toJson(data)
    }

    jsModule.emit(event.eventName, dataStr)
  }
}
