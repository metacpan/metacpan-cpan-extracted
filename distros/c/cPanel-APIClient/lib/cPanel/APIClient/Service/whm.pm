package cPanel::APIClient::Service::whm;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Service::whm - WebHost Manager access

=head1 SYNOPSIS

If your transport uses blocking I/O:

    my $resp = $client->call_api1('listaccts', \%args);

    my $pops_ar = $resp->get_data();

If your transport uses non-blocking I/O:

    my $call = $client->call_api1('listaccts', \%args);

    $call->promise()->then( sub {
        my ($resp) = @_;

        my $pops_ar = $resp->get_data();
    } );

Some non-blocking transports support canceling in-progress requests, thus:

    $client->cancel($call, ..);

See your transport’s documentation for more details.

=head1 DESCRIPTION

This class stores a WHM API access configuration and exposes
methods to call WHM APIs. It extends L<cPanel::APIClient::Service>.

Don’t try to create this object directly; instead, let
C<cPanel::APIClient->create()> do it for you.

=cut

#----------------------------------------------------------------------

use parent qw( cPanel::APIClient::Service );

# overridden in tests
our $_PORT = 2087;

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<OBJ>->call_api1( $FUNCTION_NAME, \%ARGUMENTS )

Calls WHM API v1.

I<OBJ>’s transport configuration will determine what precisely is returned;
however, it should eventually yield a L<cPanel::APIClient::Response::WHM1>
instance.

See L<cPanel’s WHM API v1 documentation|https://documentation.cpanel.net/display/DD/Guide+to+WHM+API+1> for documentation of the available API functions.

=cut

sub call_api1 {
    my ( $self, $func, $args_hr, $metaargs_hr ) = @_;

    require cPanel::APIClient::Request::WHM1;
    my $req = cPanel::APIClient::Request::WHM1->new( $func, $args_hr, $metaargs_hr );

    return $self->{'transporter'}->request( $self, $req );
}

#----------------------------------------------------------------------

=head2 I<OBJ>->call_cpanel_uapi( $USERNAME, $MODULE_NAME, $FUNCTION_NAME, \%ARGUMENTS )

Like C<call_api1()> but calls cPanel UAPI from a WHM connection.
Its eventual yield will be a L<cPanel::APIClient::Response::UAPI>
instance.

=cut

sub call_cpanel_uapi {
    my ( $self, $cpusername, $mod, $func, $args_hr, $metaargs_hr ) = @_;

    require cPanel::APIClient::Request::UAPIFromWHM1;
    my $req = cPanel::APIClient::Request::UAPIFromWHM1->new( $cpusername, $mod, $func, $args_hr, $metaargs_hr );

    return $self->{'transporter'}->request( $self, $req );
}

#----------------------------------------------------------------------

# left undocumented since unneeded
sub get_https_port {
    return $_PORT;
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
