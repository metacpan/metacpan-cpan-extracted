use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use URN::OASIS::SAML2;

is(@URN::OASIS::SAML2::EXPORT, 0, "We don't export things by default");

my @export_tags = qw(
    all
    binding
    bindings
    class
    classes
    nameid
    ns
    status
    urn
);

cmp_deeply([sort keys %URN::OASIS::SAML2::EXPORT_TAGS], \@export_tags,                   "We export all our tags");
cmp_deeply($URN::OASIS::SAML2::EXPORT_TAGS{all},        [@URN::OASIS::SAML2::EXPORT_OK], "All exports everything");

my $saml2   = 'urn:oasis:names:tc:SAML:2.0:';
my $saml1_1 = 'urn:oasis:names:tc:SAML:1.1:';

my %exports = (
    BINDING_HTTP_POST     => $saml2 . 'bindings:HTTP-POST',
    BINDING_HTTP_ARTIFACT => $saml2 . 'bindings:HTTP-Artifact',
    BINDING_HTTP_REDIRECT => $saml2 . 'bindings:HTTP-Redirect',
    BINDING_SOAP          => $saml2 . 'bindings:SOAP',
    BINDING_POAS          => $saml2 . 'bindings:POAS',
    BINDING_REVERSE_SOAP  => $saml2 . 'bindings:POAS',

    CLASS_UNSPECIFIED        => $saml2 . 'ac:classes:unspecified',
    CLASS_PASSWORD_PROTECTED => $saml2 . 'ac:classes:PasswordProtectedTransport',
    CLASS_M2FA_UNREGISTERED  => $saml2 . 'ac:classes:MobileTwoFactorUnregistered',
    CLASS_M2FA_CONTRACT      => $saml2 . 'ac:classes:MobileTwoFactorContract',
    CLASS_SMARTCARD          => $saml2 . 'ac:classes:Smartcard',
    CLASS_SMARTCARD_PKI      => $saml2 . 'ac:classes:SmartcardPKI',

    NS_ASSERTION  => 'saml',
    NS_METADATA   => 'md',
    NS_PROTOCOL   => 'samlp',
    NS_SIGNATURE  => 'ds',
    NS_ENCRYPTION => 'xenc',

    URN_ASSERTION  => $saml2 . 'assertion',
    URN_METADATA   => $saml2 . 'metadata',
    URN_PROTOCOL   => $saml2 . 'protocol',
    URN_SIGNATURE  => 'http://www.w3.org/2000/09/xmldsig#',
    URN_ENCRYPTION => 'http://www.w3.org/2001/04/xmlenc#',

    URN_PROTOCOL_ARTIFACT_RESPONSE => $saml2 . 'protocol' . ':ArtifactResponse',
    URN_PROTOCOL_LOGOUT_REQUEST    => $saml2 . 'protocol' . ':LogoutRequest',
    URN_PROTOCOL_RESPONSE          => $saml2 . 'protocol' . ':Response',

    NAMEID_FORMAT        => $saml1_1 . 'nameid-format',
    NAMEID_FORMAT_ENTITY => $saml1_1 . 'nameid-format-entity',
    NAMEID_EMAIL         => $saml1_1 . 'nameid-format:emailAddress',
    NAMEID_TRANSIENT     => $saml1_1 . 'nameid-format:transient',
    NAMEID_PERSISTENT    => $saml1_1 . 'nameid-format:persistent',

    STATUS_AUTH_FAILED    => $saml2 . 'status:AuthnFailed',
    STATUS_REQUESTER      => $saml2 . 'status:Requester',
    STATUS_REQUEST_DENIED => $saml2 . 'status:RequestDenied',
    STATUS_RESPONDER      => $saml2 . 'status:Responder',
    STATUS_SUCCESS        => $saml2 . 'status:Success',
);

my @exports = sort keys %exports;

is(@URN::OASIS::SAML2::EXPORT_OK, @exports, "We export all our things");


no strict 'refs';
foreach (@exports) {
    is("URN::OASIS::SAML2::$_"->(), $exports{$_}, "$_ is correct");
}
use strict;

done_testing;
