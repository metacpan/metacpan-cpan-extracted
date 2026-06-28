#!/bin/false
# ABSTRACT: Role for plain-name CRUD methods
# PODNAME: WebService::OPNsense::Role::Crud
use strictures 2;

package WebService::OPNsense::Role::Crud;
$WebService::OPNsense::Role::Crud::VERSION = '0.002';
use Moo::Role;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

sub add {
    my ( $self, $record_data ) = @_;
    my $uri = $self->_path('add');

    return $self->client->post( $uri, $record_data );
}

sub del {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'del/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub get {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'get/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub search {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('search');

    return $self->client->get( $uri, \%params );
}

sub set {
    my ( $self, $uuid, $record_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'set/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $record_data );
}

sub toggle {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggle/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::Crud - Role for plain-name CRUD methods

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Provides shared plain-name CRUD methods (search, get, set, add, del, toggle).
All methods in this section are called on the consuming object, not on the
role directly.

This role is consumed by L<WebService::OPNsense::IPsec::Pools>,
L<WebService::OPNsense::IPsec::Vti>,
L<WebService::OPNsense::IPsec::ManualSpd>,
L<WebService::OPNsense::OpenVPN::Instances>, and
L<WebService::OPNsense::OpenVPN::ClientOverwrites>.

=head1 PROVIDED METHODS

=head2 search

    my $results = $ctrl->search( %params );

Searches for records.

=head2 get

    my $record = $ctrl->get( $uuid );

Returns a single record by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 set

    my $result = $ctrl->set( $uuid, $record_data );

Updates a record by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add

    my $result = $ctrl->add( $record_data );

Creates record.

=head2 del

    my $result = $ctrl->del( $uuid );

Deletes a record by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle

    my $result = $ctrl->toggle( $uuid, $enabled );

Enables or disables a record.  Throws if C<$uuid> is not a valid UUID.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::IPsec::Pools>,
L<WebService::OPNsense::IPsec::Vti>,
L<WebService::OPNsense::IPsec::ManualSpd>,
L<WebService::OPNsense::OpenVPN::Instances>,
L<WebService::OPNsense::OpenVPN::ClientOverwrites>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
