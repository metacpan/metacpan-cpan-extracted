# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl XML-LibXML-xmlsec.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;

use XML::LibXML;
use XML::LibXML::xmlsec;
use MIME::Base64;

my $private = <<"PEM";
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-256-CBC,5384A2982C969F583482515FD069F9BA

pW0yRyJabd1Kyxl5urGf5C0zZl+aGfwLFQJpzO2K4ghldUFntpj7rEa7lJXE3PiO
8qSmH8Y9RtN9sjyu53Ki62kK/eisxV23ZTYfKyFAOH58uD79cPSEErZjCvn6OyXt
DEm6bbb2eEZnOM0/w7wEDk1l3j50+e4JT8fU+d+06LnvMJfo+W7E89pr4euqw4fI
NKnO8WiqQY9cuN84dx21aoHLhu+M8X8p4YsZbF0JiE+yG1Neb5NXoLtSjZuZzVOa
haCVLWDcjXvjY74qO8+hOEZc6y7WhuIYCBViJZcDnPkmbsmW1LS3FVFX6/qpvmxl
YNUQDNnIRCF0sGJOtNpfculbiSAYwlYlrxMKEGeghp3b8wSqLeLsij/JP/XCsDpy
cF6s7AGmgMz9ZHGBHDOAuNiT/AbtUti6JqCgNyrppKX/41LrcWuTfaZzuuB4MpIS
hF8jjNH9l8uWOhQl6zyc9RdAh8/X3W+waRBtDNzs1putPGIDJTdx6WSTKHuz8wT1
RwE82Th0Mqgpk+kVDpiYB8xiL4kUA21ZUybCax77b+BqgIGNMi0BOapq1ZaHPngR
W6yvtJVJdBFfwH569Jdplf264fESKEcNyKU6Cift0D9oD7YZK7oaopAvBmZbJ0Ws
zoq+6197T7+hCdBjJyyVSwmAVIp+d4LkzCFlSR804ZZ63lJ80lFAopyJ5OpVJWWz
41SFHA75RakSOQABj+2vuSJ9p2jvfeO1tsolcU59I3ks2kX8JWdwoEiKfQVOlZGk
AC4Ss3TqjmgQbjXzoTBQB9lpEIuqRzZwfaj1vGeJgE/95hJznUL8Ff6OGuvKf5nX
-----END RSA PRIVATE KEY-----
PEM


my $xml= <<"EOX";
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <Data ID="hello">
     <content>Hello world</content>
  </Data>
  <ds:Signature>
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />
      <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />
      <ds:Reference URI="#hello">
        <ds:Transforms>
          <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
        </ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
        <ds:DigestValue></ds:DigestValue>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue/>
    <ds:KeyInfo>
      <ds:KeyName>key.pem</ds:KeyName>
      <ds:KeyValue />
      <ds:X509Data>
         <ds:X509Certificate/>
      </ds:X509Data>
    </ds:KeyInfo>
  </ds:Signature>
</Envelope>
EOX

sub checkvalue($$$) {

   my $doc=shift();
   my $path=shift();
   my $match=shift();

   my $value=$doc->findvalue($path);

   return (decode_base64($value) eq decode_base64($match) );
}

my $cheat_hash= "LAM89OAB9lpCbjy8hYFXPmYenAM=";
my $cheat_value= <<"base64";
qcw3qhRQE1YSMMpXMMU/lPAl/2WU4gvUAVbsU/ZUBMakUrVWp0AJ16Z+D1YcH75j
GRuqCjeOdK87TmEq0gG/YrQZnHBuNRWHyMeadxe7ViB0GAoHGcHte5B2Su6m2MKz
XSGsF9EeRjzL3dYY6/jNouapXdCDUCw8fivyOkUGFrs=
base64

my $cheat_modulus= <<"base64";
wdbXJV/qv23A0bgf1M7u64xAjaMu6sRD0pvtZQF5xvY0bxo4uRC8+xhfb1/pFpHN
rPvAJ3Asbx4iU3pJKI+PGCGIcfYCw1A5HFmwBcmHK3sJjdyI+LqbS2nBkjhkkW6w
xcqitTOOATIsXCLvZjWvomUjjMH23nRvLcE6mFvRK5E=
base64

my $cheat_exponent="AQAB";

my $signer=XML::LibXML::xmlsec->new();

ok($signer->loadpkey(PEM => $private, secret=> 'alone')==0,"Encrypted key loading");

my $doc=XML::LibXML->load_xml(string => $xml);


ok($signer->signdoc($doc, id => "hello", 'id-node' => 'Data', 'id-attr' => 'ID'),"Signature");

ok(checkvalue($doc,'//ds:DigestValue',$cheat_hash),'Digest');
ok(checkvalue($doc,'//ds:Signature/ds:SignatureValue',$cheat_value),'Signature value');
ok(checkvalue($doc,'//ds:RSAKeyValue/ds:Modulus',$cheat_modulus),'Modulus value');
ok(checkvalue($doc,'//ds:RSAKeyValue/ds:Exponent',$cheat_exponent),'Exponent value');

