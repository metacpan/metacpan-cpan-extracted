#!/bin/false
# ABSTRACT: Role for item CRUD methods
# PODNAME: WebService::OPNsense::Role::ItemCrud
use strictures 2;

package WebService::OPNsense::Role::ItemCrud;
$WebService::OPNsense::Role::ItemCrud::VERSION = '0.002';
use Moo::Role;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

sub add_item {
    my ( $self, $item_data ) = @_;
    my $uri = $self->_path('addItem');

    return $self->client->post( $uri, $item_data );
}

sub del_item {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delItem/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub get_item {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getItem/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub search_item {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchItem');

    return $self->client->get( $uri, \%params );
}

sub set_item {
    my ( $self, $uuid, $item_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setItem/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $item_data );
}

sub toggle_item {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleItem/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::ItemCrud - Role for item CRUD methods

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Provides shared item CRUD methods (search_item, get_item, add_item, set_item,
del_item, toggle_item).  All methods in this section are called on the
consuming object, not on the role directly.

This role is consumed by L<WebService::OPNsense::IPsec::KeyPairs>,
L<WebService::OPNsense::IPsec::PreSharedKeys>,
L<WebService::OPNsense::Firewall::Alias>, and
L<WebService::OPNsense::Firewall::Category>.

=head1 PROVIDED METHODS

=head2 search_item

    my $results = $ctrl->search_item( %params );

Searches for items.

=head2 get_item

    my $item = $ctrl->get_item( $uuid );

Returns a single item by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add_item

    my $result = $ctrl->add_item( $item_data );

Creates item.

=head2 set_item

    my $result = $ctrl->set_item( $uuid, $item_data );

Updates item.  Throws if C<$uuid> is not a valid UUID.

=head2 del_item

    my $result = $ctrl->del_item( $uuid );

Deletes an item by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle_item

    my $result = $ctrl->toggle_item( $uuid, $enabled );

Enables or disables an item.  Throws if C<$uuid> is not a valid UUID.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::IPsec::KeyPairs>,
L<WebService::OPNsense::IPsec::PreSharedKeys>,
L<WebService::OPNsense::Firewall::Alias>,
L<WebService::OPNsense::Firewall::Category>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
