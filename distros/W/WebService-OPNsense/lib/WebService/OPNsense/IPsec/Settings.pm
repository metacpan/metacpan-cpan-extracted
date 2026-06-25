#!/bin/false
# ABSTRACT: IPsec settings controller
# PODNAME: WebService::OPNsense::IPsec::Settings
use strictures 2;

package WebService::OPNsense::IPsec::Settings;
$WebService::OPNsense::IPsec::Settings::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/settings';
}

with 'WebService::OPNsense::Role::Settings';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Settings - IPsec settings controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $settings = $opn->ipsec_settings;

    my $config = $settings->get;
    $settings->set_settings({ ipsec => { ... } });

=head1 DESCRIPTION

Reads and writes IPsec settings

=head1 NAME

WebService::OPNsense::IPsec::Settings - IPsec settings controller

=head1 METHODS

=head2 get

    my $config = $settings->get;

Returns the current IPsec settings.

=head2 set_settings

    my $result = $settings->set_settings($settings_data);

Updates the IPsec settings.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
