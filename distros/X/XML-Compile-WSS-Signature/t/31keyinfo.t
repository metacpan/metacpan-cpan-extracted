#!/usr/bin/env perl
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

# Check processing of KeyInfo structures.

use warnings;
use strict;

use lib '../XML-Compile-WSS/lib', 'lib';

use Log::Report mode => 2;
use Test::More  tests => 45;

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;

use XML::LibXML              ();
use XML::Compile::WSS::Util  qw/:xtp10 :wsm10/;
use XML::Compile::Tester     qw/compare_xml/;
use MIME::Base64             qw/encode_base64/;


my $certfn     = 't/20cert.pem';
my $privkey_fn = 't/20privkey.pem';
sub newdoc() { XML::LibXML::Document->new('1.0', 'UTF8') }

use_ok('XML::Compile::Cache');
use_ok('XML::Compile::WSS::KeyInfo');
use_ok('XML::Compile::WSS::Signature');

my $schema    = XML::Compile::Cache->new;
ok(defined $schema);

my $wss       = XML::Compile::WSS::Signature->new
  ( version => '1.1'
  , schema  => $schema
  , token   => 'dummy'

  , sign_types  => []
  , sign_put    => []
  , private_key => $privkey_fn
  );

isa_ok($wss, 'XML::Compile::WSS');
isa_ok($wss, 'XML::Compile::WSS::Signature');

### top-level KeyInfo readers and writers

use_ok('XML::Compile::WSS::KeyInfo');
my $ki         = XML::Compile::WSS::KeyInfo->new;
isa_ok($ki, 'XML::Compile::WSS::KeyInfo');

my $ki_reader  = $schema->reader('ds:KeyInfo');
isa_ok($ki_reader, 'CODE', 'ki_reader');

my $ki_tokens  = $ki->getTokens($wss);
isa_ok($ki_tokens, 'CODE', 'ki_tokens');

my $ki_writer  = $schema->writer('ds:KeyInfo');
isa_ok($ki_writer, 'CODE', 'ki_writer');

my $sec_reader = $schema->reader('wsse:Security');
isa_ok($sec_reader, 'CODE', 'sec_reader');

### learn some tokens

use_ok('XML::Compile::WSS::SecToken::X509v3');
my $x509     =  XML::Compile::WSS::SecToken::X509v3->fromFile($certfn);
ok(defined $x509, 'created x509v3 token');

my @t = $ki->tokens;
cmp_ok(scalar @t, '==', 0);
$ki->addToken($x509);
@t    = $ki->tokens;
cmp_ok(scalar @t, '==', 1);
is($t[0], $x509);

my $x509fp = $x509->fingerprint;
ok(defined $x509fp, 'got fingerprint');
my $x509fp64 = encode_base64 $x509fp;

### SECTOKREF_KEYID

ok(1, 'testing SECTOKREF_KEYID');

my $keyinfo1 = <<__KEYINFO__;
<?xml version="1.0"?>
<ds:KeyInfo
   xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
   xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
>
  <wsse:SecurityTokenReference>
    <wsse:KeyIdentifier
       EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
       ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbprintSHA1">$x509fp64</wsse:KeyIdentifier>
  </wsse:SecurityTokenReference>
</ds:KeyInfo>
__KEYINFO__

my $keyhash1 = $ki_reader->($keyinfo1);
#warn Dumper $keyhash1;

my @tokens = $ki_tokens->($keyhash1);
cmp_ok(scalar @tokens, '==', 1, 'found one token');
isa_ok($tokens[0], 'XML::Compile::WSS::SecToken');
is($tokens[0], $x509);

my $wr1   = $ki->builder($wss
  , publish_token => 'SECTOKREF_KEYID'
  , keyident_id   => 'my-first-id'
  , sectokref_id  => 'another-id'
  );
my $doc1  = newdoc;
my $data1 = $wr1->($doc1, $x509, undef);
#warn Dumper $data1;
my $xml1  = $ki_writer->($doc1, $data1);

compare_xml($xml1->toString(1), <<'__XML');
<ds:KeyInfo
   xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <wsse:SecurityTokenReference wsu:Id="another-id">
    <wsse:KeyIdentifier
       wsu:Id="my-first-id"
       EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
       ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbprintSHA1">
MTI6RjQ6NzY6NjY6QzI6NzA6RjM6MUU6OTk6RDQ6QjY6MjE6NTg6RjQ6RTE6MzM6NjQ6N0U6OTE6
MDA=
    </wsse:KeyIdentifier>
  </wsse:SecurityTokenReference>
</ds:KeyInfo>
__XML


### SECTOKREF_URI

ok(1, 'testing SECTOKREF_URI');
my $keyinfo2 = <<__KEYINFO__;
<?xml version="1.0"?>
<ds:KeyInfo Id="KI-7C1FF62FE1E419416813626762777505"
   xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
   xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
   xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  <wsse:SecurityTokenReference
     wsu:Id="STR-7C1FF62FE1E419416813626762777506">
    <wsse:Reference
       URI="#X509-7C1FF62FE1E419416813626762777504"
       ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"/>
  </wsse:SecurityTokenReference>
</ds:KeyInfo>
__KEYINFO__

my $keyhash2 = $ki_reader->($keyinfo2);
#warn Dumper $keyhash2;

my $security = <<'__SECURITY';
<?xml version="1.0"?>
<wsse:Security
   xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
   xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  <wsse:BinarySecurityToken
     EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
     ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"
     wsu:Id="X509-7C1FF62FE1E419416813626762777504">MIIBvDCCAWqgAwIBAgIQ9bRpmRnJApVMfyrI8qph0jAJBgUrDgMCHQUAMBYxFDASBgNVBAMTC1Jvb3QgQWdlbmN5MB4XDTA4MDgyMDIwMTQ0M1oXDTM5MTIzMTIzNTk1OVowHzEdMBsGA1UEAxMUV1NFMlF1aWNrU3RhcnRDbGllbnQwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBANJElGegKWGyIFAkCwqpX7NNjGHbOxS+5QHPPFZHFHD7LCJk46WiDehkIqhqNbV7hozJp5ml1aHDBmqdg4GqdkxgHQsdAzBnUkOUBlITPtKs+5n9HC5Qbi+kJKEWjcqzrvpNklSQUD4VPRxkGpGUJ1IFS+KO518GxRBOjc5UhL01AgMBAAGjSzBJMEcGA1UdAQRAMD6AEBLkCS0GHR1PAI1hIdwWZGOhGDAWMRQwEgYDVQQDEwtSb290IEFnZW5jeYIQBjdsAKoAZIoRz7jUqlw19DAJBgUrDgMCHQUAA0EAHNLqfHp6L1TBNjWf1e+Gz10UGnF8boh3SRBh5NXA0XLMl+abcFBIHXfXtfNW/C6Y1OG7NwS1GVRHQwNoakDNgQ==</wsse:BinarySecurityToken>
</wsse:Security>
__SECURITY

my $sec2    = $sec_reader->($security);
#warn Dumper $sec2;

my @tokens2 = $ki_tokens->($keyhash2, $sec2);
cmp_ok(scalar @tokens2, '==', 1, 'found one token');
isa_ok($tokens2[0], 'XML::Compile::WSS::SecToken::X509v3');
@t = $ki->tokens;
cmp_ok(scalar @t, '==', 2);

my $wr2   = $ki->builder($wss
  , publish_token => 'SECTOKREF_URI'
  , sectokref_uri => '#my-uri'
  );
my $doc2  = newdoc;
my $sec2b = $doc2->createElement('top');
my $data2 = $wr2->($doc2, $x509, $sec2b);
#warn Dumper $data2;
my $xml2  = $ki_writer->($doc2, $data2);

compare_xml($xml2->toString(1), <<'__XML');
<ds:KeyInfo
   xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <wsse:SecurityTokenReference>
    <wsse:Reference URI="#my-uri"
       ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"/>
  </wsse:SecurityTokenReference>
</ds:KeyInfo>
__XML

compare_xml($sec2b->toString(1), <<'__SEC', 'binsectoken');
<top>
  <wsse:BinarySecurityToken
     xmlns:c14n="http://www.w3.org/2001/10/xml-exc-c14n#"
     xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
     xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
     wsu:Id="my-uri"
     EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
     ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3">
MIICRDCCAa2gAwIBAgIUZ2NSUF4rlanKHb4wRvj8URshOyowDQYJKoZIhvcNAQELBQAwNDELMAkG
A1UEBhMCTkwxDzANBgNVBAcMBkFybmhlbTEUMBIGA1UEAwwLZXhhbXBsZS5jb20wHhcNMjUwNjI0
MTQ1MzUwWhcNMjYwNjI0MTQ1MzUwWjA0MQswCQYDVQQGEwJOTDEPMA0GA1UEBwwGQXJuaGVtMRQw
EgYDVQQDDAtleGFtcGxlLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA0B+/p2ifYE1m
f6f62PcBE842RlT0t4G0bCAgOT0AMFw/SZumvjKbsbLx+SUeGuakalvFCU9A/3WjPayCCtVGFLUR
Sfq/SM4SGqxbKa6Hqe5+0NFhVHUg+SipnIM+mDyCcHc67OAcc/VykiM6lazptaSQ1aZ3D/l+lJig
Vsc71uUCAwEAAaNTMFEwHQYDVR0OBBYEFMLSXKqdnhPsvSPbjTXti1FyLi8pMB8GA1UdIwQYMBaA
FMLSXKqdnhPsvSPbjTXti1FyLi8pMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADgYEA
av5TM+3k1nr7wObGiuwl15ilVae2aYQzGCI0X4x1lLdSQ5lFbdhgr/WNSKzE3CN9WKaWwRLAYzaq
tUgq6FUbgfeDWiuy6VzLLcTyn2FQ83wQntm/mxTFerZfntm8Ln2eC9sQSXbY/pOWuFgJd1l+72jb
FuH0CMzAKjwIxlBejms=
  </wsse:BinarySecurityToken>
</top>
__SEC

#### KEYNAME

ok(1, 'testing KEYNAME');
my $keyinfo3 = <<'__KEYINFO__';
<ds:KeyInfo
   xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
   Id="key3-read">
  <ds:KeyName>C=NL, L=Arnhem, CN=example.com</ds:KeyName>
</ds:KeyInfo>
__KEYINFO__

my $keyhash3 = $ki_reader->($keyinfo3);
#warn Dumper $keyhash3;
is($keyhash3->{Id}, 'key3-read');

my @tokens3 = $ki_tokens->($keyhash1);
cmp_ok(scalar @tokens3, '==', 1, 'found one token');
isa_ok($tokens3[0], 'XML::Compile::WSS::SecToken');
is($tokens3[0], $x509);
is($tokens3[0]->name, 'C=NL, L=Arnhem, CN=example.com');

my $wr3   = $ki->builder
  ( $wss
  , publish_token => 'KEYNAME'
  , keyinfo_id    => 'key3'
  );

my $doc3  = newdoc;
my $data3 = $wr3->($doc3, $x509, undef);
#warn Dumper $data3;
my $xml3  = $ki_writer->($doc3, $data3);

compare_xml($xml3->toString(1), <<'__XML');
<ds:KeyInfo
   xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
   Id="key3">
  <ds:KeyName>C=NL, L=Arnhem, CN=example.com</ds:KeyName>
</ds:KeyInfo>
__XML

#### X509Data

ok(1, 'testing X509Data');

# data taken from an SMD file example
my $keyinfo4 = <<'__KEYINFO4__';
<ds:KeyInfo Id="_b3cab897-58a4-4c41-9c16-d1e1539d7b70"
   xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:X509Data>
    <ds:X509Certificate>
MIIFLzCCBBegAwIBAgIgLrAbevoae52y3f6C2tB0Sn3p7XJm0T02FogxKCfNhXowDQYJKoZIhvcN
AQELBQAwfDELMAkGA1UEBhMCVVMxPDA6BgNVBAoTM0ludGVybmV0IENvcnBvcmF0aW9uIGZvciBB
c3NpZ25lZCBOYW1lcyBhbmQgTnVtYmVyczEvMC0GA1UEAxMmSUNBTk4gVHJhZGVtYXJrIENsZWFy
aW5naG91c2UgUGlsb3QgQ0EwHhcNMTMwNjI2MDAwMDAwWhcNMTgwNjI1MjM1OTU5WjCBjzELMAkG
A1UEBhMCQkUxIDAeBgNVBAgTF0JydXNzZWxzLUNhcGl0YWwgUmVnaW9uMREwDwYDVQQHEwhCcnVz
c2VsczERMA8GA1UEChMIRGVsb2l0dGUxODA2BgNVBAMTL0lDQU5OIFRNQ0ggQXV0aG9yaXplZCBU
cmFkZW1hcmsgUGlsb3QgVmFsaWRhdG9yMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
xlp3KpYHX3WyAsFhSk3LwWfnGlxnUDFqFZA3UouMYj/XigbMkNeEXIjlkROKT4OPGfRx/LAyRlQQ
jCMv4qhbkcX1p7ar63flq4SZNVcl15l7h0uT58FzSfnlz0u5rkHfJImD43+maP/8gv36FR27jW8R
9wY4hk+Ws4IB0iFSd8SXv1Kr8w/JmMQSDkiuG+RfIiubwQ/fy7Ekj5QWhPZw+mMxNKnHULy3xYz2
LwVfftjwUueacvqNRCkMXlClOADqfT8oSZoeDXehHvlPsLCemGBoTKurskIS69F0yPEH5gze0H+f
8FROsIoKSsVQ34B4S/joE67npsJPTdKsNPJTyQIDAQABo4IBhzCCAYMwDAYDVR0TAQH/BAIwADAd
BgNVHQ4EFgQUoFpY76p5yoNDRGtQpzVuR81UWQ0wgcYGA1UdIwSBvjCBu4AUw60+ptYRAEWAXDpX
Sopt3DENnnGhgYCkfjB8MQswCQYDVQQGEwJVUzE8MDoGA1UEChMzSW50ZXJuZXQgQ29ycG9yYXRp
b24gZm9yIEFzc2lnbmVkIE5hbWVzIGFuZCBOdW1iZXJzMS8wLQYDVQQDEyZJQ0FOTiBUcmFkZW1h
cmsgQ2xlYXJpbmdob3VzZSBQaWxvdCBDQYIgLrAbevoae52y3f6C2tB0Sn3p7XJm0T02FogxKCfN
hXkwDgYDVR0PAQH/BAQDAgeAMDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly9jcmwuaWNhbm4ub3Jn
L3RtY2hfcGlsb3QuY3JsMEUGA1UdIAQ+MDwwOgYDKgMEMDMwMQYIKwYBBQUHAgEWJWh0dHA6Ly93
d3cuaWNhbm4ub3JnL3BpbG90X3JlcG9zaXRvcnkwDQYJKoZIhvcNAQELBQADggEBAIeDYYJr60W3
y9Qs+3zRVI9kekKom5vkHOalB3wHaZIaAFYpI98tY0aVN9aGON0v6WQF+nvz1KRZQbAz01BXtaRJ
4mPkarhhuLn9NkBxp8HR5qcc+KH7gv6r/c0iG3bCNJ+QSr7Qf+5MlMo6zL5UddU/T2jibMXCj/f2
1Qw3x9QgoyXLFJ9ozaLgQ9RMkLlOmzkCAiXN5Ab43aJ9f7N2gE2NnRjNKmmC9ABQ0TRwEKVLhVl1
UGqCHJ3AlBXWIXN5sjPQcD/+nHeEXMxYvlAyqxXoD3MWtQVj7j2oqlakOBMgG8+q2qYlmBts4FNi
w748Il586HKBRqxHtZdRKW2VqaQ=
    </ds:X509Certificate>
    <ds:X509Certificate>
MIIEVjCCAz6gAwIBAgIgLrAbevoae52y3f6C2tB0Sn3p7XJm0T02FogxKCfNhXkwDQYJKoZIhvcN
AQELBQAwfDELMAkGA1UEBhMCVVMxPDA6BgNVBAoTM0ludGVybmV0IENvcnBvcmF0aW9uIGZvciBB
c3NpZ25lZCBOYW1lcyBhbmQgTnVtYmVyczEvMC0GA1UEAxMmSUNBTk4gVHJhZGVtYXJrIENsZWFy
aW5naG91c2UgUGlsb3QgQ0EwHhcNMTMwNjI2MDAwMDAwWhcNMjMwNjI1MjM1OTU5WjB8MQswCQYD
VQQGEwJVUzE8MDoGA1UEChMzSW50ZXJuZXQgQ29ycG9yYXRpb24gZm9yIEFzc2lnbmVkIE5hbWVz
IGFuZCBOdW1iZXJzMS8wLQYDVQQDEyZJQ0FOTiBUcmFkZW1hcmsgQ2xlYXJpbmdob3VzZSBQaWxv
dCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMJiRqFgiCoDF8zMJMKHPMEuSpjb
El9ZWII+1WawDyt+jw841HsTT+6MwZsqExbQvukgvnuSlA3Rg3xTFxodMaVZWsVQJy2PXGHVFRLn
Cp05DYZsMGZabuN9mIekYwtjePo89Lz0JtU3ibL3squGG3gg6TLtPjks7Txm18BYPOYLznui32GU
z+1aIZuk2p5A/rSldsh3bke68IX5WZhKuIxT0+BjS8yfLWI0HCUs71WVxzvlJ1v22/eMK0WEA6+Z
hCbOKIavVtGNJrwIYwhZmxqfiR1HzHTLvrV0SLlJ2bwNk/yzKm8IJfuFezQ5BBtQ2RS9opFXX8ft
3v+uQQQvi+MCAwEAAaOBwzCBwDASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTDrT6m1hEA
RYBcOldKim3cMQ2ecTAOBgNVHQ8BAf8EBAMCAQYwNAYDVR0fBC0wKzApoCegJYYjaHR0cDovL2Ny
bC5pY2Fubi5vcmcvdG1jaF9waWxvdC5jcmwwRQYDVR0gBD4wPDA6BgMqAwQwMzAxBggrBgEFBQcC
ARYlaHR0cDovL3d3dy5pY2Fubi5vcmcvcGlsb3RfcmVwb3NpdG9yeTANBgkqhkiG9w0BAQsFAAOC
AQEAKUfEJ5X6QAttajjRVseJFQxRXGHTgCaDk8C/1nj1ielZAuZtgdUpWDUr0NnGCi+LHSsgdTYR
+vMrxir7EVYQevrBobELkxeTEfjF9FVqjBHInyPFLOFkz15zGG2IwPJps+vhAd/7gT0ph1k2FEkJ
FGL5LwRf1ms4IX0vDkxTIX8Qxy1jczCiSsoV8pwlhh2NHAkpGQWN/pTS0Uqi7uU5Bm/IoGvPBzUp
5n5SjUMnTZx/+1zAuerSabt483sXBcWsjgl7MqFtfONiAtNeMNfh60lTMu4zgVwLZTO4TQM5Q2uy
lPPmZtwnA88QvM2IL85cIYJHd0z9jpUQMBGHXF2WQA==
    </ds:X509Certificate>
  </ds:X509Data>
</ds:KeyInfo>
__KEYINFO4__

my $keyhash4 = $ki_reader->($keyinfo4);
#warn Dumper $keyhash3;
is($keyhash4->{Id}, '_b3cab897-58a4-4c41-9c16-d1e1539d7b70', 'check id');

my @tokens4 = $ki_tokens->($keyhash4);
cmp_ok(scalar @tokens4, '==', 2, 'found two tokens');

my ($t4_0, $t4_1) = @tokens4;
isa_ok($t4_0, 'XML::Compile::WSS::SecToken');
is($t4_0->name, 'C=BE, ST=Brussels-Capital Region, L=Brussels, O=Deloitte, CN=ICANN TMCH Authorized Trademark Pilot Validator');
is($t4_0->fingerprint, 'FE:22:C9:AD:51:0C:5C:61:D4:6D:04:46:5D:54:E3:42:F0:D7:1E:8E');

isa_ok($t4_1, 'XML::Compile::WSS::SecToken');
is($t4_1->name, 'C=US, O=Internet Corporation for Assigned Names and Numbers, CN=ICANN Trademark Clearinghouse Pilot CA');
is($t4_1->fingerprint, 'C6:02:B4:0D:B3:C1:70:40:CD:2C:86:7F:39:B9:DC:FA:37:E5:BA:40');
