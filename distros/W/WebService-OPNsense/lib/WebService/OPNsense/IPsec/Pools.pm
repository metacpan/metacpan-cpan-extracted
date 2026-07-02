#!/bin/false
# ABSTRACT: IPsec pool controller
# PODNAME: WebService::OPNsense::IPsec::Pools
use strictures 2;

package WebService::OPNsense::IPsec::Pools;
$WebService::OPNsense::IPsec::Pools::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/pools';
}

with 'WebService::OPNsense::Role::Crud';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Pools - IPsec pool controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $pools = $opn->ipsec_pools;

    my $results = $pools->search;
    $pools->add({ pool => { ... } });

=head1 DESCRIPTION

Manages IPsec pools.

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search

    my $results = $ctrl->search( %params );

Searches for pools.

=head2 get

    my $pool = $ctrl->get( $uuid );

Returns a single pool by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 set

    my $result = $ctrl->set( $uuid, $pool_data );

Updates a pool by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add

    my $result = $ctrl->add( $pool_data );

Creates pool.

=head2 del

    my $result = $ctrl->del( $uuid );

Deletes a pool by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle

    my $result = $ctrl->toggle( $uuid, $enabled );

Enables or disables a pool.  Throws if C<$uuid> is not a valid UUID.

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
