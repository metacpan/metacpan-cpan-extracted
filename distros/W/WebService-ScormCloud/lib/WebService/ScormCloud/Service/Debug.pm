package WebService::ScormCloud::Service::Debug;

use Moose::Role;

with 'WebService::ScormCloud::Service';

=head1 NAME

WebService::ScormCloud::Service::Debug - ScormCloud API "debug" namespace

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use WebService::ScormCloud;

    my $ScormCloud = WebService::ScormCloud->new(
                        app_id      => '12345678',
                        secret_key  => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    );

    print "Service is alive\n" if $ScormCloud->ping;

    print "Auth is valid\n"    if $ScormCloud->authPing;

    print "Service says the UTC time is ", $ScormCloud->getTime, "\n";

=head1 DESCRIPTION

This module defines L<WebService::ScormCloud> API methods in the "debug"
namespace.  See L<WebService::ScormCloud> for more info.

=cut

requires 'process_request';

=head1 METHODS

=head2 ping

Returns true if the API service is reachable.

=cut

sub ping
{
    my ($self) = @_;

    return $self->process_request(
        {method => 'debug.ping'},
        sub {
            my ($response) = @_;

            exists $response->{pong} ? 1 : 0;
        }
    );
}

=head2 authPing

Returns true if the API service is reachable, and both the
application ID and secret key are valid.

=cut

sub authPing    ## no critic (NamingConventions::Capitalization)
{
    my ($self) = @_;

    return $self->process_request(
        {method => 'debug.authPing'},
        sub {
            my ($response) = @_;

            exists $response->{pong} ? 1 : 0;
        }
    );
}

=head2 getTime

Returns the current time at the API service host.  The time is in
UTC and is formatted as "YYYYMMDDhhmmss".

=cut

sub getTime    ## no critic (NamingConventions::Capitalization)
{
    my ($self) = @_;

    return $self->process_request(
        {method => 'debug.getTime'},
        sub {
            my ($response) = @_;

            return $response->{currenttime}->{content};
        }
    );
}

1;

__END__

=head1 SEE ALSO

L<WebService::ScormCloud>

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-scormcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-ScormCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Patches more than welcome, especially via GitHub:
L<https://github.com/larryl/ScormCloud>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ScormCloud::Service::Debug

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/larryl/ScormCloud>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-ScormCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-ScormCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-ScormCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-ScormCloud/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Larry Leszczynski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

