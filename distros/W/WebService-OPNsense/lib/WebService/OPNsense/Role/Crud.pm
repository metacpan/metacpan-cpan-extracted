#!/bin/false
# ABSTRACT: Role for plain-name CRUD methods
# PODNAME: WebService::OPNsense::Role::Crud
use strictures 2;

package WebService::OPNsense::Role::Crud;
$WebService::OPNsense::Role::Crud::VERSION = '0.001';
use Moo::Role;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

sub add {
    my ( $self, $record_data ) = @_;
    return $self->client->post( $self->_path('add'), $record_data );
}

sub del {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'del/{uuid}', uuid => $uuid ) );
}

sub get {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'get/{uuid}', uuid => $uuid ) );
}

sub search {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('search'), \%params );
}

sub toggle {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggle/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::Crud - Role for plain-name CRUD methods

=head1 VERSION

version 0.001

=for Pod::Coverage _api_path _path client add del get search toggle

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
