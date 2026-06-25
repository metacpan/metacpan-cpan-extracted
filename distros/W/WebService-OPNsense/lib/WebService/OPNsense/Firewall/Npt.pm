#!/bin/false
# ABSTRACT: Firewall NPT (network prefix translation) rule controller
# PODNAME: WebService::OPNsense::Firewall::Npt
use strictures 2;

package WebService::OPNsense::Firewall::Npt;
$WebService::OPNsense::Firewall::Npt::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/firewall/npt';
}

with 'WebService::OPNsense::Firewall::Role::NAT';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::Npt - Firewall NPT (network prefix translation) rule controller

=head1 VERSION

version 0.001

=for Pod::Coverage _api_path client search_rule get_rule add_rule set_rule del_rule
toggle_rule toggle_rule_log move_rule_before apply savepoint cancel_rollback revert
set_settings get list_categories list_network_select_options list_port_select_options

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
