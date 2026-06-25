#!/bin/false
# ABSTRACT: Role for settings get/set methods
# PODNAME: WebService::OPNsense::Role::Settings
use strictures 2;

package WebService::OPNsense::Role::Settings;
$WebService::OPNsense::Role::Settings::VERSION = '0.001';
use Moo::Role;
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

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

WebService::OPNsense::Role::Settings - Role for settings get/set methods

=head1 VERSION

version 0.001

=for Pod::Coverage _api_path _path client get set_settings

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
