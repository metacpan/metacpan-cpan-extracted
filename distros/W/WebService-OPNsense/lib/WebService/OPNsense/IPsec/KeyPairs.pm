#!/bin/false
# ABSTRACT: IPsec key pair controller
# PODNAME: WebService::OPNsense::IPsec::KeyPairs
use strictures 2;

package WebService::OPNsense::IPsec::KeyPairs;
$WebService::OPNsense::IPsec::KeyPairs::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/key_pairs';
}

with 'WebService::OPNsense::Role::ItemCrud';
with 'WebService::OPNsense::Role::Settings';

sub gen_key_pair {
    my ( $self, $type, $size ) = @_;
    my $path = $self->_path( 'genKeyPair{/type}{/size}', type => $type, size => $size );
    return $self->client->get($path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::KeyPairs - IPsec key pair controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $kp = $opn->ipsec_key_pairs;

    my $items = $kp->search_item;
    $kp->gen_key_pair('RSA', 2048);

=head1 DESCRIPTION

Manages IPsec key pairs.

=head1 METHODS

=head2 gen_key_pair

    my $result = $kp->gen_key_pair($type, $size);

Generates a new key pair.  Optionally specify C<$type> (e.g. C<'RSA'>) and
C<$size> (e.g. C<2048>).

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search_item

    my $results = $ctrl->search_item( %params );

Searches for key pairs.

=head2 get_item

    my $item = $ctrl->get_item( $uuid );

Returns a single key pair by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add_item

    my $result = $ctrl->add_item( $item_data );

Creates a key pair.

=head2 set_item

    my $result = $ctrl->set_item( $uuid, $item_data );

Updates a key pair.  Throws if C<$uuid> is not a valid UUID.

=head2 del_item

    my $result = $ctrl->del_item( $uuid );

Deletes a key pair by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle_item

    my $result = $ctrl->toggle_item( $uuid, $enabled );

Enables or disables a key pair.  Throws if C<$uuid> is not a valid UUID.

=head2 get_settings

    my $config = $ctrl->get_settings;

Returns key pair settings.

=head2 set_settings

    my $result = $ctrl->set_settings( $settings_data );

Updates key pair settings.

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
