use Modern::Perl;
use Test::More;
use MIME::Base64;
use FindBin qw($Bin);
use Data::Dumper;
use File::Spec;

my $pkg='XML::Sig::OO';
use_ok($pkg);
require_ok($pkg);
isa_ok($pkg->new(XML_1()),$pkg);
{
  my $cacert="$Bin/idp_cert.pem";
  my $self=$pkg->new(XML_1(),cacert=>$cacert);

  {
    my $x=$self->build_xpath;
    my ($nth)=$x->findnodes($self->xpath_SignedInfo);
    cmp_ok($nth->toString,'ne',XML_SignedInfo_canon(),'Current string should not match canon string');
    ok($nth,'should have the signed node tree');
    my $result=$self->transform($x,$nth,'http://www.w3.org/2001/10/xml-exc-c14n#');
    ok($result,'transform should work correctly');
    cmp_ok($result->get_data,'eq',XML_SignedInfo_canon(),'XML Canon should be correct');
    {
      my $result=$self->get_signed_info_node($x);
      ok($result,"should fetch the signed info node without error");
    }

    {
      my $result=$self->get_digest_method($x);
      ok($result,'should get the digest method without an error') or diag $result;
    }
    {
      my $result=$self->get_digest_value($x);
      ok($result,'should get the digest value without an error') or diag $result;
    }
    {
      my $result=$self->get_digest_node($x);
      ok($result,'should get the digest node without an error') or diag $result;
    }
    {
      my $result=$self->get_transforms($x);
      ok($result,'should get the digest transforms without an error') or diag $result;
      cmp_ok($#{$result->get_data},'==',1,'Should have 2 transforms') or die;
    }
    {
      my $x=$self->build_xpath;
      my ($nth)=$x->findnodes($self->xpath_SignedInfo);
      my $result=$self->verify_signature($x,1);
      ok($result,'should validate the signature') or die $result;
    }

    {
      my $x=$self->build_xpath;
      my ($nth)=$x->findnodes($self->xpath_SignedInfo);
      my $result=$self->verify_digest($x,1);
      ok($result,'Should verify the digest') or die $result;
    }
  }
}

{
  my $id=1;
  my $main=__PACKAGE__;

  my $method="XML_$id";
  while(my $code=$main->can($method)) {
    diag "Validating Sample: $method";

    my $self=$pkg->new($main->$method);
    my $result=$self->validate;
    ok($result);
    my $list=$result->get_data;
    my $result_id=0;
    foreach my $result (@$list) {
      foreach my $key (sort keys %{$result}) {
        my $value=$result->{$key};
        ok($value,"$method test of $key, context position: $result_id") or diag $value;
      }
      ++$result_id;
    }
    $method="XML_".++$id;
  }
}

{

  if(1) {
    my $self=$pkg->new(SIGN_XML1());
    my $x=$self->build_xpath;
    my $result=$self->get_xml_to_sign($x,1);
    ok($result,'ToSign xpath test, should find our xml to sign');
    diag $self->key_type;
    $result=$self->sign;
    ok($result,'Should sign the xml without error');
    my $signed_xml=$result->get_data;
    #diag $signed_xml;
    $self=$pkg->new(xml=>$signed_xml);
    $result=$self->validate;
    #diag Dumper($result);
    ok($result,"Should validate the xml we signed");
  }
  if(1) {
    my $self=$pkg->new(SIGN_XML1(),key_file=>File::Spec->catfile($Bin,'x509_key.pem'),cert_file=>File::Spec->catfile($Bin,'x509_cert.pem'));
    my $result=$self->sign;
    ok($result,'Should sign the using our x509 cert xml without error');
    my $signed_xml=$result->get_data;
    #diag $signed_xml;
    like $signed_xml,qr{<ds:X509Certificate},'Should have signed the xml with an x509 cert since we have it';
    $self=$pkg->new(xml=>$signed_xml);
    $result=$self->validate;
    ok($result,"Should validate the xml signed with the x509 cert");
  }
  if(1) {
    my $self=$pkg->new(SIGN_XML1(),key_file=>File::Spec->catfile($Bin,'x509_key.pem'));
    my $result=$self->sign;
    ok($result,'Should sign the using our rsa key without error');
    my $signed_xml=$result->get_data;
    #diag $signed_xml;
    $self=$pkg->new(xml=>$signed_xml);
    $result=$self->validate;
    ok($result,"Should validate the xml signed with the rsa key");

  }
  if(1){
    my $self=$pkg->new(SIGN_XML1(),key_file=>File::Spec->catfile($Bin,'dsa_priv.pem'));
    my $result=$self->sign;
    ok($result,'Should sign the using our dsa key without error');
    my $signed_xml=$result->get_data;
    #diag $signed_xml;
    $self=$pkg->new(xml=>$signed_xml);
    $result=$self->validate;
    ok($result,"Should validate the xml signed with the dsa key");

  }
  if(1){
    my $self=$pkg->new(xml=>'<?xml version="1.0" standalone="yes"?><data><test ID="A" /><test ID="B" /></data>',key_file=>File::Spec->catfile($Bin,'x509_key.pem'));
    my $result=$self->sign;
    ok($result,'Should sign both chunks using our rsa key without error');
    my $signed_xml=$result->get_data;
    #diag $signed_xml;
    $self=$pkg->new(xml=>$signed_xml);
    $result=$self->validate;
    ok($result,"Should validate both chunks signed with the rsa key");
  }
  if(1) {
    my $self=$pkg->new(xml=>'<?xml version="1.0" standalone="yes"?><data><test ID="A" /><test ID="B" /></data>');
    my $result=$self->validate;
    ok(!$result,'Should fail to validate multiple chunks, when there is no data to validate!');
    is_deeply($result->get_data,[],'Failed result should have an empty array');
  }
}

done_testing;
## BELOW THIS LINE IS SAMPLE XML FOR VALIDATION ##

sub SIGN_XML1 {
 xml=>q{<?xml version="1.0" standalone="yes"?>
<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                    Destination="http://sso.dev.venda.com/opensso"
                    IssueInstant="2019-04-30T22:07:47Z"
                    ID="e4e5f022bef0f941a8c4ff0ab8cb2fea"
                    Version="2.0"
                    ProviderName="My SP's human readable name.">
  <saml:Issuer>http://localhost:3000</saml:Issuer>
  <samlp:NameIDPolicy AllowCreate="1"
                      Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" />
</samlp:AuthnRequest>},
key_file=>'t/sign-nopw-cert.pem';
}

sub XML_Digest_canon {
q{saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="idTV6qR57CrTJM-kapCSHto9QKcpQ" IssueInstant="2019-04-20T00:15:15Z" Version="2.0"><saml:Issuer>https://login.esso-uat.charter.com:8443/nidp/saml2/metadata</saml:Issuer><saml:Subject><saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified" NameQualifier="https://login.esso-uat.charter.com:8443/nidp/saml2/metadata" SPNameQualifier="https://socmon-dev.corp.chartercom.com">mshipper</saml:NameID><saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"><saml:SubjectConfirmationData NotOnOrAfter="2019-04-20T00:20:15Z" Recipient="https://socmon-dev.corp.chartercom.com/Idp/saml/consumer-post"></saml:SubjectConfirmationData></saml:SubjectConfirmation></saml:Subject><saml:Conditions NotBefore="2019-04-20T00:10:15Z" NotOnOrAfter="2019-04-20T00:20:15Z"><saml:AudienceRestriction><saml:Audience>https://socmon-dev.corp.chartercom.com</saml:Audience></saml:AudienceRestriction></saml:Conditions><saml:AuthnStatement AuthnInstant="2019-04-19T22:27:54Z" SessionIndex="idVKIoxjLWnYYmX08J8RPVdyQad44"><saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Kerberos</saml:AuthnContextClassRef><saml:AuthnContextDeclRef>https://login.esso-uat.charter.com:8443/nidp/kerberos/vds/uri</saml:AuthnContextDeclRef></saml:AuthnContext></saml:AuthnStatement><saml:AttributeStatement><saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/sAMAccountName" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"><saml:AttributeValue xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">mshipper</saml:AttributeValue></saml:Attribute></saml:AttributeStatement></saml:Assertion>};
}

sub XML_SignedInfo_canon {
 xml=>q{<ds:SignedInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><CanonicalizationMethod xmlns="http://www.w3.org/2000/09/xmldsig#" Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></CanonicalizationMethod><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"></ds:SignatureMethod><ds:Reference URI="#idTV6qR57CrTJM-kapCSHto9QKcpQ"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></ds:DigestMethod><DigestValue xmlns="http://www.w3.org/2000/09/xmldsig#">aFGVEGqVoZx5wOSez703l81dJWM=</DigestValue></ds:Reference></ds:SignedInfo>}
}
sub XML_1 {
xml=>q{<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" Destination="https://socmon-dev.corp.chartercom.com/Idp/saml/consumer-post" ID="idH8KwdpaJhOWnNnMKM0atozZVLaw" IssueInstant="2019-04-20T00:15:14Z" Version="2.0"><saml:Issuer>https://login.esso-uat.charter.com:8443/nidp/saml2/metadata</saml:Issuer><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status><saml:Assertion ID="idTV6qR57CrTJM-kapCSHto9QKcpQ" IssueInstant="2019-04-20T00:15:15Z" Version="2.0"><saml:Issuer>https://login.esso-uat.charter.com:8443/nidp/saml2/metadata</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><CanonicalizationMethod xmlns="http://www.w3.org/2000/09/xmldsig#" Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/><ds:Reference URI="#idTV6qR57CrTJM-kapCSHto9QKcpQ"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><DigestValue xmlns="http://www.w3.org/2000/09/xmldsig#">aFGVEGqVoZx5wOSez703l81dJWM=</DigestValue></ds:Reference></ds:SignedInfo><SignatureValue xmlns="http://www.w3.org/2000/09/xmldsig#">
D70iZkosc2pk71FRZqnUoMjC1kN10kU30hivx/Aujee1Qd36Ftz/0cJcZX+D8zChXhKm/qWSXnud
dMikBN04OAnXEHC1VGj4JzfqvcXLuVprjRv+xyZ9Ono/aEhF70GgS5HrKPsN9lrVVZzRAlYoN5S1
c8dOWRSF1eZp6+34zVo+bKLe+XqON+cnGlDcGDu+Im4e1wZCc//jz+uon6Ggt6G7d8qeL4kFhCBj
5/CEGeMugc/a+CHd7ItDlWxrBgeTK1dcsCskdln2QtJj43BFbs2WY9S/ocJ/WBq0EH9AxFIjxmUa
3PMygRV7w7S7r+r3eI/hYMLyiShY9qQr+PLVnQ==
</SignatureValue><ds:KeyInfo><ds:X509Data><ds:X509Certificate>
MIIGeTCCBWGgAwIBAgIQDEP6J8wBPirOtNtbOMFM/DANBgkqhkiG9w0BAQsFADBNMQswCQYDVQQG
EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5EaWdpQ2VydCBTSEEyIFNlY3Vy
ZSBTZXJ2ZXIgQ0EwHhcNMTgwNTA0MDAwMDAwWhcNMTkwNTA1MTIwMDAwWjCBvDELMAkGA1UEBhMC
VVMxETAPBgNVBAgTCE1pc3NvdXJpMRQwEgYDVQQHEwtTYWludCBMb3VpczEuMCwGA1UEChMlQ2hh
cnRlciBDb21tdW5pY2F0aW9ucyBPcGVyYXRpbmcsIExMQzEzMDEGA1UECxMqQ2hhcnRlciBDb21t
dW5pY2F0aW9ucyBIb2xkaW5nIENvbXBhbnkgTExDMR8wHQYDVQQDDBYqLmVzc28tdWF0LmNoYXJ0
ZXIuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxgEYHKU22bWmcPBsmOHRcgk2
6kbbPwsXSKEASJ44Y1pQecjMUezD9IJ8G2xyTzRawuR3zSNgtl34FBk77Xij4XBMcmpLHYaxQpF1
pobIZ1nEo7BGNkcRJERCg/uFkifdWfXEj5YQeX/90W8rq2dzza+UsI6g0COGdiYphVNqq4pbXA7l
0FcLZpnhNm4Le2KQQOIK1+oqf8AsBtP/j2QKShzhiqcz01BEvOPbVYdr/7aPK7qMhrn6cIhftk6D
i5lmkkqWojh9TBntz0f3Pg3ZYpm2nHGEW5Iykwa01zaGP6Pg61v1kLsQclmhetZ6ORPehjPsxxWq
+4VdF9tIYA5NzwIDAQABo4IC4zCCAt8wHwYDVR0jBBgwFoAUD4BhHIIxYdUvKOeNRji0LOHG2eIw
HQYDVR0OBBYEFBRYgP6tmV8iTA5e6bwAUCVQnsCGMCEGA1UdEQQaMBiCFiouZXNzby11YXQuY2hh
cnRlci5jb20wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBr
BgNVHR8EZDBiMC+gLaArhilodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc3NjYS1zaGEyLWc2LmNy
bDAvoC2gK4YpaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NzY2Etc2hhMi1nNi5jcmwwTAYDVR0g
BEUwQzA3BglghkgBhv1sAQEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29t
L0NQUzAIBgZngQwBAgIwfAYIKwYBBQUHAQEEcDBuMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
aWdpY2VydC5jb20wRgYIKwYBBQUHMAKGOmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
Q2VydFNIQTJTZWN1cmVTZXJ2ZXJDQS5jcnQwCQYDVR0TBAIwADCCAQUGCisGAQQB1nkCBAIEgfYE
gfMA8QB3ALvZ37wfinG1k5Qjl6qSe0c4V5UKq1LoGpCWZDaOHtGFAAABYyzERvkAAAQDAEgwRgIh
ALV1YgPAvUN+xT2WpGiFBWeciqZdH2VP3Wle4NwmwfDDAiEA5XCGvXAoS9qbtuK/d6z2Q0OvCjiy
IDSBhlE85KtCq8gAdgBvU3asMfAxGdiZAKRRFf93FRwR2QLBACkGjbIImjfZEwAAAWMsxEfjAAAE
AwBHMEUCIQD4uh0hnNNTGmOTtxDNWk0bAZ5pQ9vK1X0vJNXv1hg8kAIgYk6UFO+LmGx6BAaPZKhh
VnoWQjjP/fmWYqt251eZQAYwDQYJKoZIhvcNAQELBQADggEBAEu0kAIDjVBrHroXWfhvC0P06Xlc
bHnJnEklvan4BhLChvEh8UYy6QnLohW9EjDJOkcKWg+bh2XwKOpDlnA6adpBJvQl6k5UnI55JmVq
/dkjQfV1ej7oqCvRoPRhkmf6xdPx2qVL0X5jF1ecBCHRPpf9SviBYvx3enW9gr753eZle7REgmW5
rMfpaChH4rIyHNoaGYkWmjcXXcExGjXrfjWV7prq7t2WtV94Cp3cYJluR1lzhTn+xHB+ql4B0RRm
HaFGXmUFaWjiYUK8bHYul+yzweT6tNkyyccMoM3l+JcxL3x/2zrUZ2Kdt4eg68yaW50XAWTUeL56
QHEICoacURM=
</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature><saml:Subject><saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified" NameQualifier="https://login.esso-uat.charter.com:8443/nidp/saml2/metadata" SPNameQualifier="https://socmon-dev.corp.chartercom.com">mshipper</saml:NameID><saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"><saml:SubjectConfirmationData NotOnOrAfter="2019-04-20T00:20:15Z" Recipient="https://socmon-dev.corp.chartercom.com/Idp/saml/consumer-post"/></saml:SubjectConfirmation></saml:Subject><saml:Conditions NotBefore="2019-04-20T00:10:15Z" NotOnOrAfter="2019-04-20T00:20:15Z"><saml:AudienceRestriction><saml:Audience>https://socmon-dev.corp.chartercom.com</saml:Audience></saml:AudienceRestriction></saml:Conditions><saml:AuthnStatement AuthnInstant="2019-04-19T22:27:54Z" SessionIndex="idVKIoxjLWnYYmX08J8RPVdyQad44"><saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Kerberos</saml:AuthnContextClassRef><saml:AuthnContextDeclRef>https://login.esso-uat.charter.com:8443/nidp/kerberos/vds/uri</saml:AuthnContextDeclRef></saml:AuthnContext></saml:AuthnStatement><saml:AttributeStatement><saml:Attribute xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/sAMAccountName" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"><saml:AttributeValue xsi:type="xs:string">mshipper</saml:AttributeValue></saml:Attribute></saml:AttributeStatement></saml:Assertion></samlp:Response>};

}


sub XML_2 {
 xml=>q{<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_8e8dc5f69a98cc4c1ff3427e5ce34606fd672f91e6" Version="2.0" IssueInstant="2014-07-17T01:01:48Z" Destination="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685">
  <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" ID="pfx0b1c58a3-6898-7be8-fb8b-3939a08b2494" Version="2.0" IssueInstant="2014-07-17T01:01:48Z">
    <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
  <ds:Reference URI="#pfx0b1c58a3-6898-7be8-fb8b-3939a08b2494"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>HZ1amvorf2ZXJzljYK5ySqL4Py8=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>joKLXaV56gSsibe0FpIqzNWTu0o7O36wZ9T510eL2dZD1ZVOueiriRkk96a9qj/IrL8bdGuBLaECPKT0L9B5bOWmiwIV6yVl7i2HqsQpSckmQwV+C0AFF92JILacVD4mlbb0RidxSZxiL90fsshKTO7Hn0TfdyLTQko2f2qFGtg=</ds:SignatureValue>
<ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
    <saml:Subject>
      <saml:NameID SPNameQualifier="http://sp.example.com/demo1/metadata.php" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient">_ce3d2948b4cf20146dee0a0b3dd6f69b6cf86f62d7</saml:NameID>
      <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml:SubjectConfirmationData NotOnOrAfter="2024-01-18T06:21:48Z" Recipient="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685"/>
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Conditions NotBefore="2014-07-17T01:01:18Z" NotOnOrAfter="2024-01-18T06:21:48Z">
      <saml:AudienceRestriction>
        <saml:Audience>http://sp.example.com/demo1/metadata.php</saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AuthnStatement AuthnInstant="2014-07-17T01:01:48Z" SessionNotOnOrAfter="2024-07-17T09:01:48Z" SessionIndex="_be9967abd904ddcae3c0eb4189adbe3f71e327cf93">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="uid" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="mail" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test@example.com</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="eduPersonAffiliation" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">users</saml:AttributeValue>
        <saml:AttributeValue xsi:type="xs:string">examplerole1</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>} }


sub XML_3 {
 xml=>q{<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_8e8dc5f69a98cc4c1ff3427e5ce34606fd672f91e6" Version="2.0" IssueInstant="2014-07-17T01:01:48Z" Destination="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685">
  <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" ID="pfx0b1c58a3-6898-7be8-fb8b-3939a08b2494" Version="2.0" IssueInstant="2014-07-17T01:01:48Z">
    <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
  <ds:Reference URI="#pfx0b1c58a3-6898-7be8-fb8b-3939a08b2494"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>HZ1amvorf2ZXJzljYK5ySqL4Py8=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>joKLXaV56gSsibe0FpIqzNWTu0o7O36wZ9T510eL2dZD1ZVOueiriRkk96a9qj/IrL8bdGuBLaECPKT0L9B5bOWmiwIV6yVl7i2HqsQpSckmQwV+C0AFF92JILacVD4mlbb0RidxSZxiL90fsshKTO7Hn0TfdyLTQko2f2qFGtg=</ds:SignatureValue>
<ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
    <saml:Subject>
      <saml:NameID SPNameQualifier="http://sp.example.com/demo1/metadata.php" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient">_ce3d2948b4cf20146dee0a0b3dd6f69b6cf86f62d7</saml:NameID>
      <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml:SubjectConfirmationData NotOnOrAfter="2024-01-18T06:21:48Z" Recipient="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685"/>
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Conditions NotBefore="2014-07-17T01:01:18Z" NotOnOrAfter="2024-01-18T06:21:48Z">
      <saml:AudienceRestriction>
        <saml:Audience>http://sp.example.com/demo1/metadata.php</saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AuthnStatement AuthnInstant="2014-07-17T01:01:48Z" SessionNotOnOrAfter="2024-07-17T09:01:48Z" SessionIndex="_be9967abd904ddcae3c0eb4189adbe3f71e327cf93">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="uid" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="mail" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test@example.com</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="eduPersonAffiliation" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">users</saml:AttributeValue>
        <saml:AttributeValue xsi:type="xs:string">examplerole1</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>};
}

sub XML_4 {
 xml=>q{<?xml version="1.0"?>
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="pfx265e80ef-ffb6-61ea-9fb9-0454e0e6699e" Version="2.0" IssueInstant="2014-07-17T01:01:48Z" Destination="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685">
  <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
  <ds:Reference URI="#pfx265e80ef-ffb6-61ea-9fb9-0454e0e6699e"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>J+VHcyMlSSFYPJiDePYrjs7BbQ4=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>QDNW4NoHr0tCjsZROWcJTMwML093mN5kKzBuNdxiL5Jty6ss7nArIKwfbT9yDIv0Iq31pCibNTUXwGlcSmmrm4D3TyqeCnJE2xmZALjixlTLFAp+60JVXH6oK1UoxIiDQGyJD3dtroQRmx4qShkUKzkw3VxMdrnef6NAOPBxMtk=</ds:SignatureValue>
<ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" ID="_d71a3a8e9fcc45c9e9d248ef7049393fc8f04e5f75" Version="2.0" IssueInstant="2014-07-17T01:01:48Z">
    <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer>
    <saml:Subject>
      <saml:NameID SPNameQualifier="http://sp.example.com/demo1/metadata.php" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient">_ce3d2948b4cf20146dee0a0b3dd6f69b6cf86f62d7</saml:NameID>
      <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml:SubjectConfirmationData NotOnOrAfter="2024-01-18T06:21:48Z" Recipient="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685"/>
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Conditions NotBefore="2014-07-17T01:01:18Z" NotOnOrAfter="2024-01-18T06:21:48Z">
      <saml:AudienceRestriction>
        <saml:Audience>http://sp.example.com/demo1/metadata.php</saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AuthnStatement AuthnInstant="2014-07-17T01:01:48Z" SessionNotOnOrAfter="2024-07-17T09:01:48Z" SessionIndex="_be9967abd904ddcae3c0eb4189adbe3f71e327cf93">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="uid" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="mail" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test@example.com</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="eduPersonAffiliation" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">users</saml:AttributeValue>
        <saml:AttributeValue xsi:type="xs:string">examplerole1</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>}
}

sub XML_5 {
  xml=>q{<?xml version="1.0"?>
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="pfx4ec80718-157e-7d56-2f8e-0e2ba8da23c4" Version="2.0" IssueInstant="2014-07-17T01:01:48Z" Destination="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685">
  <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
  <ds:Reference URI="#pfx4ec80718-157e-7d56-2f8e-0e2ba8da23c4"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>45S9AM5R0to0BjE2zn8wgd9RvzQ=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>x8aHRlu2Ut7k3P0WesrYl1N7wnFoxfAcQPlLNumdwQPey7o0Q3aJBEsRONqYdtjVsoryMmbI/bHG65nCvWCBs/XVst4RZCjQK5wxsk5YbjrJAODjZAHfzvf8hHeQHOXoIzfyp9b2toaRG43u16+F8t3P1P2fVV90s9dVFSSgf7U=</ds:SignatureValue>
<ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" ID="pfx0dc353b0-20a4-3626-64da-c7580dad063e" Version="2.0" IssueInstant="2014-07-17T01:01:48Z">
    <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
  <ds:Reference URI="#pfx0dc353b0-20a4-3626-64da-c7580dad063e"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>dKvEuaerWU71zqlTuoI8r6uKuqE=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>JdS6/yibokTdqG7ZymDHjJhb51d66rbFMA/6+aJ74xON1OEk/SubbaCB8w/QYUeCyK3iIUF6AEL6Of9t37c13VOzMCv0L1YxZ7z1dMP2aa1kly6iDIdmD68bvyFWXmkIVUtoh/SnKz0orireeDYAZyUGpORFV7ba/M3bHeNFm8Y=</ds:SignatureValue>
<ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
    <saml:Subject>
      <saml:NameID SPNameQualifier="http://sp.example.com/demo1/metadata.php" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient">_ce3d2948b4cf20146dee0a0b3dd6f69b6cf86f62d7</saml:NameID>
      <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml:SubjectConfirmationData NotOnOrAfter="2024-01-18T06:21:48Z" Recipient="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685"/>
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Conditions NotBefore="2014-07-17T01:01:18Z" NotOnOrAfter="2024-01-18T06:21:48Z">
      <saml:AudienceRestriction>
        <saml:Audience>http://sp.example.com/demo1/metadata.php</saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AuthnStatement AuthnInstant="2014-07-17T01:01:48Z" SessionNotOnOrAfter="2024-07-17T09:01:48Z" SessionIndex="_be9967abd904ddcae3c0eb4189adbe3f71e327cf93">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="uid" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="mail" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">test@example.com</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="eduPersonAffiliation" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xsi:type="xs:string">users</saml:AttributeValue>
        <saml:AttributeValue xsi:type="xs:string">examplerole1</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>};
}

sub XML_6 {
  xml=>q{<?xml version="1.0"?>
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="pfx7b68b02b-4b91-2f59-c3cb-49980e136fdf" Version="2.0" IssueInstant="2014-07-17T01:01:48Z" Destination="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685">
  <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
  <ds:Reference URI="#pfx7b68b02b-4b91-2f59-c3cb-49980e136fdf"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>1JSk/zWN6O84DR4ZBpnOZ/MFwRk=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>TG1VyEN+hFDBawmi2qNrHrNBQc0aDYIbZRwUiLGiwK2fBVSCFdiJdyBeqAnvCXCUUEJy0RdY37xQK+nXeOrfivxDrG+4vEyOCsYynd1+zRn+CEJSlDVkRg27SPoLZxBt/Zece67UNSOKY2PIhRGwWHELFsJg86haeEGPO768wBY=</ds:SignatureValue>
<ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:EncryptedAssertion>
    <xenc:EncryptedData xmlns:xenc="http://www.w3.org/2001/04/xmlenc#" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" Type="http://www.w3.org/2001/04/xmlenc#Element"><xenc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-cbc"/><dsig:KeyInfo xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"><xenc:EncryptedKey><xenc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-1_5"/><xenc:CipherData><xenc:CipherValue>xPJAQOA1gvM1KzRoPZGaZ+bOxOkBsQf8CMTWT5l2mt2JrLjA+SIW1/riPfxj2P/pbjh96jCBUbKrxBbTEgQm1iT0XXL5BupxRRXOVaODc4N8lO0hjqYCEHSOJNmJqaouvMOIZqt7mDKhXy25uUbuh9vrhwRkizMCIQZCi9ztDco=</xenc:CipherValue></xenc:CipherData></xenc:EncryptedKey></dsig:KeyInfo>
   <xenc:CipherData>
      <xenc:CipherValue>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</xenc:CipherValue>
   </xenc:CipherData>
</xenc:EncryptedData>
  </saml:EncryptedAssertion>
</samlp:Response>}
}

sub XML_7 {
  xml=>q{<?xml version="1.0"?>
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="pfxc8fc8e54-6f90-4b47-b5cb-9e26784b6eb5" Version="2.0" IssueInstant="2014-07-17T01:01:48Z" Destination="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685">
  <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
  <ds:Reference URI="#pfxc8fc8e54-6f90-4b47-b5cb-9e26784b6eb5"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>5KBiqDQffKdE/QHhOrdaPDJRI0Y=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>OOIlcplgQbcTNTdK/6awjCQevZyT3wTiUIMlGYWbz8lFp63uxy1Lk6cgSU6fQYjDyB1H70KWwsbYL2XQ9PMic05n0BhN2nCh1mvy5gdnlBBvjAcJriWf8TRd3NSt+Tr+UtS3Rzot9UMSNfUUzgR+80yCeyZ7SQrE6sgRdhlzmNc=</ds:SignatureValue>
<ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:EncryptedAssertion>
    <xenc:EncryptedData xmlns:xenc="http://www.w3.org/2001/04/xmlenc#" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" Type="http://www.w3.org/2001/04/xmlenc#Element"><xenc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-cbc"/><dsig:KeyInfo xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"><xenc:EncryptedKey><xenc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-1_5"/><xenc:CipherData><xenc:CipherValue>tQz8+wLVfBS99roOiy+GM0nmAADhOC7tiJpA6cCqcbcVTWGMYVGZ7KnPR/rwSOO42fJGdUNQePkgwIpH6kIAK+JWA3uGuNv9doozpx2bbft1ef70muGWqz065FNP8YcRg3GylaIv/ZzhpeBOl8UavFfQJqHra5MW698A0PxobV0=</xenc:CipherValue></xenc:CipherData></xenc:EncryptedKey></dsig:KeyInfo>
   <xenc:CipherData>
      <xenc:CipherValue>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</xenc:CipherValue>
   </xenc:CipherData>
</xenc:EncryptedData>
  </saml:EncryptedAssertion>
</samlp:Response>},

}

sub XML_8 {
my $xml=decode_base64(q{PHNhbWxwOlJlc3BvbnNlIHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJvdG9jb2wiIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIElEPSJwZngxYmRkMzhjMS04OTljLWMyNTktZjU4Ni1hM2QzNjU3MWViZWYiIFZlcnNpb249IjIuMCIgSXNzdWVJbnN0YW50PSIyMDE0LTAzLTIxVDEzOjQyOjMxWiIgRGVzdGluYXRpb249Imh0dHBzOi8vcGl0YnVsay5uby1pcC5vcmcvbmV3b25lbG9naW4vZGVtbzEvaW5kZXgucGhwP2FjcyIgSW5SZXNwb25zZVRvPSJPTkVMT0dJTl8xOTFjMDNlNjhkNzFkOTc5NmY1ZTA3ZTYyNjJjYTRhZDg4M2E3NGIxIj48c2FtbDpJc3N1ZXI+aHR0cHM6Ly9waXRidWxrLm5vLWlwLm9yZy9zaW1wbGVzYW1sL3NhbWwyL2lkcC9tZXRhZGF0YS5waHA8L3NhbWw6SXNzdWVyPjxkczpTaWduYXR1cmUgeG1sbnM6ZHM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyMiPgogIDxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+CiAgICA8ZHM6U2lnbmF0dXJlTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI3JzYS1zaGExIi8+CiAgPGRzOlJlZmVyZW5jZSBVUkk9IiNwZngxYmRkMzhjMS04OTljLWMyNTktZjU4Ni1hM2QzNjU3MWViZWYiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPnZqVjZNT1VsaWpXVEU1M3dac2N1Z0dZN05oRT08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+RWJnWDZHenRYME9GNkpWZ0IyMElRMVBhUDYvMlpzanh6SHNFdHEzK0hMeG1ZbG5lYkVhalFIMzJWbTJ0UERwclRMdkRtaGZWd1NaZEtLaEFoNGtoc3YxODN1Q3pVdU5GTmZneWx0WVFmem91UlhGZ0ZOdUJKU1IwOTRkWFc2THVqRm5TbHk0VGNScThzSG5YZ0p6V3h1V0ltKzc3TjVOemtYajRxRXFSQXdVPTwvZHM6U2lnbmF0dXJlVmFsdWU+CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNnVENDQWVvQ0NRQ2JPbHJXRGRYN0ZUQU5CZ2txaGtpRzl3MEJBUVVGQURDQmhERUxNQWtHQTFVRUJoTUNUazh4R0RBV0JnTlZCQWdURDBGdVpISmxZWE1nVTI5c1ltVnlaekVNTUFvR0ExVUVCeE1EUm05dk1SQXdEZ1lEVlFRS0V3ZFZUa2xPUlZSVU1SZ3dGZ1lEVlFRREV3OW1aV2xrWlM1bGNteGhibWN1Ym04eElUQWZCZ2txaGtpRzl3MEJDUUVXRW1GdVpISmxZWE5BZFc1cGJtVjBkQzV1YnpBZUZ3MHdOekEyTVRVeE1qQXhNelZhRncwd056QTRNVFF4TWpBeE16VmFNSUdFTVFzd0NRWURWUVFHRXdKT1R6RVlNQllHQTFVRUNCTVBRVzVrY21WaGN5QlRiMnhpWlhKbk1Rd3dDZ1lEVlFRSEV3TkdiMjh4RURBT0JnTlZCQW9UQjFWT1NVNUZWRlF4R0RBV0JnTlZCQU1URDJabGFXUmxMbVZ5YkdGdVp5NXViekVoTUI4R0NTcUdTSWIzRFFFSkFSWVNZVzVrY21WaGMwQjFibWx1WlhSMExtNXZNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdOQURDQmlRS0JnUURpdmJoUjdQNTE2eC9TM0JxS3h1cFFlMExPTm9saXVwaUJPZXNDTzNTSGJEcmwzK3E5SWJmbmZtRTA0ck51TWNQc0l4QjE2MVRkRHBJZXNMQ243YzhhUEhJU0tPdFBsQWVUWlNuYjhRQXU3YVJqWnEzK1BiclA1dVczVGNmQ0dQdEtUeXRIT2dlL09sSmJvMDc4ZFZoWFExNGQxRUR3WEpXMXJSWHVVdDRDOFFJREFRQUJNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0R0JBQ0RWZnA4NkhPYnFZK2U4QlVvV1E5K1ZNUXgxQVNEb2hCandPc2cyV3lrVXFSWEYrZExmY1VIOWRXUjYzQ3RaSUtGRGJTdE5vbVBuUXo3bmJLK29ueWd3QnNwVkVibkh1VWloWnEzWlVkbXVtUXFDdzRVdnMvMVV2cTNvck9vL1dKVmhUeXZMZ0ZWSzJRYXJRNC82N09aZkhkN1IrUE9CWGhvcGhTTXYxWk9vPC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PHNhbWxwOlN0YXR1cz48c2FtbHA6U3RhdHVzQ29kZSBWYWx1ZT0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOnN0YXR1czpTdWNjZXNzIi8+PC9zYW1scDpTdGF0dXM+PHNhbWw6QXNzZXJ0aW9uIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zOnhzPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSIgSUQ9InBmeGQzNGZiMGMzLTFkZmItY2EzZS1iMjYzLWEyYWFhMGJlZWRlNyIgVmVyc2lvbj0iMi4wIiBJc3N1ZUluc3RhbnQ9IjIwMTQtMDMtMjFUMTM6NDI6MzFaIj48c2FtbDpJc3N1ZXI+aHR0cHM6Ly9waXRidWxrLm5vLWlwLm9yZy9zaW1wbGVzYW1sL3NhbWwyL2lkcC9tZXRhZGF0YS5waHA8L3NhbWw6SXNzdWVyPjxkczpTaWduYXR1cmUgeG1sbnM6ZHM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyMiPgogIDxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+CiAgICA8ZHM6U2lnbmF0dXJlTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI3JzYS1zaGExIi8+CiAgPGRzOlJlZmVyZW5jZSBVUkk9IiNwZnhkMzRmYjBjMy0xZGZiLWNhM2UtYjI2My1hMmFhYTBiZWVkZTciPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPmlUem5CamF3U09EUFZVRVAwVWpvMTdoM1RNWT08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+TXB4Ny9LL29OUVlIbm15aVdDdEdod3FoVzZtOG5zcnhMYSs5LzQ2dTJuenU5NDMxdm1TQWZPQmF2RURjL3JnNGRYeTRWZmZyejNINFVvUEQyeFNpODFJOU1kVDl1WHRYQkJGUytVN0xIb3VyVjB4VFU0clhDajd3ZmdkbkpMVmprSnVUeWZRMXhsd2VJNzRLSUdLOGZvMVlaYmY5TGREZUE4TURCWDZXN3VBPTwvZHM6U2lnbmF0dXJlVmFsdWU+CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNnVENDQWVvQ0NRQ2JPbHJXRGRYN0ZUQU5CZ2txaGtpRzl3MEJBUVVGQURDQmhERUxNQWtHQTFVRUJoTUNUazh4R0RBV0JnTlZCQWdURDBGdVpISmxZWE1nVTI5c1ltVnlaekVNTUFvR0ExVUVCeE1EUm05dk1SQXdEZ1lEVlFRS0V3ZFZUa2xPUlZSVU1SZ3dGZ1lEVlFRREV3OW1aV2xrWlM1bGNteGhibWN1Ym04eElUQWZCZ2txaGtpRzl3MEJDUUVXRW1GdVpISmxZWE5BZFc1cGJtVjBkQzV1YnpBZUZ3MHdOekEyTVRVeE1qQXhNelZhRncwd056QTRNVFF4TWpBeE16VmFNSUdFTVFzd0NRWURWUVFHRXdKT1R6RVlNQllHQTFVRUNCTVBRVzVrY21WaGN5QlRiMnhpWlhKbk1Rd3dDZ1lEVlFRSEV3TkdiMjh4RURBT0JnTlZCQW9UQjFWT1NVNUZWRlF4R0RBV0JnTlZCQU1URDJabGFXUmxMbVZ5YkdGdVp5NXViekVoTUI4R0NTcUdTSWIzRFFFSkFSWVNZVzVrY21WaGMwQjFibWx1WlhSMExtNXZNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdOQURDQmlRS0JnUURpdmJoUjdQNTE2eC9TM0JxS3h1cFFlMExPTm9saXVwaUJPZXNDTzNTSGJEcmwzK3E5SWJmbmZtRTA0ck51TWNQc0l4QjE2MVRkRHBJZXNMQ243YzhhUEhJU0tPdFBsQWVUWlNuYjhRQXU3YVJqWnEzK1BiclA1dVczVGNmQ0dQdEtUeXRIT2dlL09sSmJvMDc4ZFZoWFExNGQxRUR3WEpXMXJSWHVVdDRDOFFJREFRQUJNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0R0JBQ0RWZnA4NkhPYnFZK2U4QlVvV1E5K1ZNUXgxQVNEb2hCandPc2cyV3lrVXFSWEYrZExmY1VIOWRXUjYzQ3RaSUtGRGJTdE5vbVBuUXo3bmJLK29ueWd3QnNwVkVibkh1VWloWnEzWlVkbXVtUXFDdzRVdnMvMVV2cTNvck9vL1dKVmhUeXZMZ0ZWSzJRYXJRNC82N09aZkhkN1IrUE9CWGhvcGhTTXYxWk9vPC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PHNhbWw6U3ViamVjdD48c2FtbDpOYW1lSUQgU1BOYW1lUXVhbGlmaWVyPSJodHRwczovL3BpdGJ1bGsubm8taXAub3JnL25ld29uZWxvZ2luL2RlbW8xL21ldGFkYXRhLnBocCIgRm9ybWF0PSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6bmFtZWlkLWZvcm1hdDp0cmFuc2llbnQiPl8yMTI2ZGQxOWI4YTlhMjgyMzhkODhmZGM3Mzg1ZTYwOTk1MDA0YTc3ODI8L3NhbWw6TmFtZUlEPjxzYW1sOlN1YmplY3RDb25maXJtYXRpb24gTWV0aG9kPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6Y206YmVhcmVyIj48c2FtbDpTdWJqZWN0Q29uZmlybWF0aW9uRGF0YSBOb3RPbk9yQWZ0ZXI9IjIwMjMtMDktMjJUMTk6MDI6MzFaIiBSZWNpcGllbnQ9Imh0dHBzOi8vcGl0YnVsay5uby1pcC5vcmcvbmV3b25lbG9naW4vZGVtbzEvaW5kZXgucGhwP2FjcyIgSW5SZXNwb25zZVRvPSJPTkVMT0dJTl8xOTFjMDNlNjhkNzFkOTc5NmY1ZTA3ZTYyNjJjYTRhZDg4M2E3NGIxIi8+PC9zYW1sOlN1YmplY3RDb25maXJtYXRpb24+PC9zYW1sOlN1YmplY3Q+PHNhbWw6Q29uZGl0aW9ucyBOb3RCZWZvcmU9IjIwMTQtMDMtMjFUMTM6NDI6MDFaIiBOb3RPbk9yQWZ0ZXI9IjIwMjMtMDktMjJUMTk6MDI6MzFaIj48c2FtbDpBdWRpZW5jZVJlc3RyaWN0aW9uPjxzYW1sOkF1ZGllbmNlPmh0dHBzOi8vcGl0YnVsay5uby1pcC5vcmcvbmV3b25lbG9naW4vZGVtbzEvbWV0YWRhdGEucGhwPC9zYW1sOkF1ZGllbmNlPjwvc2FtbDpBdWRpZW5jZVJlc3RyaWN0aW9uPjwvc2FtbDpDb25kaXRpb25zPjxzYW1sOkF1dGhuU3RhdGVtZW50IEF1dGhuSW5zdGFudD0iMjAxNC0wMy0yMVQxMzo0MTowOVoiIFNlc3Npb25Ob3RPbk9yQWZ0ZXI9IjIwMTQtMDMtMjFUMjE6NDI6MzFaIiBTZXNzaW9uSW5kZXg9Il9lNjU3OGQ2YWY5N2I5ZjdmMDY3MmQ4NTBkMjlkYjRhZGQxYTI4NmRjMjQiPjxzYW1sOkF1dGhuQ29udGV4dD48c2FtbDpBdXRobkNvbnRleHRDbGFzc1JlZj51cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YWM6Y2xhc3NlczpQYXNzd29yZDwvc2FtbDpBdXRobkNvbnRleHRDbGFzc1JlZj48L3NhbWw6QXV0aG5Db250ZXh0Pjwvc2FtbDpBdXRoblN0YXRlbWVudD48c2FtbDpBdHRyaWJ1dGVTdGF0ZW1lbnQ+PHNhbWw6QXR0cmlidXRlIE5hbWU9InVpZCIgTmFtZUZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1hdDpiYXNpYyI+PHNhbWw6QXR0cmlidXRlVmFsdWUgeHNpOnR5cGU9InhzOnN0cmluZyI+dGVzdDwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6QXR0cmlidXRlPjxzYW1sOkF0dHJpYnV0ZSBOYW1lPSJtYWlsIiBOYW1lRm9ybWF0PSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXR0cm5hbWUtZm9ybWF0OmJhc2ljIj48c2FtbDpBdHRyaWJ1dGVWYWx1ZSB4c2k6dHlwZT0ieHM6c3RyaW5nIj50ZXN0QGV4YW1wbGUuY29tPC9zYW1sOkF0dHJpYnV0ZVZhbHVlPjwvc2FtbDpBdHRyaWJ1dGU+PHNhbWw6QXR0cmlidXRlIE5hbWU9ImNuIiBOYW1lRm9ybWF0PSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXR0cm5hbWUtZm9ybWF0OmJhc2ljIj48c2FtbDpBdHRyaWJ1dGVWYWx1ZSB4c2k6dHlwZT0ieHM6c3RyaW5nIj50ZXN0PC9zYW1sOkF0dHJpYnV0ZVZhbHVlPjwvc2FtbDpBdHRyaWJ1dGU+PHNhbWw6QXR0cmlidXRlIE5hbWU9InNuIiBOYW1lRm9ybWF0PSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXR0cm5hbWUtZm9ybWF0OmJhc2ljIj48c2FtbDpBdHRyaWJ1dGVWYWx1ZSB4c2k6dHlwZT0ieHM6c3RyaW5nIj53YWEyPC9zYW1sOkF0dHJpYnV0ZVZhbHVlPjwvc2FtbDpBdHRyaWJ1dGU+PHNhbWw6QXR0cmlidXRlIE5hbWU9ImVkdVBlcnNvbkFmZmlsaWF0aW9uIiBOYW1lRm9ybWF0PSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXR0cm5hbWUtZm9ybWF0OmJhc2ljIj48c2FtbDpBdHRyaWJ1dGVWYWx1ZSB4c2k6dHlwZT0ieHM6c3RyaW5nIj51c2VyPC9zYW1sOkF0dHJpYnV0ZVZhbHVlPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPmFkbWluPC9zYW1sOkF0dHJpYnV0ZVZhbHVlPjwvc2FtbDpBdHRyaWJ1dGU+PC9zYW1sOkF0dHJpYnV0ZVN0YXRlbWVudD48L3NhbWw6QXNzZXJ0aW9uPjwvc2FtbHA6UmVzcG9uc2U+});
  xml=>$xml,
}
sub XML_9 {
my $xml=decode_base64(q{PHNhbWxwOlJlc3BvbnNlIHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJvdG9jb2wiIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIElEPSJfYzdmNjk1NTk1MTFhNTU1YWMwM2E5YTM1ZTk1NTI3YTlhMmE3MjZmYWQwIiBWZXJzaW9uPSIyLjAiIElzc3VlSW5zdGFudD0iMjAxNC0wOS0yNFQwMDo0OTo0OVoiIERlc3RpbmF0aW9uPSJodHRwOi8vcHl0b29sa2l0LmNvbTo4MDAwLz9hY3MiIEluUmVzcG9uc2VUbz0iT05FTE9HSU5fZmQ3OGQ4YTYyMmQwMDEwNzcxOTMyODcwNzI0ZjM4NDM4MTZkMzk4YSI+PHNhbWw6SXNzdWVyPmh0dHBzOi8vaWRwLmV4YW1wbGUuY29tL3NpbXBsZXNhbWwvc2FtbDIvaWRwL21ldGFkYXRhLnBocDwvc2FtbDpJc3N1ZXI+PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgPGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz4KICAgIDxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz4KICA8ZHM6UmVmZXJlbmNlIFVSST0iI19jN2Y2OTU1OTUxMWE1NTVhYzAzYTlhMzVlOTU1MjdhOWEyYTcyNmZhZDAiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPlRoeHRtcHY1QUF2SGY2bXl0K0RMWHg1SW9DST08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+MTNRaFp3VDgzbk5tVVMyNmZHVkptQ29NZUw1SzNrcXNaS2xKMWJxWWd2cTBOTHZyRUo0YVh6TTVHTElrN21idjR3UysxRkQ1MTgxdVVJVWRURjNJWHJNeW04R215NXhYcVk2MVYrYWR6YlJIYnIzamZqdlFnaXlJdWcvUE9rWkxpSWhTTHVxLy9tb2FXYXRBQXB0dWVCYU5lOVFQb3N0N3pXSlpJc2EweXRRPTwvZHM6U2lnbmF0dXJlVmFsdWU+CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNiRENDQWRXZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRMEZBREJUTVFzd0NRWURWUVFHRXdKMWN6RVRNQkVHQTFVRUNBd0tRMkZzYVdadmNtNXBZVEVWTUJNR0ExVUVDZ3dNVDI1bGJHOW5hVzRnU1c1ak1SZ3dGZ1lEVlFRRERBOXBaSEF1WlhoaGJYQnNaUzVqYjIwd0hoY05NVFF3T1RJek1USXlOREE0V2hjTk5ESXdNakE0TVRJeU5EQTRXakJUTVFzd0NRWURWUVFHRXdKMWN6RVRNQkVHQTFVRUNBd0tRMkZzYVdadmNtNXBZVEVWTUJNR0ExVUVDZ3dNVDI1bGJHOW5hVzRnU1c1ak1SZ3dGZ1lEVlFRRERBOXBaSEF1WlhoaGJYQnNaUzVqYjIwd2daOHdEUVlKS29aSWh2Y05BUUVCQlFBRGdZMEFNSUdKQW9HQkFPV0ErWUhVN2N2UE9yQk9meENzY3NZVEpCK2tIM01hQTlCRnJTSEZTK0tjUjZjdzdvUFNrdElKeFVndkRwUWJ0Zk5jT2tFL3R1T1BCRG9lY2g3QVhmdkg2ZDdCdzd4dFc4UFBKMm1CNUhuL0hHVzJyb1loeG1maDN0UjVTZHdONmk0RVJWRjhlTGt2d0NIc05ReUsyUmVmMERBSnZwQk5aTUhDcFMyNDkxNi9BZ01CQUFHalVEQk9NQjBHQTFVZERnUVdCQlE3Ny9xVmVpaWdmaFlESVRwbENOdEpLWlRNOERBZkJnTlZIU01FR0RBV2dCUTc3L3FWZWlpZ2ZoWURJVHBsQ050SktaVE04REFNQmdOVkhSTUVCVEFEQVFIL01BMEdDU3FHU0liM0RRRUJEUVVBQTRHQkFKTzJqLzF1TzgwRTVDMlBNNkZrOW16ZXJyYmt4bDdBWi9tdmxiT24rc05aRStWWjFBbnRZdUc4ZWtiSnBKdEcxWWZSZmM3RUE5bUV0cXZ2NGRodjd6Qnk0bks0OU9SK0twSUJqSXRXQjVrWXZycU1MS0JhMzJzTWJncXFVcWVGMUVOWEtqcHZMU3VQZGZHSlpBM2ROYS8rRHliOEdHcVdlNzA3ekx5YzVGOG08L2RzOlg1MDlDZXJ0aWZpY2F0ZT48L2RzOlg1MDlEYXRhPjwvZHM6S2V5SW5mbz48L2RzOlNpZ25hdHVyZT48c2FtbHA6U3RhdHVzPjxzYW1scDpTdGF0dXNDb2RlIFZhbHVlPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6c3RhdHVzOlN1Y2Nlc3MiLz48L3NhbWxwOlN0YXR1cz48c2FtbDpFbmNyeXB0ZWRBc3NlcnRpb24+PHhlbmM6RW5jcnlwdGVkRGF0YSB4bWxuczp4ZW5jPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyMiIHhtbG5zOmRzaWc9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyMiIFR5cGU9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI0VsZW1lbnQiPjx4ZW5jOkVuY3J5cHRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNhZXMxMjgtY2JjIi8+PGRzaWc6S2V5SW5mbyB4bWxuczpkc2lnPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjIj48eGVuYzpFbmNyeXB0ZWRLZXk+PHhlbmM6RW5jcnlwdGlvbk1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3JzYS1vYWVwLW1nZjFwIi8+PHhlbmM6Q2lwaGVyRGF0YT48eGVuYzpDaXBoZXJWYWx1ZT56SFNWUW9LdktScGg4Q0x5VVNxeWhBMkVPanB3UU93dDkwNlA4bUFVeE5pRlZ3WjBiMWgwcGR4RnpMdkJsT05wSDlZMWFFOVZ3aGg4UnRSNDdYc3ptMXBUbjJBbFZ2R3g2SDZtVE1aS2NYbmppeDYrZTA4WmREY1ZHUHFFd09KNWpqQVpvKzFjTHowLzV3VG9MRzZpZ0FlWDEvZi9WVDhLdG9PQXVZSWFCbTA9PC94ZW5jOkNpcGhlclZhbHVlPjwveGVuYzpDaXBoZXJEYXRhPjwveGVuYzpFbmNyeXB0ZWRLZXk+PC9kc2lnOktleUluZm8+CiAgIDx4ZW5jOkNpcGhlckRhdGE+CiAgICAgIDx4ZW5jOkNpcGhlclZhbHVlPkVOdGFJbDBVVndBcmpvNXo4Zm81d1d0MFExeWV5ekFZKzE3K0RzZktiM1NqTERuVjJiTXVOZHM2dFRRcGF2WnBEYU0rZW0xOVo1Q2JRbUlzVENON2xsVUxOUzJuTEFhckF4U2dJNGxkTitpZ1RIWTMxWDVzNUNMN1NacFBzVG11dWs2OUJlaHF2WGZrclBhRDlDMHpaTVlYcjllcEozbm9reXk2NnBrS3JlZ2dsZEpOem1leWc1SWdSWjdkbG1JQ2duUE1yUmRwZnNLMC9jUjkzbGw5d2hJVGNYV2l6VG9MWWtZMUkrSUptTWRORVk5a1F6L0hDVEQ0SUNsYmhEUzJwUXAxWG51YzM4Q05lTzU4Rk4vSHhVUnhRckRMUHFNUWV2Tlo0alBObktZdUQwcFlzbHl0V1U4aGd4dGtYWWZ6T3R5Nll2VFArUFhjdmhybUMzRHNZUXRDSURBU09nTENkQUtNVmxVc3owemxnbTZGalkwQitsc3ZTWE9sVko0OU83Ymx6Z3ZYKzNSZVVsSHB3RFZ4Nm5welVNWW5iWFJ3Ky9SSlNZeW01b2U5M1krMGttaEpkSzBiWlVMY1lOZWVnTWVtVXJyUjN3Q1dyeTZPZTZ1YUVxWVNFdXJrcytYS2hQdS9PS1dHOHZ5TWhPZ0FrTVdMbzQ0N1NGM2lPQTAydldYZUNVbSt0dEpxdmVwamVxOTJVZ1FoSDVjZWo2dW1Gb2lnSTlFOHJsZ0xnem1jYnd4aG14UWprOG5jaDc0d0FKbWFhT1JjNjYvRWtBK1hwUnN5SXhKWG51VmlLWWt3bjMzNjZJSTJaenpnUUU5UWhOM0lYbE1COHp5a2pFczl5aW43V0JqZy9Id0xwT1d5VG1NY2FMcDhMVmdTNlpXR29TY21Gc29jeDluQkNvSmJuU3NRanV2a3VPbVRtMHlORHFGRzNmVWRsWUlSdzh1QWlTM2ZweWttclJpd081V3BnWFRIMnBYUFFzWFpDdlltQXorbDJUUU5YendOejY2Y2FGck9wdm5MUW52bTJWRDg2a3JaaXhKRGRWZDZaOEhoRjJRSHpNamdLN1hCOG9wcjhwK2ZqN3BrY2JwenRaV2Y3RVNFUnNuWlBHT3VwWTlTLy9ZQjc0c0pDaTNhamczYmdsbEhIN0MrbGlnQWFkd0NDRjViWjRsT1RxY1M3VFVJMjlLNDRKMmZrS2VWeThBVnVZVXNxZ3NWSjd2WGtzNUljMnFoc1FSdStzY2NzOFR0Y0dYSFowalRhUkU4ei9JT1VmdXdCNUFLNC8vV1hNLzVZekEwWEhnSmpIUVpueHhieTdvdlNaYnNvYXVxRFMxTHJhOWtIUFhpZTlvZHlQbmpobExXb1d0WTBodW9EUUR0K3N1aHpyYTF4RzJ6MUh4UmEvRFZVREhKR2FCR29sMFRLQ0FmbXVkMUlqb05VVzdYVVN1d21VSVdVb0drbVNRTy9EYTVYQXhEV1lHVHVuMUdBcmdyTEwzVkJPNGJ6WEMybG1pNUl1OWhqQTJlZ3JRWTBQVit0WkJkTnpCdkxRYTY3RlJqR0hjd1lneDh6ZW9TSGVGRkVUcHBUeHIxWGdicHBVV1lLUjF2V1NvMjdhcXFjeVhTbnVHMUpCSmJOeEdDbjR4SU4yR2RMOXQ5VzNKa2NXUGRSeGE2K1ZuSyszbHpKNGVNNzBtekhaY2ZMQTJLaURYUmhjVG1oU1lGKzZJWThxREdYQXBWMXdld1BSRXZPNWozL21lOTdPVUlIY0cwaFRZTnhhbjhucG1XMmVMVU53ZnpjZE1JNzNhaUsrWk5FTXNkY1hRMnFMSittc0I0dzVYRHBNaHFxMGhYZ3NsZmF6eFZ0Q3E3VWJqS2tENlVRc1pWTHZZSTduYjJUOG9QMlVabUZFUlNDdU5sZys2M3JDTU1lOXd2NnZWMkdUM0RqZHU4Vi9IQzgrMUlXRUtaZEJOM3UvaVNUdEhZTnFtTUdCMVJ4Q0tRWVZrY3hDUzJRV0VrL2hoaGJndEJNOU5KY1BScHJqVS9oSHR6ZFB5UTNNckFLR05sRXBJeGpJNjRkbEdmall5T1JpWDZiTGs5aU5tdmJ4SXl6YnQxSzg0WlNsbTZJTDlXZDVUSmlMdGR5d2lqTlFQZkNVOUxSdkw4NUZYL1RtS3lqOENxenJXcGFZSEp6S0p6RUVUeFMwRldzMnJvcDJURXhrclFjWHlzUjQzNFhMUmE2SHRyVUNjMkNEV2g1dmkxMUF0ZUpCOHhzSVJFYXp1blQ3blBkb0I5NjNaMWFFa1VscTFjb0NieHZnTThxSS9nemZLUDVORmJPRHNJVFdMcVlvTHZaQ2pYSU9jYWdTWGt0Z240YkRGL3hlUG1vMHgxdXJlY0oyMHBJZ2tXM0J5RFFxOWc2YWk5NWdLY1ZZU3FhYXYxLzl1ZXoxK0VzWEZHYVJMU0o3ZTVWZTIxOW1mTGc5T1hrSldWdkZSeFFTVkROWkJWeWRqcUlZd013YjdaQXB4Zkp1OFJGSnQyNTdVT3VDeTBTZWFuRFBFa2M3NlZRekh6MmlBWkhvbitRQ2l4OUVXdXg1dWZEOWRmUmwzc05tOWljMmxUUFZRbm5Sb2NGTjRpdWFyZjQvVkp2dW1uQnlhdmV2Z3g3aXJwdFZmT3lZQWF2YkMzUzByREVaRms2VTBMZUNGd1pPalJjZEVhZDRjeEZYMEI4NndtYXVQSkF2ZTVmaXRJd29GNkpuUkZEK2x4c2N2RUxKYVlFVEF0RkFwN2ljS0JPTi9rNGdzeUs2TGd3NFEvcFNWWXducnBua2t3byszQXJSbUlwdTE5ZVowcHN1QjV6dnFJbkFTV09naGRsZHo4YWdQaXA0N3lSZisrcnE2NHp5RE5TZGVXSTM3ZUVWYkVpd1h5eHRSR3RFSWtRa2drdG05VEU5MCt5eHIrTVo0RmxQU0NKTFkwUDN6WGNFZ2hMZzJUUC84ZXBwUVljcUlJd0pCUWZ6S21CN3pta3FOd0ZZQkhVck05VVRCRlVMVkdhbXpEQnQ4UzNVc0g5OHV0MHlOeUxLSThueEh3V3lnSGFzaGUybVFpUlRDV1l4MGdUc2l5NTN0aVMySHpmRFZmTDM4U0VkNXFqUWUyR1ZVUTlJakt0N05mMUlSQ2dZblRYTVk3KzQ3eUpaYkVJcithZGRIRXFadk9mQWpKY2ZpcUc1eEp1MGhWV01vTThvemFkWkxCN2pUR2dGTERCTHdXTjBvVEVHNVo5Wm81SXlNYmVlWHYxZFc2ZWNLSjJkd2dnb1VxMytmWmN0NVcwbldERHhWSjZRdEQzbHFrZjdzNm9XdmFRcHhHL1ZnRXA4L1NKZnNSekNnbm1XWVFqUWtDclUxbldUREVHWkhuUGtpbUh5RHRaNUJ3REJGZVhVdHQ5R3Nwdk1CNHUwdjYzcmF6bVAwMVdiT2hBVDd0Y0dBQVZzM2ZhTGpvaEd0NTlraVljQkR0cEllZjAzdjBhT2VtOS9wTjNPYW1nM0dUTzc3MG1LS1dDTTNEM2JQejAzNng3cHpWZCtrSUtCZjFtMkF5WDFmMTRKS2VHQmJWUlAxcmIxaXh0OGVKdGVxSHdLRXd2NFRUKzhPeU5GR1F5eVNCQ2d0R1lzdjkrRm1KN2pNeWpNOHJHb2lUTmxQb0pCMlVDcERKT2M5SlVaOVVYa3k4THFCRE95d2pyTzBBL0h1UFdXWnc1RWEyUktkenFNQkxON2JXRktvREtsK3VIblJCcTRzcU5EWUhmeHEvUml5ejRsVlRXYlUvMVV6akpGSzF6UisyYlJzN1piOUtxbzU4ZHVHekV5V1Q5Tk94M0wvSEowUVNYQ0hRSk41YXRDZ2JNVEJTMEtGQmdLSGpTS1FiYWVYS0l6a3FJSkQ5US85ZkJaMGZuOVMwd2tTNlJ6Nk84SWpxWGpQMXdpT0RoT1VGVjdrRlJjSVdQM1ZIVTFtN0ZGcGJpY1RuREdvczBPV01pRWt3VW8vcWZTRFhOQ0FKNFY0b2x5M244bUZSL2JTaDZHRmJpc1VUTmJmQnBDcmZUeFRlaCtJNGFkVlU2dUIyaTl5ZmtWSVFaSjR5QnZ2M1c5NnlaV2dmcXh4M1BKN25GTW0wODdqb2FYMTcwM2tSL3NzbllEVHZFOXlCL1ZGS0J1VnkzQk5oREl2cVRXcDVlNFhJV0lUK0RYL1Uxb3FEb2lDNnVtcHZKUVJVY1R4UUx5RGp6ZEtmNW8yMzRGUkQ3d1NVQVpYa1B5UVR2SmdtVnJzbCtJdDNaazQ4MVhOd01wdG9iZWRHR0ZlUFJ4T3dyNWtQTlRYSHFxL2xkZmlCcENtQzJZQUxkZEV1NDExdk9TYXhUc2JqSGNaRDVlblE0cmR4K1RrelIzbGdkL2lVd0RHSUZpYnU5ZVdkWkx2YWZEV3gxOXJhUGxJRUl1TkJ4dGZsU0IyOWlVaEljeUxFQUtQUy90eTBvWGQ5VTQ2UkZscDA2UlNyY1ArVU1FQWxqN2dqamZuM3MxZmlRc1d1cnhqb2YxZDFad1EwVUFxdzRGSWxpaFpZZU40UVRXYVd6c2FJWXlNcWdmZjNqTVFTSFNMYVJLUHF1S1RFTEJJT0txaU9iVk1hVUdGRndWeGgvNC9rblVHa25LZFFzZTl5c0dJZzBlR2s0OXhRZy9RVkFDVU13N1lqQ2hVdnNqa3U5dkhQUks0Z0RwZWtzM0d3SDlDclVrRGV2cHk2NTZiZi96bUF4dlZnS3NVUU5HUVA1eXJ5dDd4cDB0OEpIbHQ5K054ZHYyL2tVbFpuQlQyUnh6Rm04bDBhWVFRR3ZFSGY4K25TNHl4ejRVMFMyY0dRb2xKYWRyM0l2em9DdndNNVNiNXV6MFJVNnU0cjg0TkV4cllxRDRORWRSeHhRelF4Tm91T2ZvMlRKRGFBUktUMXZndi9lS2hzeFo3bnRaRWx5K2pKTlN0ZHc5cXdmSG0wZVJwR2QxRTlFZytOZEF1cTRCR2ErYzBseEp6ZnU3R0VOVndsd0R2MkUrSjhUb2JpbktkaWlWdzg2V1VYVFFNZnp1Qkg4NmZhdzYyYTV5TXJSZnhEMnViQlQ4Y2FJMGM1aDRqc2hvNW9yZmpGb1RCOVQybldMc3puUTBqdktPREpuUjVQSHR2WkdiZGRaTHd3SHQ5N1RwWEVESUFiNEE3d3NvVlBjMGM1NEg1cDVFMFNqUFhJdEpEcHdSR1piSFN5TnduSm1WZU95YVhWaVdOZSt4NDd3eWttR24rUUViT2h6YUNJNERtRE1CRThDU2xJZzRCQWNwTVE5VjB0NW1FcDVWZDRaRXJwL0FXV1lTakFkVDg0WGFLR0R6cUJsYjBQc1J3YnhkL2M5NnEvTUtORHpLNU5DcHJnTEZHZTluSUkrOWVZeUg0L01mRnFZOWpuWVc2M3MyOTlQY3pWV00yRmFDS1JJL2dyRy9MWlZOaVdjdC9KT0JVQkpzaDYvbkZvc0pWbDdCdllZc3dLM0gzNHgvcnQxcFljV0M0WlhxSHZyRWNMVGFlcjRXZzFTZTZxN0V4UUZYZ21BTGtWNFNiTjQ4QUJHTGZhY2ZHUWRzTkQrWFlVaTdTY1YvYU9EL2tSNGZNeWhrN3RBTGNENENIQUNDRzJ1MW1lRmxvNngzcC83cmEvZm5UcVJoRXNwRjJtV2k3QjR2YUIrNkc1enVBQURtYmxlalNycE5UR1FoaFNyRHozcnlvYkpYb0ZiY2Q5SHZ6dVNYWU04dU1sUVdYOURWSzNrMkZvcFlyQytjTGE2K1VIdlZwdG14S2lpSGM4MFBhdUVXUUZxRnhPb3VwUGtIS0J4R0F2VnFnR2NGYW9Zb2ZUeld4QU5CNGN3ZVRNOWhyWTlieGdzRGZXUklUOEdOWCtNK2RQWWdwVjVLdm92M0s5dFJJZHVMbWVVMW5WVFI0NU11ZkJ6VG03d2ZZWmdoTndEdjExbUszYkZzcll0dmVWZFFQT1cwSkt0dHI2RFo3TW5GRkMra1FJZEJ4RXNxUGlXUEFsY21EZW5oVUxidTVxb2JUc2xiSkk5THlhUDZHNTQ3WkVmanVNNGlzemJHVHIrN0J6ZDdwR3FDa0lraHdWU1hjVmVweDVkUWNwNHdZSjVEZmRYUUZnaU9vMXd2UDBFNzhWVjhjc245NlNhaTBMWHErdHVET1U5UEFDb0hFaXdLNjVYenl6MSt6YWVNajkwWkRNN2pkQWx1MzJadmVRYWZQY3RVcWx6cUNPUXltRUZRUDhHczczV1J5aWhFRS84aEN3UW5rcm5VTktzUi9BendPcUFRaTJ4UzZsUWEvalBwTUFqcnVGNkdYaHpJR2l2RDMxVVRiOXVOQXdlUWpBT29UaEZINkxNc2hETC9WLzRpWEszeFl3cjVWQWUvb0FzVFJzS3VoZFBab0gxcW9ueE5yRlNxR29TclVEWVorUG45dmQ0cXB3R0RuQTRLWnpMYTFQdTYwVkxqWGR3M3ErZEdsV0RFVmVlRUljMjQyUnhxbVRHSWp1QnAwUGl3UGxpSC9VVC9xRWNUQmM4enlTYzVndXVMU1NsZHowMERubzhlMXZGdEJrMzlSbHZ2MmhJeUVaeFMzcGFNckRkRnRYczh5cWRIUTNWU3pyTGNHWTd3L01UNkc5ZUt4N1l2OVlrUGtaaWEzNGkyNmtwcEx3MDMvazdGUWt0U1QyUk1BWkEwa3BVNjBZNkJzNkE0TWFNcU5kN1VZSlpFNXlqek1aTU9iQWpFSW9UMXl2VFlNWVI5N0ZhK2d5Mzd6SDlzVHc1ckVna0xscmtJS2gzbThBK1ZIVi8vTGw0MHp0ZTNPN2dtbkFubldSRC8rbHBwSlJnMHFyR0xQMTRZcUN3NmpaamtpTjdJYmF4UTlsU0l0WTZKdDFDekU4NFhhWk54VXNDVk1JNGgzN21wN0FTK3ZCZWRDdEZ4QkJMeGxoMWt3R01PUW1qQnV6OVhwN3MxU2t3WkZyWlluOFN5T1VLdzZSekF5bUhqUDVGeVJ2MXhiUmVOODB6SFlpd2Y3RndlZEhEdG0yQlg4SVRIL1kxVnJjRXJqQVhack1iWXM2VWhxbXBKRTdJSkFFSktJdWVsMW1PNitoRE5uVXpnL29ScHB6YXBtdFdxamIxcHRVc0t5YWxycm8xd2ptb3lURjRvRFpWN1FnYThxSEthNURFcjRKVi9nMzNaK3VVbURkamRTYXZIa0FKYVY4RDV3NHFjRUhoVm4xMmpQZUtyVjlYMEg4alFuSS9TNEt5UWlhRzFvR0dNbFN6NGEzczdrcytianVKTFFzZ1BHK3ZaRFhHbEtxSnFIQ09UbXR3WENhcWdVQ1YxU2lDU0JmWVdya2trNjd4TFFQUkZxNDU2WVgvTS9RUlg4b3J6RE1POTd6V1loUW5BUHllVGx1VXQrWWUzNXdyencybmM3M0hNK0dHVEJHSW1NaWhCYzZFS2hUUjBYNFJTR1JsVllIUUp0S1FHV2Z4V1VGa3F4ZnFtTGNXUGhYTzM0UHVYekhzZTRrenlLRGJXaTgyWVhranRZbUo4YWpEWm9wL0NYelVmeGZkQ1diamkvUkZPQkhpb0Q0Y3prRjlTTlI5TWpJbjJtQkkyekxBRGI1NGhsN0pLWFg0Rmd2SVNVZWhNZXUzT1FOUmduV2h5eExLWFJsRnJIN1QwVnZlVFJuRWtTcWxOeEI2TXlwbDNDVUNndTF6Q1ZWL2ZlTWd3R2VzdjJXSi9tUytQV2ViOGRKTlMzL3lzRUFDc25FTFJtL05xUE1VQ2xNUGVCSS9rek9GS1pRZkNyQnlweEFSbHRodVFZPTwveGVuYzpDaXBoZXJWYWx1ZT4KICAgPC94ZW5jOkNpcGhlckRhdGE+CjwveGVuYzpFbmNyeXB0ZWREYXRhPjwvc2FtbDpFbmNyeXB0ZWRBc3NlcnRpb24+PC9zYW1scDpSZXNwb25zZT4=});
  xml=>$xml,
}

sub XML_10 {
my $xml=decode_base64(q{PHNhbWxwOlJlc3BvbnNlIHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJvdG9jb2wiIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIElEPSJfZTZkMzIxZGM1OGMyYTZkNjEzMTFhNTNkYTFkMjhiMzZkMjdiOWRhZGEzIiBWZXJzaW9uPSIyLjAiIElzc3VlSW5zdGFudD0iMjAxNC0wOS0yM1QxMjo0NjozMVoiIERlc3RpbmF0aW9uPSJodHRwOi8vcHl0b29sa2l0LmNvbTo4MDAwLz9hY3MiIEluUmVzcG9uc2VUbz0iT05FTE9HSU5fNTJlOGNiZGM0OGNkNzdmZmM3MGI4ZWI2MTgxYmEwYTVjN2U1YTRiYyI+PHNhbWw6SXNzdWVyPmh0dHBzOi8vaWRwLmV4YW1wbGUuY29tL3NpbXBsZXNhbWwvc2FtbDIvaWRwL21ldGFkYXRhLnBocDwvc2FtbDpJc3N1ZXI+PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgPGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz4KICAgIDxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz4KICA8ZHM6UmVmZXJlbmNlIFVSST0iI19lNmQzMjFkYzU4YzJhNmQ2MTMxMWE1M2RhMWQyOGIzNmQyN2I5ZGFkYTMiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPnBUTEcxYXliMTFvRjRJanorOC9OdW43NDdpND08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+dlM2NnB0L3QvMzlwWG9jd0ZneWRUWmg1eC9YN29tMFBnL2xoYXFEOWN3NzByWE5CNU1zbVZMR3BWSXZwQnd5WlkzS0t2ZUZNdDA5cTJCSkl1V0RsblVFOGhXR0k2STlFOGZpVXUvZ0VoRU4yRmx3NWdtK05BYXhWVHZuR1IrMkh5UmtYUjBCa0R3TngyVFM3bnZweFFEbzI1b25KUnhtenpPekxlZWlwQ2o0PTwvZHM6U2lnbmF0dXJlVmFsdWU+CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNiRENDQWRXZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRMEZBREJUTVFzd0NRWURWUVFHRXdKMWN6RVRNQkVHQTFVRUNBd0tRMkZzYVdadmNtNXBZVEVWTUJNR0ExVUVDZ3dNVDI1bGJHOW5hVzRnU1c1ak1SZ3dGZ1lEVlFRRERBOXBaSEF1WlhoaGJYQnNaUzVqYjIwd0hoY05NVFF3T1RJek1USXlOREE0V2hjTk5ESXdNakE0TVRJeU5EQTRXakJUTVFzd0NRWURWUVFHRXdKMWN6RVRNQkVHQTFVRUNBd0tRMkZzYVdadmNtNXBZVEVWTUJNR0ExVUVDZ3dNVDI1bGJHOW5hVzRnU1c1ak1SZ3dGZ1lEVlFRRERBOXBaSEF1WlhoaGJYQnNaUzVqYjIwd2daOHdEUVlKS29aSWh2Y05BUUVCQlFBRGdZMEFNSUdKQW9HQkFPV0ErWUhVN2N2UE9yQk9meENzY3NZVEpCK2tIM01hQTlCRnJTSEZTK0tjUjZjdzdvUFNrdElKeFVndkRwUWJ0Zk5jT2tFL3R1T1BCRG9lY2g3QVhmdkg2ZDdCdzd4dFc4UFBKMm1CNUhuL0hHVzJyb1loeG1maDN0UjVTZHdONmk0RVJWRjhlTGt2d0NIc05ReUsyUmVmMERBSnZwQk5aTUhDcFMyNDkxNi9BZ01CQUFHalVEQk9NQjBHQTFVZERnUVdCQlE3Ny9xVmVpaWdmaFlESVRwbENOdEpLWlRNOERBZkJnTlZIU01FR0RBV2dCUTc3L3FWZWlpZ2ZoWURJVHBsQ050SktaVE04REFNQmdOVkhSTUVCVEFEQVFIL01BMEdDU3FHU0liM0RRRUJEUVVBQTRHQkFKTzJqLzF1TzgwRTVDMlBNNkZrOW16ZXJyYmt4bDdBWi9tdmxiT24rc05aRStWWjFBbnRZdUc4ZWtiSnBKdEcxWWZSZmM3RUE5bUV0cXZ2NGRodjd6Qnk0bks0OU9SK0twSUJqSXRXQjVrWXZycU1MS0JhMzJzTWJncXFVcWVGMUVOWEtqcHZMU3VQZGZHSlpBM2ROYS8rRHliOEdHcVdlNzA3ekx5YzVGOG08L2RzOlg1MDlDZXJ0aWZpY2F0ZT48L2RzOlg1MDlEYXRhPjwvZHM6S2V5SW5mbz48L2RzOlNpZ25hdHVyZT48c2FtbHA6U3RhdHVzPjxzYW1scDpTdGF0dXNDb2RlIFZhbHVlPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6c3RhdHVzOlN1Y2Nlc3MiLz48L3NhbWxwOlN0YXR1cz48c2FtbDpBc3NlcnRpb24geG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeG1sbnM6eHM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hIiBJRD0iXzc2ZDEwMTAyOGY3MDRjNjJhOTkyNjg5MWE0YTFjOWNjM2QzMzJkMTI5YiIgVmVyc2lvbj0iMi4wIiBJc3N1ZUluc3RhbnQ9IjIwMTQtMDktMjNUMTI6NDY6MzFaIj48c2FtbDpJc3N1ZXI+aHR0cHM6Ly9pZHAuZXhhbXBsZS5jb20vc2ltcGxlc2FtbC9zYW1sMi9pZHAvbWV0YWRhdGEucGhwPC9zYW1sOklzc3Vlcj48ZHM6U2lnbmF0dXJlIHhtbG5zOmRzPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjIj4KICA8ZHM6U2lnbmVkSW5mbz48ZHM6Q2Fub25pY2FsaXphdGlvbk1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMTAveG1sLWV4Yy1jMTRuIyIvPgogICAgPGRzOlNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNyc2Etc2hhMSIvPgogIDxkczpSZWZlcmVuY2UgVVJJPSIjXzc2ZDEwMTAyOGY3MDRjNjJhOTkyNjg5MWE0YTFjOWNjM2QzMzJkMTI5YiI+PGRzOlRyYW5zZm9ybXM+PGRzOlRyYW5zZm9ybSBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNlbnZlbG9wZWQtc2lnbmF0dXJlIi8+PGRzOlRyYW5zZm9ybSBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMTAveG1sLWV4Yy1jMTRuIyIvPjwvZHM6VHJhbnNmb3Jtcz48ZHM6RGlnZXN0TWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI3NoYTEiLz48ZHM6RGlnZXN0VmFsdWU+L25YbW1VenY3M0hlK1FUMS9nejdiM3JCRk5NPTwvZHM6RGlnZXN0VmFsdWU+PC9kczpSZWZlcmVuY2U+PC9kczpTaWduZWRJbmZvPjxkczpTaWduYXR1cmVWYWx1ZT5keG1SNWVMdTdya3kyZWo3MVVZbkpodUJSeXAxMENadGdSOTJFRjU5SzFlY1dzcHI0RlVHbFhON0hlcGN1RWUzcFN5NEs1Qno3MlV4bFhpR2JvKzlhSmVXTGZVNlVQMVBJYlR2cFBLT3ljdzZ0dE5zOWtDVUh1UTdGUGI3L2pTRzZHZE1wRkpoQmZoVjhXRS92ODBJSWwwNk4vMFpXK2E4QzRtQUxTMy9HRVU9PC9kczpTaWduYXR1cmVWYWx1ZT4KPGRzOktleUluZm8+PGRzOlg1MDlEYXRhPjxkczpYNTA5Q2VydGlmaWNhdGU+TUlJQ2JEQ0NBZFdnQXdJQkFnSUJBREFOQmdrcWhraUc5dzBCQVEwRkFEQlRNUXN3Q1FZRFZRUUdFd0oxY3pFVE1CRUdBMVVFQ0F3S1EyRnNhV1p2Y201cFlURVZNQk1HQTFVRUNnd01UMjVsYkc5bmFXNGdTVzVqTVJnd0ZnWURWUVFEREE5cFpIQXVaWGhoYlhCc1pTNWpiMjB3SGhjTk1UUXdPVEl6TVRJeU5EQTRXaGNOTkRJd01qQTRNVEl5TkRBNFdqQlRNUXN3Q1FZRFZRUUdFd0oxY3pFVE1CRUdBMVVFQ0F3S1EyRnNhV1p2Y201cFlURVZNQk1HQTFVRUNnd01UMjVsYkc5bmFXNGdTVzVqTVJnd0ZnWURWUVFEREE5cFpIQXVaWGhoYlhCc1pTNWpiMjB3Z1o4d0RRWUpLb1pJaHZjTkFRRUJCUUFEZ1kwQU1JR0pBb0dCQU9XQStZSFU3Y3ZQT3JCT2Z4Q3Njc1lUSkIra0gzTWFBOUJGclNIRlMrS2NSNmN3N29QU2t0SUp4VWd2RHBRYnRmTmNPa0UvdHVPUEJEb2VjaDdBWGZ2SDZkN0J3N3h0VzhQUEoybUI1SG4vSEdXMnJvWWh4bWZoM3RSNVNkd042aTRFUlZGOGVMa3Z3Q0hzTlF5SzJSZWYwREFKdnBCTlpNSENwUzI0OTE2L0FnTUJBQUdqVURCT01CMEdBMVVkRGdRV0JCUTc3L3FWZWlpZ2ZoWURJVHBsQ050SktaVE04REFmQmdOVkhTTUVHREFXZ0JRNzcvcVZlaWlnZmhZRElUcGxDTnRKS1pUTThEQU1CZ05WSFJNRUJUQURBUUgvTUEwR0NTcUdTSWIzRFFFQkRRVUFBNEdCQUpPMmovMXVPODBFNUMyUE02Rms5bXplcnJia3hsN0FaL212bGJPbitzTlpFK1ZaMUFudFl1Rzhla2JKcEp0RzFZZlJmYzdFQTltRXRxdnY0ZGh2N3pCeTRuSzQ5T1IrS3BJQmpJdFdCNWtZdnJxTUxLQmEzMnNNYmdxcVVxZUYxRU5YS2pwdkxTdVBkZkdKWkEzZE5hLytEeWI4R0dxV2U3MDd6THljNUY4bTwvZHM6WDUwOUNlcnRpZmljYXRlPjwvZHM6WDUwOURhdGE+PC9kczpLZXlJbmZvPjwvZHM6U2lnbmF0dXJlPjxzYW1sOlN1YmplY3Q+PHNhbWw6TmFtZUlEIFNQTmFtZVF1YWxpZmllcj0iaHR0cDovL3B5dG9vbGtpdC5jb206ODAwMC9tZXRhZGF0YS8iIEZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOm5hbWVpZC1mb3JtYXQ6dW5zcGVjaWZpZWQiPjI1ZGRkN2QzNGE3ZDc5ZGI2OTE2NzYyNWNkYTU2YTMyMGFkZjI4NzY8L3NhbWw6TmFtZUlEPjxzYW1sOlN1YmplY3RDb25maXJtYXRpb24gTWV0aG9kPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6Y206YmVhcmVyIj48c2FtbDpTdWJqZWN0Q29uZmlybWF0aW9uRGF0YSBOb3RPbk9yQWZ0ZXI9IjIwMjQtMDMtMjZUMTg6MDY6MzFaIiBSZWNpcGllbnQ9Imh0dHA6Ly9weXRvb2xraXQuY29tOjgwMDAvP2FjcyIgSW5SZXNwb25zZVRvPSJPTkVMT0dJTl81MmU4Y2JkYzQ4Y2Q3N2ZmYzcwYjhlYjYxODFiYTBhNWM3ZTVhNGJjIi8+PC9zYW1sOlN1YmplY3RDb25maXJtYXRpb24+PC9zYW1sOlN1YmplY3Q+PHNhbWw6Q29uZGl0aW9ucyBOb3RCZWZvcmU9IjIwMTQtMDktMjNUMTI6NDY6MDFaIiBOb3RPbk9yQWZ0ZXI9IjIwMjQtMDMtMjZUMTg6MDY6MzFaIj48c2FtbDpBdWRpZW5jZVJlc3RyaWN0aW9uPjxzYW1sOkF1ZGllbmNlPmh0dHA6Ly9weXRvb2xraXQuY29tOjgwMDAvbWV0YWRhdGEvPC9zYW1sOkF1ZGllbmNlPjwvc2FtbDpBdWRpZW5jZVJlc3RyaWN0aW9uPjwvc2FtbDpDb25kaXRpb25zPjxzYW1sOkF1dGhuU3RhdGVtZW50IEF1dGhuSW5zdGFudD0iMjAxNC0wOS0yM1QxMjo0NjozMVoiIFNlc3Npb25Ob3RPbk9yQWZ0ZXI9IjIwMTQtMDktMjNUMjA6NDY6MzFaIiBTZXNzaW9uSW5kZXg9Il9jZWYzYjIwNTViYTZhMTI1MmMyMjQ2YWJhN2UwNmJmMzQ1MDkwODBmYTMiPjxzYW1sOkF1dGhuQ29udGV4dD48c2FtbDpBdXRobkNvbnRleHRDbGFzc1JlZj51cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YWM6Y2xhc3NlczpQYXNzd29yZDwvc2FtbDpBdXRobkNvbnRleHRDbGFzc1JlZj48L3NhbWw6QXV0aG5Db250ZXh0Pjwvc2FtbDpBdXRoblN0YXRlbWVudD48c2FtbDpBdHRyaWJ1dGVTdGF0ZW1lbnQ+PHNhbWw6QXR0cmlidXRlIE5hbWU9InVpZCIgTmFtZUZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1hdDpiYXNpYyI+PHNhbWw6QXR0cmlidXRlVmFsdWUgeHNpOnR5cGU9InhzOnN0cmluZyI+c21hcnRpbjwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6QXR0cmlidXRlPjxzYW1sOkF0dHJpYnV0ZSBOYW1lPSJtYWlsIiBOYW1lRm9ybWF0PSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXR0cm5hbWUtZm9ybWF0OmJhc2ljIj48c2FtbDpBdHRyaWJ1dGVWYWx1ZSB4c2k6dHlwZT0ieHM6c3RyaW5nIj5zbWFydGluQHlhY28uZXM8L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48c2FtbDpBdHRyaWJ1dGUgTmFtZT0iY24iIE5hbWVGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphdHRybmFtZS1mb3JtYXQ6YmFzaWMiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPlNpeHRvMzwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6QXR0cmlidXRlPjxzYW1sOkF0dHJpYnV0ZSBOYW1lPSJzbiIgTmFtZUZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1hdDpiYXNpYyI+PHNhbWw6QXR0cmlidXRlVmFsdWUgeHNpOnR5cGU9InhzOnN0cmluZyI+TWFydGluMjwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6QXR0cmlidXRlPjxzYW1sOkF0dHJpYnV0ZSBOYW1lPSJwaG9uZSIgTmFtZUZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1hdDpiYXNpYyIvPjxzYW1sOkF0dHJpYnV0ZSBOYW1lPSJlZHVQZXJzb25BZmZpbGlhdGlvbiIgTmFtZUZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1hdDpiYXNpYyI+PHNhbWw6QXR0cmlidXRlVmFsdWUgeHNpOnR5cGU9InhzOnN0cmluZyI+dXNlcjwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48c2FtbDpBdHRyaWJ1dGVWYWx1ZSB4c2k6dHlwZT0ieHM6c3RyaW5nIj5hZG1pbjwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6QXR0cmlidXRlPjwvc2FtbDpBdHRyaWJ1dGVTdGF0ZW1lbnQ+PC9zYW1sOkFzc2VydGlvbj48L3NhbWxwOlJlc3BvbnNlPg==});
  xml=>$xml,
}
sub XML_11 {
my $xml=decode_base64(q{PHNhbWxwOlJlc3BvbnNlIHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJvdG9jb2wiIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIElEPSJwZnhjM2QyYjU0Mi0wZjdlLTg3NjctOGU4Ny01YjBkYzY5MTMzNzUiIFZlcnNpb249IjIuMCIgSXNzdWVJbnN0YW50PSIyMDE0LTAzLTIxVDEzOjQxOjA5WiIgRGVzdGluYXRpb249Imh0dHBzOi8vcGl0YnVsay5uby1pcC5vcmcvbmV3b25lbG9naW4vZGVtbzEvaW5kZXgucGhwP2FjcyIgSW5SZXNwb25zZVRvPSJPTkVMT0dJTl81ZDllMzE5YzFiOGE2N2RhNDgyMjc5NjRjMjhkMjgwZTc4NjBmODA0Ij48c2FtbDpJc3N1ZXI+aHR0cHM6Ly9waXRidWxrLm5vLWlwLm9yZy9zaW1wbGVzYW1sL3NhbWwyL2lkcC9tZXRhZGF0YS5waHA8L3NhbWw6SXNzdWVyPjxkczpTaWduYXR1cmUgeG1sbnM6ZHM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyMiPgogIDxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+CiAgICA8ZHM6U2lnbmF0dXJlTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI3JzYS1zaGExIi8+CiAgPGRzOlJlZmVyZW5jZSBVUkk9IiNwZnhjM2QyYjU0Mi0wZjdlLTg3NjctOGU4Ny01YjBkYzY5MTMzNzUiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPjFkUUZpWVUwbzJPRjdjL1JWVjhHcGdiNHUzST08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+d1JnQlhPcS9GaUxaYzJtdXJlVEMvajZ6WTcwOU9pa0o1SGVVU3J1SFRkWWpFZzlhWnkxUmJ4bEtJWUVJZlhwblg3TkJvS3hmQU1tK08wZnNycU9qZ2NZeFRWa3Faak9yNzFxaVhOYnR3amVBa2RZU3BrNWJyc0FjbmZjUGR2OFFSZVlyM0Q3dDVaVkNnWXV2WFErZE5FTEtlYWc3ZTFBU096VnFPZHA1WjlZPTwvZHM6U2lnbmF0dXJlVmFsdWU+CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNnVENDQWVvQ0NRQ2JPbHJXRGRYN0ZUQU5CZ2txaGtpRzl3MEJBUVVGQURDQmhERUxNQWtHQTFVRUJoTUNUazh4R0RBV0JnTlZCQWdURDBGdVpISmxZWE1nVTI5c1ltVnlaekVNTUFvR0ExVUVCeE1EUm05dk1SQXdEZ1lEVlFRS0V3ZFZUa2xPUlZSVU1SZ3dGZ1lEVlFRREV3OW1aV2xrWlM1bGNteGhibWN1Ym04eElUQWZCZ2txaGtpRzl3MEJDUUVXRW1GdVpISmxZWE5BZFc1cGJtVjBkQzV1YnpBZUZ3MHdOekEyTVRVeE1qQXhNelZhRncwd056QTRNVFF4TWpBeE16VmFNSUdFTVFzd0NRWURWUVFHRXdKT1R6RVlNQllHQTFVRUNCTVBRVzVrY21WaGN5QlRiMnhpWlhKbk1Rd3dDZ1lEVlFRSEV3TkdiMjh4RURBT0JnTlZCQW9UQjFWT1NVNUZWRlF4R0RBV0JnTlZCQU1URDJabGFXUmxMbVZ5YkdGdVp5NXViekVoTUI4R0NTcUdTSWIzRFFFSkFSWVNZVzVrY21WaGMwQjFibWx1WlhSMExtNXZNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdOQURDQmlRS0JnUURpdmJoUjdQNTE2eC9TM0JxS3h1cFFlMExPTm9saXVwaUJPZXNDTzNTSGJEcmwzK3E5SWJmbmZtRTA0ck51TWNQc0l4QjE2MVRkRHBJZXNMQ243YzhhUEhJU0tPdFBsQWVUWlNuYjhRQXU3YVJqWnEzK1BiclA1dVczVGNmQ0dQdEtUeXRIT2dlL09sSmJvMDc4ZFZoWFExNGQxRUR3WEpXMXJSWHVVdDRDOFFJREFRQUJNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0R0JBQ0RWZnA4NkhPYnFZK2U4QlVvV1E5K1ZNUXgxQVNEb2hCandPc2cyV3lrVXFSWEYrZExmY1VIOWRXUjYzQ3RaSUtGRGJTdE5vbVBuUXo3bmJLK29ueWd3QnNwVkVibkh1VWloWnEzWlVkbXVtUXFDdzRVdnMvMVV2cTNvck9vL1dKVmhUeXZMZ0ZWSzJRYXJRNC82N09aZkhkN1IrUE9CWGhvcGhTTXYxWk9vPC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PHNhbWxwOlN0YXR1cz48c2FtbHA6U3RhdHVzQ29kZSBWYWx1ZT0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOnN0YXR1czpTdWNjZXNzIi8+PC9zYW1scDpTdGF0dXM+PHNhbWw6QXNzZXJ0aW9uIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zOnhzPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSIgSUQ9Il9jY2NkNjAyNDExNjY0MWZlNDhlMGFlMmM1MTIyMGQwMjc1NWY5NmM5OGQiIFZlcnNpb249IjIuMCIgSXNzdWVJbnN0YW50PSIyMDE0LTAzLTIxVDEzOjQxOjA5WiI+PHNhbWw6SXNzdWVyPmh0dHBzOi8vcGl0YnVsay5uby1pcC5vcmcvc2ltcGxlc2FtbC9zYW1sMi9pZHAvbWV0YWRhdGEucGhwPC9zYW1sOklzc3Vlcj48c2FtbDpTdWJqZWN0PjxzYW1sOk5hbWVJRCBTUE5hbWVRdWFsaWZpZXI9Imh0dHBzOi8vcGl0YnVsay5uby1pcC5vcmcvbmV3b25lbG9naW4vZGVtbzEvbWV0YWRhdGEucGhwIiBGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDpuYW1laWQtZm9ybWF0OnRyYW5zaWVudCI+X2I5OGY5OGJiMWFiNTEyY2VkNjUzYjU4YmFhZmY1NDM0NDhkYWVkNTM1ZDwvc2FtbDpOYW1lSUQ+PHNhbWw6U3ViamVjdENvbmZpcm1hdGlvbiBNZXRob2Q9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDpjbTpiZWFyZXIiPjxzYW1sOlN1YmplY3RDb25maXJtYXRpb25EYXRhIE5vdE9uT3JBZnRlcj0iMjAyMy0wOS0yMlQxOTowMTowOVoiIFJlY2lwaWVudD0iaHR0cHM6Ly9waXRidWxrLm5vLWlwLm9yZy9uZXdvbmVsb2dpbi9kZW1vMS9pbmRleC5waHA/YWNzIiBJblJlc3BvbnNlVG89Ik9ORUxPR0lOXzVkOWUzMTljMWI4YTY3ZGE0ODIyNzk2NGMyOGQyODBlNzg2MGY4MDQiLz48L3NhbWw6U3ViamVjdENvbmZpcm1hdGlvbj48L3NhbWw6U3ViamVjdD48c2FtbDpDb25kaXRpb25zIE5vdEJlZm9yZT0iMjAxNC0wMy0yMVQxMzo0MDozOVoiIE5vdE9uT3JBZnRlcj0iMjAyMy0wOS0yMlQxOTowMTowOVoiPjxzYW1sOkF1ZGllbmNlUmVzdHJpY3Rpb24+PHNhbWw6QXVkaWVuY2U+aHR0cHM6Ly9waXRidWxrLm5vLWlwLm9yZy9uZXdvbmVsb2dpbi9kZW1vMS9tZXRhZGF0YS5waHA8L3NhbWw6QXVkaWVuY2U+PC9zYW1sOkF1ZGllbmNlUmVzdHJpY3Rpb24+PC9zYW1sOkNvbmRpdGlvbnM+PHNhbWw6QXV0aG5TdGF0ZW1lbnQgQXV0aG5JbnN0YW50PSIyMDE0LTAzLTIxVDEzOjQxOjA5WiIgU2Vzc2lvbk5vdE9uT3JBZnRlcj0iMjAxNC0wMy0yMVQyMTo0MTowOVoiIFNlc3Npb25JbmRleD0iXzlmZTBjOGRjZDMzMDJlNzM2NGZjYWIyMmE1Mjc0OGViZjIyMjRkZjBhYSI+PHNhbWw6QXV0aG5Db250ZXh0PjxzYW1sOkF1dGhuQ29udGV4dENsYXNzUmVmPnVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphYzpjbGFzc2VzOlBhc3N3b3JkPC9zYW1sOkF1dGhuQ29udGV4dENsYXNzUmVmPjwvc2FtbDpBdXRobkNvbnRleHQ+PC9zYW1sOkF1dGhuU3RhdGVtZW50PjxzYW1sOkF0dHJpYnV0ZVN0YXRlbWVudD48c2FtbDpBdHRyaWJ1dGUgTmFtZT0idWlkIiBOYW1lRm9ybWF0PSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXR0cm5hbWUtZm9ybWF0OmJhc2ljIj48c2FtbDpBdHRyaWJ1dGVWYWx1ZSB4c2k6dHlwZT0ieHM6c3RyaW5nIj50ZXN0PC9zYW1sOkF0dHJpYnV0ZVZhbHVlPjwvc2FtbDpBdHRyaWJ1dGU+PHNhbWw6QXR0cmlidXRlIE5hbWU9Im1haWwiIE5hbWVGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphdHRybmFtZS1mb3JtYXQ6YmFzaWMiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPnRlc3RAZXhhbXBsZS5jb208L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48c2FtbDpBdHRyaWJ1dGUgTmFtZT0iY24iIE5hbWVGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphdHRybmFtZS1mb3JtYXQ6YmFzaWMiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPnRlc3Q8L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48c2FtbDpBdHRyaWJ1dGUgTmFtZT0ic24iIE5hbWVGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphdHRybmFtZS1mb3JtYXQ6YmFzaWMiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPndhYTI8L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48c2FtbDpBdHRyaWJ1dGUgTmFtZT0iZWR1UGVyc29uQWZmaWxpYXRpb24iIE5hbWVGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphdHRybmFtZS1mb3JtYXQ6YmFzaWMiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPnVzZXI8L3NhbWw6QXR0cmlidXRlVmFsdWU+PHNhbWw6QXR0cmlidXRlVmFsdWUgeHNpOnR5cGU9InhzOnN0cmluZyI+YWRtaW48L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48L3NhbWw6QXR0cmlidXRlU3RhdGVtZW50Pjwvc2FtbDpBc3NlcnRpb24+PC9zYW1scDpSZXNwb25zZT4=});
  xml=>$xml,
}
sub XML_12 {
  xml=>q{<?xml version="1.0" standalone="yes"?>
<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" Destination="http://sso.dev.venda.com/opensso" IssueInstant="2019-04-30T22:07:47Z" ID="e4e5f022bef0f941a8c4ff0ab8cb2fea" Version="2.0" ProviderName="My SP's human readable name.">
  <saml:Issuer>http://localhost:3000</saml:Issuer>
  <samlp:NameIDPolicy AllowCreate="1" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" />
<Signature xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" /><SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" /><Reference URI="#e4e5f022bef0f941a8c4ff0ab8cb2fea"><Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" /><Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"><InclusiveNamespaces PrefixList="xs" xmlns="http://www.w3.org/2001/10/xml-exc-c14n#" /></Transform></Transforms><DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256" /><DigestValue>kU63NojDYVz/bLlBxREIIFqNLfqi7S4rBzoFmXxHing=</DigestValue></Reference></SignedInfo><SignatureValue>C2aS2Dk0EqzZjEo7VzkfATQl1lyBd7MO6eKX1kSZT0rqSXn1ChfCQRINnstgEzLiwBuqqdHdlKy1mNUXT19Si5DjYUiIgmCbipFD+o6E6ZBy7raHEYL22sUlXLS0OY691SBe3gqZ4l0RrJ7Xcbox3uNn+QbK68DOjdL9UH0OIBzYoX9/romzbqbYRr8tyNmS6u88GoLDAV3sxdaTspTql1pX60z8UJV7CtFbm5NNR4IqJBQkflfsDMOtAyz9GVuvWaYF9HXQs5QONqG+qZd8CQ593L91jdJZ0kKPFoa8oFhdv9VaiNAROLv7nK6D/uEI+V4r1u76WOx9lDSm5YHOc/DQQdWU5hdGR7caSObod7zXEshfnzr9d7DugxY+m/TWk3aPqLfUJdQytAeyrZ86BCSVWmDctIR9nip+fl9aTWFcKoht7+0PtR05L2/uSbHwaEc4KP4qwVJVT2I5KydJnNMQDwTUf/P/Qwq6lvN9LXA7FjAtppmQi95qgkuHHl1qVIGBHriwQzmZwkEmmt2Q1fFflxQadwwlY9NASH8tPXaaJHqWT0Yyxo4bG3EVeuVx3cDykaY2wikIj9CyLo7bW3q91Y+HPbtPkUIjYgiZXQVze9od8fm7/NHt3oZJPyhwqvw5CL241679/IHpvHvemBsz1WiMGHqqsZ9nDreSKTI=</SignatureValue><KeyInfo><X509Data><X509Certificate>MIIFkzCCA3ugAwIBAgIJALYqNH4SQ30wMA0GCSqGSIb3DQEBCwUAMGAxCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJNTzESMBAGA1UEBwwJU29tZVBMYWNlMRwwGgYDVQQKDBNEZWZhdWx0IENvbXBhbnkgTHRkMRIwEAYDVQQDDAlsb2NhbGhvc3QwHhcNMTkwNTAxMjMyNDE1WhcNMjAwNDMwMjMyNDE1WjBgMQswCQYDVQQGEwJVUzELMAkGA1UECAwCTU8xEjAQBgNVBAcMCVNvbWVQTGFjZTEcMBoGA1UECgwTRGVmYXVsdCBDb21wYW55IEx0ZDESMBAGA1UEAwwJbG9jYWxob3N0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEApyoN3hwK2eT9c0Hl+Nq+vFNU7nvbpOoDvzcW0Sz7aAYENTSQOvpS0Um/odsFQQ15JeaExDG0dxBHSuhAEBOv+Dr0zMWEZzKl5g+n+v0JZ33dHTcG+rxTJSNOVtliJqyO2CM/RZcRG0MLsUuEo6mG85h+17ZZyj6Dy2Jb0dsyVWpYQGsxsyA6W/QcYgOZrlSwZf+RwtkWwKR0FzOofxfOcoNGl1YkH2S5cEJcFU09Ew+hOGFIGWCHYm31S5PYG7dsG01zUBRMuLV1WvWYyjkGBgUEb8HeVcIC9Rl35iIgHzJ1rIQnQal8JW+yozzFWCnV3weG/Uf/n6c2h5I0HGxQXhET3jeYm7t1o7dCARrFh4cCL79eTYQC7KOkvjcrfZmzC/G9Viu+BrBu+2KNUrzuz15tMIA8wcPjrcERnRA/tpm5jpr1BHjXT6A8iZKi4ch0i1kxLGUL/r8fa+nlJ4dBvv7FYMF2g5L+Za2qNkPINxVX6RmvD7bHJ/ko3BB3E32sarBtb5eSpMVZ5YOEChoolEehoWy5Jz+CmgM2Wx/y4xr1suovoqMCzUKCiGjpUMuOLDQ3SplvUXJVoaYxW42hpeRbq9c5kXgIGRN84fcvJoawnSoOSy+tGWFnQqCuxeCnj0T1hBCph5mFSWXZWPmqcJMPi4xj+7Pf/mAQJ0iz0U8CAwEAAaNQME4wHQYDVR0OBBYEFI4+uGIu2WQRBN4Sgq8L23qYGnxlMB8GA1UdIwQYMBaAFI4+uGIu2WQRBN4Sgq8L23qYGnxlMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggIBADoyBulaHm7PRlSCHRaDWRM3jsBI9B8O0z5yi5cq1LNg7MyxSbEvlkFaRWPCkBhKYyPkhDtxiFWXTQEeR8Qt7qyBHkX3gex4R4TKrCDMwbfVhEqSja6HxJgsn+n+o59kGE1SIvuFE2CvIQI1D0FloByzTDjaBuDT+yDWqBzHj4ZNHWSkLxkqtu/CA/x7YAkR46SQPtr7vGi37S4o4e84iik2IldaBwfne0DYWoD++aUU79n8VQaL0OqpCVjegrWezYYGJ0keqJgUPf/HW8l9H8FsxSu7osmjKO9EZrz/lYJaWDVJT3+Sl58M1myG7zUlOmEQ75PzBcDBp1dOvgQ/ZZOAwVmb31hH68HJqDPaOFvRq47JfSKuhlOMn/A1CR1Q6vMGC27P4o4pGvNXS7vkEcLAv7Ss7lsPyofAd++Z3cig+sUezw9wvOl3kjSbbYhF7jgAzD/vhHElN6+KGNCcpsKVrFr400u/WK0L9jtj2M9GLyNgfY5ivcf3RkKZ13EExahR0KrYwymG5sHQiZXGfWJlhfccy/N0h+9NncuFkatRiQfdgAOZmHtpyaTE6EgOPyjvqHss6h8HFOS6Fdjo8Mkrdlyd9UM90r7eKPVef/k3nwrF88Z1KOipuBWMzxHAr1VzJlZnvK2Ckmf4y4LhB382itrWoTlcPxPfXbBgQNX8</X509Certificate></X509Data></KeyInfo></Signature></samlp:AuthnRequest>}
}