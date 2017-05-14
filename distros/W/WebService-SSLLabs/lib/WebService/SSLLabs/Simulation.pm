package WebService::SSLLabs::Simulation;

use strict;
use warnings;
use WebService::SSLLabs::SimClient();

our $VERSION = '0.28';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    $self->{client} = WebService::SSLLabs::SimClient->new( $self->{client} );
    return $self;
}

sub client {
    my ($self) = @_;
    return $self->{client};
}

sub error_code {
    my ($self) = @_;
    return $self->{errorCode};
}

sub attempts {
    my ($self) = @_;
    return $self->{attempts};
}

sub protocol_id {
    my ($self) = @_;
    return $self->{protocolId};
}

sub suite_id {
    my ($self) = @_;
    return $self->{suiteId};
}

sub kx_info {
    my ($self) = @_;
    return $self->{kxInfo};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Simulation - Simulation object

=head1 VERSION

Version 0.28

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Simulation> object, accepts a hash ref as it's parameter.

=head2 client

instance of L<SimClient|WebService::SSLLabs::SimClient>.

=head2 error_code

zero if handshake was successful, 1 if it was not.

=head2 attempts

always 1 with the current implementation.

=head2 protocol_id

Negotiated protocol ID.

=head2 suite_id

key exchange info.

=head2 kx_info

Negotiated suite ID.

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Simulation requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Simulation requires no non-core modules

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

    perldoc WebService::SSLLabs::Simulation


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
