package vn.com.pd.sslwebsocket.logger

import android.util.Log
import com.google.gson.Gson

enum class LogType(val id: Int, val label: String, val emoji: String) {
  DEBUG(0, "DEBUG", "🟢"),
  ERROR(1, "ERROR", "❌"),
  WARN(2, "WARN", "⚠️")
}

class Logger {
  private val gson = Gson()

  companion object {
    val instance: Logger = Logger()
  }

  fun log(type: LogType, message: String, vararg args: Any?, data: Any? = null) {
    val tag = "SslWebsocket"

    val formattedMessage = try {
      message.format(*args)
    } catch (e: Exception) {
      "⚠️ Format error: $message"
    }

    val fullLog = buildString {
      append("${type.emoji} ${type.label}: $formattedMessage")
      if (data != null) {
        append("\n📦 Data: ${safeToJson(data)}")
      }
    }

    when (type) {
      LogType.DEBUG -> Log.d(tag, fullLog)
      LogType.ERROR -> Log.e(tag, fullLog)
      LogType.WARN  -> Log.w(tag, fullLog)
    }
  }

  private fun safeToJson(obj: Any): String {
    return try {
      gson.toJson(obj)
    } catch (e: Exception) {
      "⚠️ Failed to serialize object: ${e.message}"
    }
  }

  fun debug(msg: String, vararg args: Any?, data: Any? = null) = log(LogType.DEBUG, msg, *args, data = data)
  fun error(msg: String, vararg args: Any?, data: Any? = null) = log(LogType.ERROR, msg, *args, data = data)
  fun warn(msg: String, vararg args: Any?, data: Any? = null) = log(LogType.WARN, msg, *args, data = data)
}
