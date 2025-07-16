// File: PublicKeyTrustManager.kt
package vn.com.pd.sslwebsocket

import android.annotation.SuppressLint
import android.util.Base64
import java.security.PublicKey
import java.security.cert.CertificateException
import java.security.cert.X509Certificate
import javax.net.ssl.X509TrustManager

import java.security.MessageDigest

class PublicKeyTrustManager(private val expectedKeyHashBase64: String) : X509TrustManager {
  override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {}

  override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()

  override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
    if (chain.isNullOrEmpty()) throw CertificateException("No server certificate provided")

    val cert = chain[0]
    val publicKey: PublicKey = cert.publicKey
    val publicKeyBytes = publicKey.encoded // Still in SPKI format

    val hash = MessageDigest.getInstance("SHA-256").digest(publicKey.encoded)
    val hashBase64 = Base64.encodeToString(hash, Base64.NO_WRAP)
    if (hashBase64 != expectedKeyHashBase64) throw CertificateException("Pinning failed")
  }
}