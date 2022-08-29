#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML::xmlsec;

my $signeddoc= <<"EOX";
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <Data id="hello">
     <content>Hello world</content>
  </Data>
  <ds:Signature>
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
      <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
      <ds:Reference URI="#hello">
        <ds:Transforms>
          <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
        </ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
        <ds:DigestValue>H8+/9SNyFIQUr3D4ivpWwCjRwAU=</ds:DigestValue>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue>gROBCm94jxE8tmSWiVD5Mg7V4PAg2z9720OkifhdZQ6o8BLhfO0T9tr7H/Buscdg
HIQUY4waNbQu3r3076WasOH8iMwXb7ffzbshhBWU73juGnXZBoLZ8chWR9To6C3w
BGwx18j9s4azI0ldh8P0atFda1SqCLHxLCjtZO/bn4A=</ds:SignatureValue>
    <ds:KeyInfo>
      <ds:KeyName>key.pem</ds:KeyName>
      <ds:KeyValue>
<ds:RSAKeyValue>
<ds:Modulus>
shsF7sQ/geqW9cv/8ArtK9umdP7oV5B3i2lRxGPTgFExb7auTyhwKQv71ZVZ4pXa
UOTFtqPubfPvipP++WhMMi9PmaIO8bUmU4YYpZLrLGFbFBwJeJd4f3KISJpz4xz0
/wGQPtvUiEjQZfNAX41rAhy7EYeflkMlKlA4M3WDc3U=
</ds:Modulus>
<ds:Exponent>
AQAB
</ds:Exponent>
</ds:RSAKeyValue>
</ds:KeyValue>
      <ds:X509Data>
         
      </ds:X509Data>
    </ds:KeyInfo>
  </ds:Signature>
</Envelope>
EOX

my $tampered= <<"EOX";
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <Data id="hello">
     <content>Hello world!</content>
  </Data>
  <ds:Signature>
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
      <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
      <ds:Reference URI="#hello">
        <ds:Transforms>
          <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
        </ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
        <ds:DigestValue>H8+/9SNyFIQUr3D4ivpWwCjRwAU=</ds:DigestValue>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue>gROBCm94jxE8tmSWiVD5Mg7V4PAg2z9720OkifhdZQ6o8BLhfO0T9tr7H/Buscdg
HIQUY4waNbQu3r3076WasOH8iMwXb7ffzbshhBWU73juGnXZBoLZ8chWR9To6C3w
BGwx18j9s4azI0ldh8P0atFda1SqCLHxLCjtZO/bn4A=</ds:SignatureValue>
    <ds:KeyInfo>
      <ds:KeyName>key.pem</ds:KeyName>
      <ds:KeyValue>
<ds:RSAKeyValue>
<ds:Modulus>
shsF7sQ/geqW9cv/8ArtK9umdP7oV5B3i2lRxGPTgFExb7auTyhwKQv71ZVZ4pXa
UOTFtqPubfPvipP++WhMMi9PmaIO8bUmU4YYpZLrLGFbFBwJeJd4f3KISJpz4xz0
/wGQPtvUiEjQZfNAX41rAhy7EYeflkMlKlA4M3WDc3U=
</ds:Modulus>
<ds:Exponent>
AQAB
</ds:Exponent>
</ds:RSAKeyValue>
</ds:KeyValue>
      <ds:X509Data>
         
      </ds:X509Data>
    </ds:KeyInfo>
  </ds:Signature>
</Envelope>
EOX

my $cert= <<"PEM";
-----BEGIN CERTIFICATE-----
MIIDJDCCAo2gAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBrjELMAkGA1UEBhMCY2wx
CzAJBgNVBAgMAlJNMTQwMgYDVQQKDCtFbXByZXNhIENvbnN0cnVjdG9yYSBNb2xs
ZXIgeSBQZXJlei1Db3RhcG9zMR4wHAYDVQQDDBVFcmljaCBTdHJlbG93IEZpZWRs
ZXIxETAPBgNVBAcMCFNhbnRpYWdvMQswCQYDVQQLDAJUSTEcMBoGCSqGSIb3DQEJ
ARYNZXNmQG1vbGxlci5jbDAeFw0yMDAyMjAxNjQ3NTFaFw0yMTAyMTkxNjQ3NTFa
MIGuMQswCQYDVQQGEwJjbDELMAkGA1UECAwCUk0xNDAyBgNVBAoMK0VtcHJlc2Eg
Q29uc3RydWN0b3JhIE1vbGxlciB5IFBlcmV6LUNvdGFwb3MxHjAcBgNVBAMMFUVy
aWNoIFN0cmVsb3cgRmllZGxlcjERMA8GA1UEBwwIU2FudGlhZ28xCzAJBgNVBAsM
AlRJMRwwGgYJKoZIhvcNAQkBFg1lc2ZAbW9sbGVyLmNsMIGfMA0GCSqGSIb3DQEB
AQUAA4GNADCBiQKBgQCyGwXuxD+B6pb1y//wCu0r26Z0/uhXkHeLaVHEY9OAUTFv
tq5PKHApC/vVlVnildpQ5MW2o+5t8++Kk/75aEwyL0+Zog7xtSZThhilkussYVsU
HAl4l3h/cohImnPjHPT/AZA+29SISNBl80BfjWsCHLsRh5+WQyUqUDgzdYNzdQID
AQABo1AwTjAdBgNVHQ4EFgQUutWLQ8pHpJiPNNsKRW/WFt49QEEwHwYDVR0jBBgw
FoAUutWLQ8pHpJiPNNsKRW/WFt49QEEwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0B
AQ0FAAOBgQBZtKII6cd30Jkk481gt6n+Pvx1XCm82WltUe0kJ93AIwnOYLUHu7+N
39tUOVacxPyJQtEgmM40JHy8J+rFVvFDF+wnQz3lYDvOvFZYadTaHuImylDZPOX/
jJrieKKWdl/wjQJNaV1eLsJ4NyOcyz8AC1ZflGbKfi48fFTGoP60zw==
-----END CERTIFICATE-----
PEM

my $doc=XML::LibXML->load_xml(string => $signeddoc);
my $signer=XML::LibXML::xmlsec->new();

$signer->loadcert(PEM => $cert);

if ($signer->verifydoc($doc, 'id-attr' => 'id', id=>'hello','id-node' =>'Data')) {
   print "Verify ok";
} else {
   print "NOT OK\n";
   print $signer->lastmsg;
}

