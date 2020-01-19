package WebService::SSLLabs::DrownHost;

use strict;
use warnings;

our $VERSION = '0.32';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub ip {
    my ($self) = @_;
    return $self->{ip};
}

sub export {
    my ($self) = @_;
    return $self->{export} ? 1 : 0;
}

sub port {
    my ($self) = @_;
    return $self->{port};
}

sub special {
    my ($self) = @_;
    return $self->{special} ? 1 : 0;
}

sub sslv2 {
    my ($self) = @_;
    return $self->{sslv2} ? 1 : 0;
}

sub status {
    my ($self) = @_;
    return $self->{status};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::DrownHost - DrownHost object

=head1 VERSION

Version 0.32

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::DrownHost> object, accepts a hash ref as it's parameter.

=head2 ip

IP address of server that shares same RSA-Key/hostname in its certificate

=head2 export

true if export cipher suites detected

=head2 port

port number of the server

=head2 special

true if vulnerable OpenSSL version detected

=head2 sslv2

true if SSL v2 is supported

=head2 status

drown host status

=over 2

=item error - error occurred in test

=item unknown - before the status is checked

=item not_checked - not checked if already vulnerable server found

=item not_checked_same_host - Not checked (same host)

=item handshake_failure - when SSL v2 not supported by server

=item sslv2 - SSL v2 supported but not same rsa key

=item key_match - vulnerable (same key with SSL v2)

=item hostname_match - vulnerable (same hostname with SSL v2)

=back

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::DrownHost requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::DrownHost requires no non-core modules

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

    perldoc WebService::SSLLabs::DrownHost


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

