#!/bin/false
# ABSTRACT: OpenVPN instances controller
# PODNAME: WebService::OPNsense::OpenVPN::Instances
use strictures 2;

package WebService::OPNsense::OpenVPN::Instances;
$WebService::OPNsense::OpenVPN::Instances::VERSION = '0.003';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/openvpn/instances';
}

with 'WebService::OPNsense::Role::Crud';

sub set_instance {
    my ( $self, $uuid, $instance_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'set/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $instance_data );
}

sub gen_key {
    my ( $self, $type ) = @_;
    my $uri = $self->_path( 'genKey{/type}', type => $type );

    return $self->client->get(
        $uri,
    );
}

sub search_static_key {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchStaticKey');

    return $self->client->get( $uri, \%params );
}

sub get_static_key {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getStaticKey/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub add_static_key {
    my ( $self, $key_data ) = @_;
    my $uri = $self->_path('addStaticKey');

    return $self->client->post( $uri, $key_data );
}

sub set_static_key {
    my ( $self, $uuid, $key_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setStaticKey/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $key_data );
}

sub del_static_key {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delStaticKey/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::OpenVPN::Instances - OpenVPN instances controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::OPNsense::Constants qw( $PROTO_UDP $OPN_ENABLED $OPN_DISABLED );

    my $instances = $opn->openvpn_instances;

    # List instances
    my $list = $instances->search(current => 1, rowCount => 50);

    # Create an instance
    $instances->add({
        server => {
            enabled  => $OPN_ENABLED,
            port     => 1194,
            protocol => $PROTO_UDP,
        },
    });

    # Toggle an instance
    $instances->toggle($uuid, $OPN_DISABLED);

    # Generate a key
    my $key = $instances->gen_key('tls-crypt');

=head1 DESCRIPTION

OpenVPN server and client instances.

=head1 METHODS

=head2 set_instance

    my $result = $instances->set_instance($uuid, $instance_data);

Updates instance.

=head2 gen_key

    my $key = $instances->gen_key;
    my $key = $instances->gen_key($type);

Generates an OpenVPN key.  Optionally specify a key type (e.g. C<'tls-crypt'>).

=head2 search_static_key

    my $results = $instances->search_static_key(%params);

Searches for static keys.

=head2 get_static_key

    my $key = $instances->get_static_key($uuid);

Returns a single static key by UUID.

=head2 add_static_key

    my $result = $instances->add_static_key($key_data);

Creates static key.

=head2 set_static_key

    my $result = $instances->set_static_key($uuid, $key_data);

Updates static key.

=head2 del_static_key

    my $result = $instances->del_static_key($uuid);

Deletes a static key by UUID.

=head1 CONSTANTS

Protocol constants are available from
L<WebService::OPNsense::Constants>:

=over

=item C<$PROTO_UDP>

=item C<$PROTO_TCP>

=back

Use them when setting the C<protocol> field in an instance.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Crud>

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search

    my $results = $ctrl->search( %params );

Searches for OpenVPN instances.

=head2 get

    my $instance = $ctrl->get( $uuid );

Returns a single instance by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add

    my $result = $ctrl->add( $instance_data );

Creates an instance.

=head2 del

    my $result = $ctrl->del( $uuid );

Deletes an instance by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle

    my $result = $ctrl->toggle( $uuid, $enabled );

Enables or disables an instance.  Throws if C<$uuid> is not a valid UUID.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
