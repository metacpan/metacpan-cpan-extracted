#!/bin/false
# ABSTRACT: OpenVPN instances controller
# PODNAME: WebService::OPNsense::OpenVPN::Instances
use strictures 2;

package WebService::OPNsense::OpenVPN::Instances;
$WebService::OPNsense::OpenVPN::Instances::VERSION = '0.001';
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
    return $self->client->post( $self->_path( 'set/{uuid}', uuid => $uuid ), $instance_data );
}

sub gen_key {
    my ( $self, $type ) = @_;
    return $self->client->get(
        $self->_path( 'genKey{/type}', type => $type ),
    );
}

sub search_static_key {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchStaticKey'), \%params );
}

sub get_static_key {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getStaticKey/{uuid}', uuid => $uuid ) );
}

sub add_static_key {
    my ( $self, $key_data ) = @_;
    return $self->client->post( $self->_path('addStaticKey'), $key_data );
}

sub set_static_key {
    my ( $self, $uuid, $key_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setStaticKey/{uuid}', uuid => $uuid ), $key_data );
}

sub del_static_key {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delStaticKey/{uuid}', uuid => $uuid ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::OpenVPN::Instances - OpenVPN instances controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $instances = $opn->openvpn_instances;

    # List instances
    my $list = $instances->search(current => 1, rowCount => 50);

    # Create an instance
    $instances->add({
        server => {
            enabled  => 1,
            port     => 1194,
            protocol => 'UDP',
        },
    });

    # Toggle an instance
    $instances->toggle($uuid, 0);

    # Generate a key
    my $key = $instances->gen_key('tls-crypt');

=head1 DESCRIPTION

OpenVPN server and client instances.

=head1 NAME

WebService::OPNsense::OpenVPN::Instances - OpenVPN instances controller

=head1 METHODS

=head2 set_instance

    my $result = $instances->set_instance($uuid, $instance_data);

Updates an existing instance.

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

Creates a new static key.

=head2 set_static_key

    my $result = $instances->set_static_key($uuid, $key_data);

Updates an existing static key.

=head2 del_static_key

    my $result = $instances->del_static_key($uuid);

Deletes a static key by UUID.

=for Pod::Coverage _api_path _path client search get add del toggle

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
