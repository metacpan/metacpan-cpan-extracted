#!/bin/false
# ABSTRACT: IPsec VTI (Virtual Tunnel Interface) controller
# PODNAME: WebService::OPNsense::IPsec::Vti
use strictures 2;

package WebService::OPNsense::IPsec::Vti;
$WebService::OPNsense::IPsec::Vti::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/vti';
}

with 'WebService::OPNsense::Role::Crud';

sub set_vti {
    my ( $self, $uuid, $vti_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'set/{uuid}', uuid => $uuid ), $vti_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Vti - IPsec VTI (Virtual Tunnel Interface) controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $vti = $opn->ipsec_vti;

    my $results = $vti->search;
    $vti->add({ vti => { ... } });

=head1 DESCRIPTION

IPsec Virtual Tunnel Interfaces.

=head1 NAME

WebService::OPNsense::IPsec::Vti - IPsec VTI (Virtual Tunnel Interface) controller

=head1 METHODS

=head2 set_vti

    my $result = $vti->set_vti($uuid, $vti_data);

Updates an existing VTI entry.

=for Pod::Coverage _api_path _path client search get add del toggle

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
