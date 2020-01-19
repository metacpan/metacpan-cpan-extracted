package WebService::SSLLabs::Suite;

use strict;
use warnings;
use WebService::SSLLabs::Suite();

our $VERSION = '0.32';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub cipher_strength {
    my ($self) = @_;
    return $self->{cipherStrength};
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub ecdh_bits {
    my ($self) = @_;
    return $self->{ecdhBits};
}

sub ecdh_strength {
    my ($self) = @_;
    return $self->{ecdhStrength};
}

sub dh_strength {
    my ($self) = @_;
    return $self->{dhStrength};
}

sub dh_ys {
    my ($self) = @_;
    return $self->{dhYs};
}

sub dh_g {
    my ($self) = @_;
    return $self->{dhG};
}

sub dh_p {
    my ($self) = @_;
    return $self->{dhP};
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub q {
    my ($self) = @_;
    return $self->{q};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Suite - Suite object

=head1 VERSION

Version 0.32

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Suite> object, accepts a hash ref as it's parameter.

=head2 id

suite RFC ID (e.g., 5)

=head2 name

suite name (e.g., TLS_RSA_WITH_RC4_128_SHA)

=head2 cipher_strength

suite strength (e.g., 128)

=head2 dh_strength

strength of DH params (e.g., 1024)

=head2 dh_p

DH params, p component

=head2 dh_g

DH params, g component

=head2 dh_ys

DH params, Ys component

=head2 ecdh_bits

ECDH bits

=head2 ecdh_strength

ECDH RSA-equivalent strength

=head2 q

0 if the suite is insecure, null otherwise

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Suite requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Suite requires no non-core modules

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

    perldoc WebService::SSLLabs::Suite


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
