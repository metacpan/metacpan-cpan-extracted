#!/bin/false
# ABSTRACT: IPsec manual SPD (Security Policy Database) controller
# PODNAME: WebService::OPNsense::IPsec::ManualSpd
use strictures 2;

package WebService::OPNsense::IPsec::ManualSpd;
$WebService::OPNsense::IPsec::ManualSpd::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/manual_spd';
}

with 'WebService::OPNsense::Role::Crud';

sub set_manual_spd {
    my ( $self, $uuid, $spd_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'set/{uuid}', uuid => $uuid ), $spd_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::ManualSpd - IPsec manual SPD (Security Policy Database) controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $mspd = $opn->ipsec_manual_spd;

    my $results = $mspd->search;
    $mspd->add({ spd => { ... } });

=head1 DESCRIPTION

Manages manual IPsec Security Policy Database entries.

=head1 NAME

WebService::OPNsense::IPsec::ManualSpd - IPsec manual SPD controller

=head1 METHODS

=head2 set_manual_spd

    my $result = $mspd->set_manual_spd($uuid, $spd_data);

Updates an existing manual SPD entry.

=for Pod::Coverage _api_path _path client search get add del toggle

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
