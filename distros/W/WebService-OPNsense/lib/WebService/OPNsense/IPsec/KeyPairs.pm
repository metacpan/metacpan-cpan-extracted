#!/bin/false
# ABSTRACT: IPsec key pair controller
# PODNAME: WebService::OPNsense::IPsec::KeyPairs
use strictures 2;

package WebService::OPNsense::IPsec::KeyPairs;
$WebService::OPNsense::IPsec::KeyPairs::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/key_pairs';
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

version 0.001

=head1 SYNOPSIS

    my $kp = $opn->ipsec_key_pairs;

    my $items = $kp->search_item;
    $kp->gen_key_pair('RSA', 2048);

=head1 DESCRIPTION

Manages IPsec key pairs.

=head1 NAME

WebService::OPNsense::IPsec::KeyPairs - IPsec key pair controller

=head1 METHODS

=head2 get

    my $config = $kp->get;

Returns the key pair configuration.

=head2 set_settings

    my $result = $kp->set_settings($settings_data);

Sets the key pair configuration.

=head2 gen_key_pair

    my $result = $kp->gen_key_pair($type, $size);

Generates a new key pair.  Optionally specify C<$type> (e.g. C<'RSA'>) and
C<$size> (e.g. C<2048>).

=for Pod::Coverage _api_path _path client search_item get_item add_item set_item del_item

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
