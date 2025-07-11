// Helper: Convert PKCS#8 base64 to PKCS#1 base64 if needed
export function pkcs8ToPkcs1IfNeeded(base64: string): string {
  // PKCS#8 always starts with: MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
  // PKCS#1 always starts with: MIIBCgKCAQEA
  if (base64.startsWith('MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA')) {
    try {
      const buf = Buffer.from(base64, 'base64');
      // PKCS#8 header for RSA public key is 24 bytes
      // 0x30 0x82 ... 0x30 0x0d 0x06 0x09 ... 0x05 0x00 0x03 0x82 ... 0x00 0x00
      // Find the sequence 0x03 0x82 (bit string tag) and skip header
      let i = 0;
      while (i < buf.length - 1) {
        if (buf[i] === 0x03 && buf[i + 1] === 0x82) {
          // Next 2 bytes: length, then 1 byte: 0x00, then PKCS#1 starts
          const pkcs1Start = i + 4; // skip 0x03 0x82 len_hi len_lo 0x00
          const pkcs1 = buf.slice(pkcs1Start);
          return pkcs1.toString('base64');
        }
        i++;
      }
    } catch (e) {
      // Fallback: return original
      return base64;
    }
  }
  return base64;
}
