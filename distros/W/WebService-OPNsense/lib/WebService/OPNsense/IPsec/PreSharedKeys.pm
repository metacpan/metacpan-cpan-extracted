#!/bin/false
# ABSTRACT: IPsec pre-shared key controller
# PODNAME: WebService::OPNsense::IPsec::PreSharedKeys
use strictures 2;

package WebService::OPNsense::IPsec::PreSharedKeys;
$WebService::OPNsense::IPsec::PreSharedKeys::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/pre_shared_keys';
}

with 'WebService::OPNsense::Role::ItemCrud';
with 'WebService::OPNsense::Role::Settings';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::PreSharedKeys - IPsec pre-shared key controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $psk = $opn->ipsec_pre_shared_keys;

    my $items = $psk->search_item;
    $psk->add_item({ ... });

=head1 DESCRIPTION

Manages IPsec pre-shared keys.

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search_item

    my $results = $ctrl->search_item( %params );

Searches for pre-shared keys.

=head2 get_item

    my $item = $ctrl->get_item( $uuid );

Returns a single pre-shared key by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add_item

    my $result = $ctrl->add_item( $item_data );

Creates a pre-shared key.

=head2 set_item

    my $result = $ctrl->set_item( $uuid, $item_data );

Updates a pre-shared key.  Throws if C<$uuid> is not a valid UUID.

=head2 del_item

    my $result = $ctrl->del_item( $uuid );

Deletes a pre-shared key by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle_item

    my $result = $ctrl->toggle_item( $uuid, $enabled );

Enables or disables a pre-shared key.  Throws if C<$uuid> is not a valid UUID.

=head2 get_settings

    my $config = $ctrl->get_settings;

Returns pre-shared key settings.

=head2 set_settings

    my $result = $ctrl->set_settings( $settings_data );

Updates pre-shared key settings.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::ItemCrud>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
