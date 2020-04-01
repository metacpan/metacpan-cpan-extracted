package WebService::SSLLabs::Key;

use strict;
use warnings;

our $VERSION = '0.33';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub strength {
    my ($self) = @_;
    return $self->{strength};
}

sub debian_flaw {
    my ($self) = @_;
    return $self->{debianFlaw} ? 1 : 0;
}

sub alg {
    my ($self) = @_;
    return $self->{alg};
}

sub size {
    my ($self) = @_;
    return $self->{size};
}

sub q {
    my ($self) = @_;
    return $self->{q};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Key - Key object

=head1 VERSION

Version 0.33

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Key> object, accepts a hash ref as it's parameter.

=head2 size

key size, e.g., 1024 or 2048 for RSA and DSA, or 256 bits for EC.

=head2 strength

key size expressed in RSA bits.

=head2 alg

key algorithm; possible values: RSA, DSA, and EC.

=head2 debian_flaw

true if we suspect that the key was generated using a weak random number generator (detected via a blacklist database)

=head2 q

0 if key is insecure, null otherwise

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Key requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Key requires no non-core modules

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

    perldoc WebService::SSLLabs::Key


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
