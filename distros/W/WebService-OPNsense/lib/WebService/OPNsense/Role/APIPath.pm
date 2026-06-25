#!/bin/false
# ABSTRACT: Role providing _path helper for URI::Template URL construction
# PODNAME: WebService::OPNsense::Role::APIPath
use strictures 2;

package WebService::OPNsense::Role::APIPath;
$WebService::OPNsense::Role::APIPath::VERSION = '0.001';
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

version 0.001

=for Pod::Coverage _api_path _path client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
