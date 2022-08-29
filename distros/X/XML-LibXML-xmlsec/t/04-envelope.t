# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl XML-LibXML-xmlsec.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 4;

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
</Envelope>
EOX

sub checkvalue($$$) {

   my $doc=shift();
   my $path=shift();
   my $match=shift();

   my $value=$doc->findvalue($path);

   return (decode_base64($value) eq decode_base64($match) );
}

my $cheat_hash= "ZNnL1a/TRmyud5vprbwJm0z/cBWiTyg964iiKl0F3Tw=";
my $cheat_value= <<"base64";
RxwTT2lff92Z4A1Jm27GkzILzsg7R4vzxPTC0loucaaTU/NAGHN1KpdD5rj3I3UZ
ARmhzoMIgZARCU2+jkWqCD+ur8L1AOXa6FtfSflCVH7HAbZ6dFn6ka7OGsR3qXUq
/FK7PTM6XpoqYYlrwtwJm4VxsdSdYbRaEzqwJgQqTR8=
base64


my $signer=XML::LibXML::xmlsec->new();
my $doc=XML::LibXML->load_xml(string => $xml);

$signer->template4sign($doc,'RSA-SHA256','hello');

print $doc->toString;

ok($signer->loadpkey(PEM => $private)==0,"Private key loading");



ok($signer->signdoc($doc, id => "hello", 'id-node' => 'Data', 'id-attr' => 'ID'),"Signature");

ok(checkvalue($doc,'//ds:DigestValue',$cheat_hash),'Digest');
ok(checkvalue($doc,'//ds:Signature/ds:SignatureValue',$cheat_value),'Signature value');

