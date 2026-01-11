# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use MIME::Base64;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $xml = <<'XMLWIDE';
<?xml version="1.0" encoding="utf-8"?>

<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="_dc503975-dcc8-4b3a-ae2e-0c6642f9e1e8" Version="2.0" IssueInstant="2021-11-25T14:17:26.184Z" Destination="http://localhost:3000/consumer-post" InResponseTo="NETSAML2_6c11b211b1857bd1f3833ad50392fe1c">
  <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">https://sts.windows.net/someguid</Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success" />
  </samlp:Status>
  <Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="_some_guid" IssueInstant="2021-11-25T14:17:26.168Z" Version="2.0">
    <Issuer>https://sts.windows.net/some_guid/</Issuer>
    <Subject>
      <NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">myuser@netsaml2</NameID>
      <SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <SubjectConfirmationData InResponseTo="NETSAML2_6c11b211b1857bd1f3833ad50392fe1c" NotOnOrAfter="2021-11-25T15:17:26.059Z" Recipient="http://localhost:3000/consumer-post" />
      </SubjectConfirmation>
    </Subject>
    <Conditions NotBefore="2021-11-25T14:12:26.059Z" NotOnOrAfter="2021-11-25T15:17:26.059Z">
      <AudienceRestriction>
        <Audience>http://localhost:3000</Audience>
      </AudienceRestriction>
    </Conditions>
    <AttributeStatement>
      <Attribute Name="http://schemas.microsoft.com/identity/claims/tenantid">
        <AttributeValue>some_guid</AttributeValue>
      </Attribute>
      <Attribute Name="http://schemas.microsoft.com/identity/claims/objectidentifier">
        <AttributeValue>some_guid</AttributeValue>
      </Attribute>
      <Attribute Name="http://schemas.microsoft.com/identity/claims/displayname">
        <AttributeValue>パスワードをお忘れの方</AttributeValue>
      </Attribute>
      <Attribute Name="http://schemas.microsoft.com/identity/claims/identityprovider">
        <AttributeValue>https://sts.windows.net/some_guid/</AttributeValue>
      </Attribute>
      <Attribute Name="http://schemas.microsoft.com/claims/authnmethodsreferences">
        <AttributeValue>http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/password</AttributeValue>
      </Attribute>
      <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname">
        <AttributeValue>Net</AttributeValue>
      </Attribute>
      <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname">
        <AttributeValue>SAML2</AttributeValue>
      </Attribute>
      <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name">
        <AttributeValue>myuser@netsaml2</AttributeValue>
      </Attribute>
    </AttributeStatement>
    <AuthnStatement AuthnInstant="2021-11-25T08:29:25.523Z" SessionIndex="_someguid">
      <AuthnContext>
        <AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</AuthnContextClassRef>
      </AuthnContext>
    </AuthnStatement>
  </Assertion>
</samlp:Response>
XMLWIDE

my $sig = XML::Sig->new( { key => 't/rsa.private.key' } );
isa_ok( $sig, 'XML::Sig' );
my $signed = $sig->sign($xml);
my $is_valid = $sig->verify( $signed );
ok( $is_valid == 1);

my $sig2 = XML::Sig->new( { key => 't/rsa.private.key', cert => 't/rsa.cert.pem', x509 => 1 } );
isa_ok( $sig2, 'XML::Sig' );
my $signed2 = $sig2->sign($xml);
my $is_valid2 = $sig2->verify( $signed2 );
ok( $is_valid2 == 1 );


SKIP: {
    eval {
        require Crypt::OpenSSL::DSA;
    };
    skip "Crypt::OpenSSL::DSA not installed", 2 if ($@);
    my $sig3 = XML::Sig->new( { key => 't/dsa.private.key' } );
    isa_ok( $sig3, 'XML::Sig' );
    my $signed3 = $sig3->sign($xml);
    my $is_valid3 = $sig3->verify( $signed3 );
    ok( $is_valid3 == 1 );
}
my $sig4 = XML::Sig->new( { key => 't/pkcs8.private.key' } );
isa_ok( $sig4, 'XML::Sig' );
my $signed4 = $sig4->sign($xml);
my $is_valid4 = $sig4->verify( $signed4 );
ok( $is_valid4 == 1);

my $sig5 = XML::Sig->new( { key => 't/ecdsa.private.pem' } );
isa_ok( $sig5, 'XML::Sig' );
my $signed5 = $sig5->sign($xml);
my $is_valid5 = $sig5->verify( $signed5 );
ok( $is_valid5 == 1);

my $sig6 = XML::Sig->new( { key => 't/ecdsa.private.pem', cert => 't/ecdsa.public.pem', x509 => 1 } );
isa_ok( $sig6, 'XML::Sig' );
my $signed6 = $sig6->sign($xml);
my $is_valid6 = $sig6->verify( $signed6 );
ok( $is_valid6 == 1);


