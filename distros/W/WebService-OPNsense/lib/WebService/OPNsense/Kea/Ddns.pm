#!/bin/false
# ABSTRACT: Kea DDNS controller
# PODNAME: WebService::OPNsense::Kea::Ddns
use strictures 2;

package WebService::OPNsense::Kea::Ddns;
$WebService::OPNsense::Kea::Ddns::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/kea/ddns';
}

with 'WebService::OPNsense::Role::Settings';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::Ddns - Kea DDNS controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $ddns = $opn->kea_ddns;

    my $config = $ddns->get;

    $ddns->set({ ... });

=head1 DESCRIPTION

Manages Kea DDNS configuration.

=head1 NAME

WebService::OPNsense::Kea::Ddns - Kea DDNS controller

=head1 METHODS

=head2 get

    my $config = $ddns->get;

Returns the full Kea DDNS configuration.

=head2 set_settings

    my $result = $ddns->set_settings($config_data);

Updates the Kea DDNS configuration.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
