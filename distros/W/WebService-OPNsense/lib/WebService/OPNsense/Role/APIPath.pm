#!/bin/false
# ABSTRACT: Role providing _path helper for URI::Template URL construction
# PODNAME: WebService::OPNsense::Role::APIPath
use strictures 2;

package WebService::OPNsense::Role::APIPath;
$WebService::OPNsense::Role::APIPath::VERSION = '0.003';
use Moo::Role;
use namespace::clean;

requires 'client';
requires '_api_path';

sub _path {
    my ( $self, $endpoint, %vars ) = @_;
    require URI::Template;
    my $api_path = $self->_api_path;
    my $uri      = "$api_path/$endpoint";
    return URI::Template->new($uri)->process( \%vars );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::APIPath - Role providing _path helper for URI::Template URL construction

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Provides a shared C<_path> helper for L<URI::Template>-based URL construction.
Consuming classes must provide a C<_api_path> method and consume the
L<WebService::Client> role.

This role is consumed by L<WebService::OPNsense::Role::Crud>,
L<WebService::OPNsense::Role::ItemCrud>,
L<WebService::OPNsense::Role::Service>,
L<WebService::OPNsense::Role::Settings>,
L<WebService::OPNsense::Firewall::Role::NAT>,
L<WebService::OPNsense::Backup>,
L<WebService::OPNsense::IPsec::Tunnel>,
L<WebService::OPNsense::OpenVPN::Export>, and
L<WebService::OPNsense::Routes>.

=head1 REQUIRED METHODS

=head2 client

    my $http_client = $ctrl->client;

Provided by the consuming class via L<WebService::Client>.

=head2 _api_path

    my $api_path = $ctrl->_api_path;

Returns the base API path string for the controller (e.g. C</api/firewall/filter>).

=head1 PROVIDED METHODS

=head2 _path

    my $uri = $ctrl->_path( $endpoint, %vars );

Constructs a URI by combining C<_api_path> with C<$endpoint> and expanding
any template variables via L<URI::Template>.

    # /api/firewall/filter/searchRule
    my $uri = $self->_path('searchRule');

    # /api/firewall/filter/getRule/123
    my $uri = $self->_path('getRule/:id', id => 123);

=head1 SEE ALSO

L<WebService::OPNsense::Role::Crud>,
L<WebService::OPNsense::Role::ItemCrud>,
L<WebService::OPNsense::Role::Service>,
L<WebService::OPNsense::Role::Settings>,
L<WebService::OPNsense::Firewall::Role::NAT>,
L<WebService::OPNsense::Backup>,
L<WebService::OPNsense::IPsec::Tunnel>,
L<WebService::OPNsense::OpenVPN::Export>,
L<WebService::OPNsense::Routes>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
