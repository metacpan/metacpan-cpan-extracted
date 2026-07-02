#!/bin/false
# ABSTRACT: OpenVPN client overwrites controller
# PODNAME: WebService::OPNsense::OpenVPN::ClientOverwrites
use strictures 2;

package WebService::OPNsense::OpenVPN::ClientOverwrites;
$WebService::OPNsense::OpenVPN::ClientOverwrites::VERSION = '0.003';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/openvpn/client_overwrites';
}

with 'WebService::OPNsense::Role::Crud';

sub set_overwrite {
    my ( $self, $uuid, $overwrite_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'set/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $overwrite_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::OpenVPN::ClientOverwrites - OpenVPN client overwrites controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $overwrites = $opn->openvpn_client_overwrites;

    my $list = $overwrites->search(current => 1, rowCount => 50);

    $overwrites->add({
        overwrite => {
            description => 'Custom client config',
        },
    });

=head1 DESCRIPTION

Manages OpenVPN client-specific configuration overwrites.

=head1 METHODS

=head2 set_overwrite

    my $result = $overwrites->set_overwrite($uuid, $overwrite_data);

Updates client overwrite.

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search

    my $results = $ctrl->search( %params );

Searches for client overwrites.

=head2 get

    my $overwrite = $ctrl->get( $uuid );

Returns a single client overwrite by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add

    my $result = $ctrl->add( $overwrite_data );

Creates client overwrite.

=head2 del

    my $result = $ctrl->del( $uuid );

Deletes a client overwrite by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle

    my $result = $ctrl->toggle( $uuid, $enabled );

Enables or disables a client overwrite.  Throws if C<$uuid> is not a valid UUID.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Crud>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
