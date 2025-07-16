#import "CryptographyUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation CryptographyUtils

+ (nullable NSString *)spkiSha256Base64FromCertificate:(SecCertificateRef)certificate {
    if (!certificate) return nil;
    SecKeyRef publicKey = SecCertificateCopyKey(certificate);
    if (!publicKey) return nil;
    CFErrorRef error = NULL;
    CFDataRef publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error);
    if (!publicKeyData) {
        CFRelease(publicKey);
        return nil;
    }
    NSData *rawKey = (__bridge NSData *)publicKeyData;
    // Prefix for RSA 2048 (if the server uses RSA)
    const unsigned char rsa2048SPKIPrefix[] = {
        0x30, 0x82, 0x01, 0x22,  // SEQUENCE
        0x30, 0x0d,
        0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01,  // OID: rsaEncryption
        0x05, 0x00,             // NULL
        0x03, 0x82, 0x01, 0x0f, 0x00  // BIT STRING (unused bits = 0)
    };
    NSMutableData *spkiData = [NSMutableData dataWithBytes:rsa2048SPKIPrefix length:sizeof(rsa2048SPKIPrefix)];
    [spkiData appendData:rawKey];
    // SHA256
    uint8_t hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(spkiData.bytes, (CC_LONG)spkiData.length, hash);
    NSData *hashData = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
    NSString *base64 = [hashData base64EncodedStringWithOptions:0];
    CFRelease(publicKeyData);
    CFRelease(publicKey);
    return base64;
}

+ (nullable SecKeyRef)publicKeyFromCertificate:(SecCertificateRef)certificate {
    if (!certificate) return nil;
    return SecCertificateCopyKey(certificate);
}

+ (nullable NSData *)sha256FromData:(NSData *)data {
    if (!data) return nil;
    uint8_t hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    return [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
}

+ (nullable NSString *)base64FromData:(NSData *)data {
    if (!data) return nil;
    return [data base64EncodedStringWithOptions:0];
}

+ (nullable NSData *)dataFromBase64:(NSString *)base64String {
    if (!base64String) return nil;
    return [[NSData alloc] initWithBase64EncodedString:base64String options:0];
}

+ (BOOL)compareCertificate:(SecCertificateRef)certificate withExpectedBase64:(NSString *)expectedBase64 {
    NSString *certBase64 = [self spkiSha256Base64FromCertificate:certificate];
    if (!certBase64 || !expectedBase64) return NO;
    return [certBase64 isEqualToString:expectedBase64];
}

@end
