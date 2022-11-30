use strict;
use warnings;
use Test::More tests => 5;
use XML::Enc;
use MIME::Base64 qw/decode_base64/;
use File::Which;
use File::Slurper qw/read_text/;

my $xml = <<'ENDXML';
<?xml version="1.0" encoding="UTF-8"?>
<PaymentInfo xmlns="http://example.org/paymentv2">
  <Name>John Smith</Name>
  <CreditCard Currency="USD" Limit="5,000"><EncryptedData xmlns="http://www.w3.org/2001/04/xmlenc#" Id="ED" Type="http://www.w3.org/2001/04/xmlenc#Content">
          <EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-cbc"/>
        <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <EncryptedKey xmlns="http://www.w3.org/2001/04/xmlenc#" Id="EK">
             <EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p">
                <ds:DigestMethod xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
                        <OAEPparams>MTIzNDU2Nzg=</OAEPparams>
                    </EncryptionMethod>
            <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
                  <ds:KeyName>my-rsa-key</ds:KeyName>
                   </ds:KeyInfo>
                   <CipherData>
                     <CipherValue>qkGLaEkRFs+wAbz/zXl50nI7w8+b0NUxYXQu84lJz4iXeKj5/si2lgADR9bGVQ6N
iSQGxMF9cra8zlzaB6hqxcL3u4A161ajA4iMn88kdkda/ZgVANaombU1HPn+Mqzo
3/F/hfGSJ0CpzXv5Pi3zqe2J3Sii9NQBiyRkd0lbm41gCXLuRNkZH9x/LhOlrHEC
Vj/7fi8sYTFuqz4MeCbIdNOzxOR5g/L+VTeAcTZfT6wfkfc7jFa2CqkwBqMvNrtD
o+A0MmK0fb0/kJLxNx91PVXNti4l/SrbmGZhKIIgmY9DKtAJjTK60zWkiamfqA/N
WbrcIZjGje5oRXC7GLyBJfHuLo4sQIN7UvbZCcz16OVcgOC2B/hG7CQCXGwiZV+U
rTLjBaijbx/j0+zbMs+PkmD2Ba3DgrwzsGJ2sPq6oTW28ZJebcjSxNEundodNuFv
RcohqiMFOlVJRKU/x15HsthnXrMDvYpIrKT4NJKQJHnPEeTZ+Bd6PR8jTL30p2Ea
6yH3F189AVgQf8t6ZB+GSBb/zO2aKIrA6iiViz+MJDiiD3XY3T3beaDH/u09izRs
bBqDCnFkkxajyENT8r5C1tS0PNAmaisXqPhkYSsWUBHYPgIxUasDy2oJBafF1JW0
02N7Bvg9oVFDY+Xc4hWsmaC31txPEds6ZdxhBclCMu0=</CipherValue>
                   </CipherData>
                 </EncryptedKey>
               </ds:KeyInfo>
               <CipherData>
                 <CipherValue>ecIQfyygbLDMHLKCLO31g3Y4Q+2eJZ15hyt/kiLekdBWHZRFUBzEf/3W5H66tCL2
/fsWY+Y2Zim64WuXJfPdYmy4UtSexpwTEHr0I5LR6Ykw2A61akDEh/zXKWpHsLrn
so/amlIwRtEYJTQdER7+6kkMa40M2Jf2Hk6BIXfOSCggh0KpnCnuc1+NACE0VUh6</CipherValue>
               </CipherData>
</EncryptedData></CreditCard>
</PaymentInfo>
ENDXML

my $decrypter = XML::Enc->new(
    {
        key                 => 't/xmlsec-key.pem',
        no_xml_declaration  => 1
    }
);

ok($decrypter->decrypt($xml) =~ /4019 2445 0277 5567/, "Successfully Decrypted xmlsec1 xml using OAEPparams");

$xml = <<'XML';
<?xml version="1.0"?>
<foo ID="XML-SIG_1">
    <bar>123</bar>
</foo>
XML

my $encrypter = XML::Enc->new(
    {
        key                 => 't/sign-private.pem',
        cert                => 't/sign-certonly.pem',
        oaep_params         => '123456789',
        no_xml_declaration  => 1
    }
);

my $encrypted = $encrypter->encrypt($xml);
ok($encrypted =~ /CipherData/, "Successfully Encrypted with XML::Enc using OAEPparams");

ok($encrypter->decrypt($encrypted) =~ /<bar>123<\/bar>/, "Successfully Decrypted with XML::Enc using OAEPparams");

$decrypter = XML::Enc->new(
    {
        key                 => 't/sign-private.pem',
        cert                => 't/sign-certonly.pem',
        oaep_params         => '123789',
        no_xml_declaration  => 1
    }
);
$encrypted =~ s/MTIzNDU2Nzg5/MTIzNzg5Cg==/mg;

my $ret;
eval {
    $ret = $decrypter->decrypt($encrypted);
};
ok($@ =~ /FATAL: rsa_decrypt_key_ex/,"XML::Enc Unable to decrypt if XML includes incorrect OAEPparams");
ok(!$ret);

done_testing;
