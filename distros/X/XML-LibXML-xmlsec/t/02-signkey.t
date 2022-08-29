# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl XML-LibXML-xmlsec.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 7;

use XML::LibXML;
use XML::LibXML::xmlsec;
use MIME::Base64;

my $private = <<"PEM";
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQDB1tclX+q/bcDRuB/Uzu7rjECNoy7qxEPSm+1lAXnG9jRvGji5
ELz7GF9vX+kWkc2s+8AncCxvHiJTekkoj48YIYhx9gLDUDkcWbAFyYcrewmN3Ij4
uptLacGSOGSRbrDFyqK1M44BMixcIu9mNa+iZSOMwfbedG8twTqYW9ErkQIDAQAB
AoGAT1x2mYa7xcRZvYN1BNv0VdwGUfcNrnDMk93jRAdmpF8I+LPzpVGFDgjciezq
saLgYoJwGbWDe7sKssLOURz1qGTUTVdxMxTgY0cWyJk5W9aVMI9Dl2mmrwbp6+t0
pTlKUFENcO4ERIe4RB0HSiNmSNwjef/Csi5hCX9aUHlL8kECQQDsqJGdALdUnTg8
+BzhsU2whMSolrR/A/JopQQNdDcnjxeSdPd6FR4KxMD6bku8G5KJFuuZONdDdR0V
L5kYAfK7AkEA0a5lWXrZF1vZ9zjnry6plYnBYAYMPDhQeonUCCDj1qFcItQdVDac
g3xBCsfdxPw1FXtlvvwjui6At02ORE00IwJAdDq6AU0HvTPWGgOVU7cbu9UJLO+P
SE5s8L4SxnTMXc5mOlTd8oSKk6lcSeJ/qaw1BMVQApmrB4NuPCh7XRIf3wJARtKY
+Pg9i15C6PYXi1w/e3rkDgL87vo2dK1JKNWzHzOxYzIyFde8Vc0KSxHnHjnx1Cex
3ihcCO7cGw3fF8Lb8QJBALXgcCHKcJPdfEdbDW4Zbv38vv2JY88VA2unk8S8cDx1
wOdkz7y8ghYxr/NylPw6CyAeYDx+ryrfc
Q8wSYGilTk=
-----END RSA PRIVATE KEY-----
PEM

my $public= <<"PEM";
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDB1tclX+q/bcDRuB/Uzu7rjECN
oy7qxEPSm+1lAXnG9jRvGji5ELz7GF9vX+kWkc2s+8AncCxvHiJTekkoj48YIYhx
9gLDUDkcWbAFyYcrewmN3Ij4uptLacGSOGSRbrDFyqK1M44BMixcIu9mNa+iZSOM
wfbedG8twTqYW9ErkQIDAQAB
-----END PUBLIC KEY-----
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

ok($signer->loadpkey(PEM => $private)==0,"Private key loading");
ok($signer->loadpkey(PEM => $public)==0,"Public key loading");

my $doc=XML::LibXML->load_xml(string => $xml);


ok($signer->signdoc($doc, id => "hello", 'id-node' => 'Data', 'id-attr' => 'ID'),"Signature");

ok(checkvalue($doc,'//ds:DigestValue',$cheat_hash),'Digest');
ok(checkvalue($doc,'//ds:Signature/ds:SignatureValue',$cheat_value),'Signature value');
ok(checkvalue($doc,'//ds:RSAKeyValue/ds:Modulus',$cheat_modulus),'Modulus value');
ok(checkvalue($doc,'//ds:RSAKeyValue/ds:Exponent',$cheat_exponent),'Exponent value');

