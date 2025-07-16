package vn.com.pd.sslwebsocket.models

enum class Event(val eventName: String) {
  OPEN("onOpen"),
  CLOSED("onClosed"),
  CLOSING("onClosing"),
  MESSAGE("onMessage"),
  FAILURE("onFailure")
}
