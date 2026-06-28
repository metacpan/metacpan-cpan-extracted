#!/bin/false
# ABSTRACT: Kea control agent controller
# PODNAME: WebService::OPNsense::Kea::CtrlAgent
use strictures 2;

package WebService::OPNsense::Kea::CtrlAgent;
$WebService::OPNsense::Kea::CtrlAgent::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/kea/ctrl_agent';
}

with 'WebService::OPNsense::Role::Settings';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::CtrlAgent - Kea control agent controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $ctrl_agent = $opn->kea_ctrl_agent;

    my $config = $ctrl_agent->get;

    $ctrl_agent->set_settings({ ... });

=head1 DESCRIPTION

Kea control agent configuration.

=head1 METHODS

=head2 get_settings

    my $config = $ctrl_agent->get_settings;

Returns the full Kea control agent configuration.

=head2 set_settings

    my $result = $ctrl_agent->set_settings($config_data);

Updates the Kea control agent configuration.

=head2 client

    my $http_client = $ctrl_agent->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Settings>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
