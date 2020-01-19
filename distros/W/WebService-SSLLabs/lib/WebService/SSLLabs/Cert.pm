package WebService::SSLLabs::Cert;

use strict;
use warnings;
use URI();

our $VERSION = '0.32';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub alt_names {
    my ($self) = @_;
    return @{ $self->{altNames} };
}

sub issuer_subject {
    my ($self) = @_;
    return $self->{issuerSubject};
}

sub issues {
    my ($self) = @_;
    return $self->{issues};
}

sub ocsp_revocation_status {
    my ($self) = @_;
    return $self->{ocspRevocationStatus};
}

sub ocsp_uris {
    my ($self) = @_;
    return map { URI->new($_) } @{ $self->{ocspURIs} };
}

sub revocation_info {
    my ($self) = @_;
    return $self->{revocationInfo};
}

sub sgc {
    my ($self) = @_;
    return $self->{sgc} ? 1 : 0;
}

sub validation_type {
    my ($self) = @_;
    return $self->{validationType};
}

sub sct {
    my ($self) = @_;
    return $self->{sct} ? 1 : 0;
}

sub sig_alg {
    my ($self) = @_;
    return $self->{sigAlg};
}

sub common_names {
    my ($self) = @_;
    return map { URI->new($_) } @{ $self->{commonNames} };
}

sub crl_uris {
    my ($self) = @_;
    return map { URI->new($_) } @{ $self->{crlURIs} };
}

sub issuer_label {
    my ($self) = @_;
    return $self->{issuerLabel};
}

sub subject {
    my ($self) = @_;
    return $self->{subject};
}

sub not_before {
    my ($self) = @_;
    return $self->{notBefore};
}

sub revocation_status {
    my ($self) = @_;
    return $self->{revocationStatus};
}

sub not_after {
    my ($self) = @_;
    return $self->{notAfter};
}

sub crl_revocation_status {
    my ($self) = @_;
    return $self->{crlRevocationStatus};
}

sub must_staple {
    my ($self) = @_;
    return $self->{mustStaple};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Cert - Cert object

=head1 VERSION

Version 0.32

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Cert> object, accepts a hash ref as it's parameter.

=head2 subject

certificate subject

=head2 common_names

list of common names extracted from the subject

=head2 alt_names

alternative names

=head2 not_before

UNIX timestamp before which the certificate is not valid

=head2 not_after

UNIX timestamp after which the certificate is not valid

=head2 issuer_subject

issuer subject

=head2 sig_alg

certificate signature algorithm

=head2 issuer_label

issuer name

=head2 revocation_info

a number that represents revocation information present in the certificate:

=over 2

=item bit 0 (1) - CRL information available

=item bit 1 (2) - OCSP information available

=back

=head2 crl_uris

list of CRL L<URI|URI>s extracted from the certificate.

=head2 ocsp_uris

list of OCSP L<URI|URI>s extracted from the certificate

=head2 revocation_status

a number that describes the revocation status of the certificate:

=over 2

=item 0 - not checked

=item 1 - certificate revoked

=item 2 - certificate not revoked

=item 3 - revocation check error

=item 4 - no revocation information

=item 5 - internal error

=back

=head2 crl_revocation_status

same as revocationStatus, but only for the CRL information (if any).

=head2 ocsp_revocation_status

same as revocationStatus, but only for the OCSP information (if any).

=head2 sgc

Server Gated Cryptography support; integer:

=over 2

=item bit 1 (1) - WebServicescape SGC

=item bit 2 (2) - Microsoft SGC

=back

=head2 validation_type

E for Extended Validation certificates; may be null if unable to determine

=head2 issues

list of certificate issues, one bit per issue:

=over 2

=item bit 0 (1) - no chain of trust

=item bit 1 (2) - not before

=item bit 2 (4) - not after

=item bit 3 (8) - hostname mismatch

=item bit 4 (16) - revoked

=item bit 5 (32) - bad common name

=item bit 6 (64) - self-signed

=item bit 7 (128) - blacklisted

=item bit 8 (256) - insecure signature

=back

=head2 sct

true if the certificate contains an embedded SCT; false otherwise.

=head2 must_staple

a number that describes the must staple feature extension status

=over 2

=item 0 - not supported

=item 1 - Supported, but OCSP response is not stapled

=item 2 - Supported, OCSP response is stapled

=back

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Cert requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Cert requires the following non-core modules

  URI

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-ssllabs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-SSLLabs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::SSLLabs::Cert


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-SSLLabs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-SSLLabs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-SSLLabs>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-SSLLabs/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ivan Ristic and the team at L<https://www.qualys.com> for providing the service at L<https://www.ssllabs.com>

POD was extracted from the API help at L<https://github.com/ssllabs/ssllabs-scan/blob/stable/ssllabs-api-docs.md>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
