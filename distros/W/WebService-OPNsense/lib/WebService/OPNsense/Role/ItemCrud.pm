#!/bin/false
# ABSTRACT: Role for item CRUD methods
# PODNAME: WebService::OPNsense::Role::ItemCrud
use strictures 2;

package WebService::OPNsense::Role::ItemCrud;
$WebService::OPNsense::Role::ItemCrud::VERSION = '0.001';
use Moo::Role;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

sub add_item {
    my ( $self, $item_data ) = @_;
    return $self->client->post( $self->_path('addItem'), $item_data );
}

sub del_item {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delItem/{uuid}', uuid => $uuid ) );
}

sub get_item {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getItem/{uuid}', uuid => $uuid ) );
}

sub search_item {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchItem'), \%params );
}

sub set_item {
    my ( $self, $uuid, $item_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setItem/{uuid}', uuid => $uuid ), $item_data );
}

sub toggle_item {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleItem/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::ItemCrud - Role for item CRUD methods

=head1 VERSION

version 0.001

=for Pod::Coverage _api_path _path client add_item del_item get_item search_item set_item toggle_item

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
