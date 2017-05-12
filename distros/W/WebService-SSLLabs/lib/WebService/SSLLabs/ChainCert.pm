package WebService::SSLLabs::ChainCert;

use strict;
use warnings;

our $VERSION = '0.27';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub subject {
    my ($self) = @_;
    return $self->{subject};
}

sub label {
    my ($self) = @_;
    return $self->{label};
}

sub not_before {
    my ($self) = @_;
    return $self->{notBefore};
}

sub not_after {
    my ($self) = @_;
    return $self->{notAfter};
}

sub issuer_subject {
    my ($self) = @_;
    return $self->{issuerSubject};
}

sub issuer_label {
    my ($self) = @_;
    return $self->{issuerLabel};
}

sub sig_alg {
    my ($self) = @_;
    return $self->{sigAlg};
}

sub issues {
    my ($self) = @_;
    return $self->{issues};
}

sub key_alg {
    my ($self) = @_;
    return $self->{keyAlg};
}

sub key_size {
    my ($self) = @_;
    return $self->{keySize};
}

sub key_strength {
    my ($self) = @_;
    return $self->{keyStrength};
}

sub revocation_status {
    my ($self) = @_;
    return $self->{revocationStatus};
}

sub crl_revocation_status {
    my ($self) = @_;
    return $self->{crlRevocationStatus};
}

sub ocsp_revocation_status {
    my ($self) = @_;
    return $self->{ocspRevocationStatus};
}

sub raw {
    my ($self) = @_;
    return $self->{raw};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::ChainCert - ChainCert object

=head1 VERSION

Version 0.27

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::ChainCert> object, accepts a hash ref as it's parameter.

=head2 subject

certificate subject

=head2 label

certificate label (user-friendly name)

=head2 not_before

=head2 not_after

=head2 issuer_subject

issuer subject

=head2 issuer_label

issuer label (user-friendly name)

=head2 sig_alg

=head2 issues

a number of flags the describe the problems with this certificate:

=over 2

=item bit 0 (1) - certificate not yet valid

=item bit 1 (2) - certificate expired

=item bit 2 (4) - weak key

=item bit 3 (8) - weak signature

=item bit 4 (16) - blacklisted

=back

=head2 key_alg

key algorithm.

=head2 key_size

key size, in bits appopriate for the key algorithm.

=head2 key_strength

key strength, in equivalent RSA bits.

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

=head2 raw

PEM-encoded certificate data 

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::ChainCert requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::ChainCert requires no non-core modules

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

    perldoc WebService::SSLLabs::ChainCert


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
