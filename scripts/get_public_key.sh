#!/bin/bash

DEFAULT_HOSTPORT="<your-ws-url-without-wss://>"

HOSTPORT="$1"
if [ -z "$HOSTPORT" ]; then
    HOSTPORT="$DEFAULT_HOSTPORT"
    echo "No host:port provided, using default: $HOSTPORT"
fi

openssl s_client -connect "$HOSTPORT" -showcerts </dev/null |
    awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ { print }' >all_certs.pem

if ! grep -q "BEGIN CERTIFICATE" all_certs.pem; then
    echo "❌ No certificates found in server response!"
    rm -f all_certs.pem
    exit 1
fi

# Split certs for macOS (no csplit -b)
awk 'BEGIN{c=0;out="cert_00.pem"} /-----BEGIN CERTIFICATE-----/{out=sprintf("cert_%02d.pem",c++);} {print > out}' all_certs.pem

for cert in cert_*.pem; do
    openssl x509 -in "$cert" -pubkey -noout |
        openssl pkey -pubin -outform DER 2>/dev/null >pubkey_spki.der
    HASH=$(openssl dgst -sha256 -binary pubkey_spki.der | openssl base64 | tr -d '\n')
    echo "✅ SHA256(SPKI) Base64: $HASH"
done

rm -f all_certs.pem cert_*.pem pubkey_spki.der
