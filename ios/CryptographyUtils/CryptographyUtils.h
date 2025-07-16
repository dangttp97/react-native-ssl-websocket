#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface CryptographyUtils : NSObject

+ (nullable NSString *)spkiSha256Base64FromCertificate:(SecCertificateRef)certificate;
+ (BOOL)compareCertificate:(SecCertificateRef)certificate withExpectedBase64:(NSString *)expectedBase64;
+ (nullable SecKeyRef)publicKeyFromCertificate:(SecCertificateRef)certificate;
+ (nullable NSData *)sha256FromData:(NSData *)data;
+ (nullable NSString *)base64FromData:(NSData *)data;
+ (nullable NSData *)dataFromBase64:(NSString *)base64String;

@end
