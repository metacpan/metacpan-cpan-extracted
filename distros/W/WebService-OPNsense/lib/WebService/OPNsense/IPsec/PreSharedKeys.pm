#!/bin/false
# ABSTRACT: IPsec pre-shared key controller
# PODNAME: WebService::OPNsense::IPsec::PreSharedKeys
use strictures 2;

package WebService::OPNsense::IPsec::PreSharedKeys;
$WebService::OPNsense::IPsec::PreSharedKeys::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/pre_shared_keys';
}

with 'WebService::OPNsense::Role::ItemCrud';

sub get {
    my ($self) = @_;
    return $self->client->get( $self->_path('get') );
}

sub set_settings {
    my ( $self, $settings_data ) = @_;
    return $self->client->post( $self->_path('set'), $settings_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::PreSharedKeys - IPsec pre-shared key controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $psk = $opn->ipsec_pre_shared_keys;

    my $items = $psk->search_item;
    $psk->add_item({ ... });

=head1 DESCRIPTION

Manages IPsec pre-shared keys.

=head1 NAME

WebService::OPNsense::IPsec::PreSharedKeys - IPsec pre-shared key controller

=head1 METHODS

=head2 get

    my $config = $psk->get;

Returns the pre-shared key configuration.

=head2 set_settings

    my $result = $psk->set_settings($settings_data);

Sets the pre-shared key configuration.

=for Pod::Coverage _api_path _path client search_item get_item add_item set_item del_item

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
