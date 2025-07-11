// File: PublicKeyTrustManager.kt
package vn.com.pd.sslwebsocket

import android.annotation.SuppressLint
import android.util.Base64
import java.security.PublicKey
import java.security.cert.CertificateException
import java.security.cert.X509Certificate
import javax.net.ssl.X509TrustManager

@SuppressLint("CustomX509TrustManager")
class PublicKeyTrustManager(private val expectedKeyBase64: String) : X509TrustManager {
  @SuppressLint("TrustAllX509TrustManager")
  override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {}

  override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()

  override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
    if (chain.isNullOrEmpty()) throw CertificateException("No server certificate provided")

    val cert = chain[0]
    val publicKey: PublicKey = cert.publicKey
    val actualKeyBase64 = Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)

    if (actualKeyBase64 != expectedKeyBase64) {
      throw CertificateException("Public key pinning failure")
    }
  }
}
