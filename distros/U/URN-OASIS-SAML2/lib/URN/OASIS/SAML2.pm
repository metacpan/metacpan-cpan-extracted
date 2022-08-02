# vim: tw=120
package URN::OASIS::SAML2;
our $VERSION = '0.003';
use warnings;
use strict;

# ABSTRACT: Constants for urn:oasis SAML2 implementations

use Exporter qw(import);

my @binding = qw(
    BINDING_HTTP_POST
    BINDING_HTTP_ARTIFACT
    BINDING_HTTP_REDIRECT
    BINDING_SOAP
    BINDING_POAS
    BINDING_REVERSE_SOAP
);

my @class = qw(
    CLASS_UNSPECIFIED
    CLASS_PASSWORD_PROTECTED
    CLASS_M2FA_UNREGISTERED
    CLASS_M2FA_CONTRACT
    CLASS_SMARTCARD
    CLASS_SMARTCARD_PKI
);

my @nameid = qw(
    NAMEID_FORMAT
    NAMEID_FORMAT_ENTITY
    NAMEID_EMAIL
    NAMEID_TRANSIENT
    NAMEID_PERSISTENT
);

my @urn = qw(
    URN_ASSERTION
    URN_METADATA
    URN_PROTOCOL
    URN_SIGNATURE
    URN_ENCRYPTION
    URN_PROTOCOL_ARTIFACT_RESPONSE
    URN_PROTOCOL_LOGOUT_REQUEST
    URN_PROTOCOL_RESPONSE
);

my @ns = qw(
    NS_ASSERTION
    NS_METADATA
    NS_PROTOCOL
    NS_SIGNATURE
    NS_ENCRYPTION
);

my @status = qw(
    STATUS_AUTH_FAILED
    STATUS_REQUESTER
    STATUS_REQUEST_DENIED
    STATUS_RESPONDER
    STATUS_SUCCESS
);

our @EXPORT_OK = (@binding, @class, @nameid, @ns, @urn, @status);

our %EXPORT_TAGS = (
    all      => \@EXPORT_OK,
    bindings => \@binding,
    binding  => \@binding,
    classes  => \@class,
    class    => \@class,
    nameid   => \@nameid,
    urn      => \@urn,
    ns       => \@ns,
    status   => \@status,
);

use constant base    => 'urn:oasis:names:tc:SAML:';
use constant saml2   => base . '2.0:';
use constant saml1_1 => base . '1.1:';

use constant URN_ASSERTION => saml2 . 'assertion';
use constant NS_ASSERTION  => 'saml';

use constant URN_METADATA => saml2 . 'metadata';
use constant NS_METADATA  => 'md';

use constant URN_PROTOCOL => saml2 . 'protocol';
use constant NS_PROTOCOL  => 'samlp';

use constant URN_SIGNATURE => 'http://www.w3.org/2000/09/xmldsig#';
use constant NS_SIGNATURE  => 'ds';

use constant URN_ENCRYPTION => 'http://www.w3.org/2001/04/xmlenc#';
use constant NS_ENCRYPTION  => 'xenc';

use constant URN_PROTOCOL_ARTIFACT_RESPONSE => URN_PROTOCOL . ':ArtifactResponse';
use constant URN_PROTOCOL_LOGOUT_REQUEST    => URN_PROTOCOL . ':LogoutRequest';
use constant URN_PROTOCOL_RESPONSE          => URN_PROTOCOL . ':Response';

use constant BINDING_HTTP_POST     => saml2 . 'bindings:HTTP-POST';
use constant BINDING_HTTP_ARTIFACT => saml2 . 'bindings:HTTP-Artifact';
use constant BINDING_HTTP_REDIRECT => saml2 . 'bindings:HTTP-Redirect';
use constant BINDING_SOAP          => saml2 . 'bindings:SOAP';
use constant BINDING_POAS          => saml2 . 'bindings:POAS';
use constant BINDING_REVERSE_SOAP  => BINDING_POAS;

use constant CLASS_UNSPECIFIED        => saml2 . 'ac:classes:unspecified';
use constant CLASS_PASSWORD_PROTECTED => saml2 . 'ac:classes:PasswordProtectedTransport';
use constant CLASS_M2FA_UNREGISTERED  => saml2 . 'ac:classes:MobileTwoFactorUnregistered';
use constant CLASS_M2FA_CONTRACT      => saml2 . 'ac:classes:MobileTwoFactorContract';
use constant CLASS_SMARTCARD          => saml2 . 'ac:classes:Smartcard';
use constant CLASS_SMARTCARD_PKI      => saml2 . 'ac:classes:SmartcardPKI';

use constant NAMEID_FORMAT        => saml1_1 . 'nameid-format';
use constant NAMEID_FORMAT_ENTITY => saml1_1 . 'nameid-format-entity';
use constant NAMEID_EMAIL         => saml1_1 . 'nameid-format:emailAddress';
use constant NAMEID_TRANSIENT     => saml1_1 . 'nameid-format:transient';
use constant NAMEID_PERSISTENT    => saml1_1 . 'nameid-format:persistent';

use constant STATUS_AUTH_FAILED    => saml2 . 'status:AuthnFailed';
use constant STATUS_REQUESTER      => saml2 . 'status:Requester';
use constant STATUS_REQUEST_DENIED => saml2 . 'status:RequestDenied';
use constant STATUS_RESPONDER      => saml2 . 'status:Responder';
use constant STATUS_SUCCESS        => saml2 . 'status:Success';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

URN::OASIS::SAML2 - Constants for urn:oasis SAML2 implementations

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    # All at once
    use URN::OASIS::SAML2 qw(:all);

    # or use one of the export tags

=head1 DESCRIPTION

This module provides constants which are in use by the SAML2 implementation.

=head1 Available export tags

=head2 urn

    use URN::OASIS::SAML2 qw(:urn);
    use URN::OASIS::SAML2 qw(
        URN_ASSERTION
        URN_METADATA
        URN_PROTOCOL
        URN_SIGNATURE
        URN_ENCRYPTION
    );

=head2 ns

    use URN::OASIS::SAML2 qw(:ns);
    use URN::OASIS::SAML2 qw(
        NS_ASSERTION
        NS_METADATA
        NS_PROTOCOL
        NS_SIGNATURE
        NS_ENCRYPTION
    );

=head2 bindings

    use URN::OASIS::SAML2 qw(:binding);
    use URN::OASIS::SAML2 qw(
        BINDING_HTTP_POST
        BINDING_HTTP_ARTIFACT
        BINDING_HTTP_REDIRECT
        BINDING_SOAP
        BINDING_POAS # also available as BINDING_REVERSE_SOAP
    );

=head2 classes

    use URN::OASIS::SAML2 qw(:class);
    use URN::OASIS::SAML2 qw(
        CLASS_UNSPECIFIED
        CLASS_PASSWORD_PROTECTED
        CLASS_M2FA_UNREGISTERED
        CLASS_M2FA_CONTRACT
        CLASS_SMARTCARD
        CLASS_SMARTCARD_PKI
    );

=head2 nameid

    use URN::OASIS::SAML2 qw(:nameid);
    use URN::OASIS::SAML2 qw(
        NAMEID_EMAIL
        NAMEID_TRANSIENT
        NAMEID_PERSISTENT
    );

=head2 status

    use URN::OASIS::SAML2 qw(:status);
    use URN::OASIS::SAML2 qw(
        STATUS_AUTH_FAILED
        STATUS_REQUESTER
        STATUS_REQUEST_DENIED
        STATUS_RESPONDER
        STATUS_SUCCESS
    );

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
