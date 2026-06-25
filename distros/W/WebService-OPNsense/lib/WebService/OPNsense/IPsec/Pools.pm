#!/bin/false
# ABSTRACT: IPsec pool controller
# PODNAME: WebService::OPNsense::IPsec::Pools
use strictures 2;

package WebService::OPNsense::IPsec::Pools;
$WebService::OPNsense::IPsec::Pools::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/pools';
}

with 'WebService::OPNsense::Role::Crud';

sub set_pool {
    my ( $self, $uuid, $pool_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'set/{uuid}', uuid => $uuid ), $pool_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Pools - IPsec pool controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $pools = $opn->ipsec_pools;

    my $results = $pools->search;
    $pools->add({ pool => { ... } });

=head1 DESCRIPTION

Manages IPsec pools.

=head1 NAME

WebService::OPNsense::IPsec::Pools - IPsec pool controller

=head1 METHODS

=head2 set_pool

    my $result = $pools->set_pool($uuid, $pool_data);

Updates an existing pool.

=for Pod::Coverage _api_path _path client search get add del toggle

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
