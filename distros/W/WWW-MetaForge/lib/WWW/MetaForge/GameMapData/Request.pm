package WWW::MetaForge::GameMapData::Request;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: HTTP request builder for MetaForge Game Map Data API

use Moo;
use HTTP::Request;
use URI;
use namespace::clean;

has base_url => (
  is      => 'ro',
  default => 'https://metaforge.app/api/game-map-data',
);

sub _build_request {
  my ($self, %params) = @_;

  my $uri = URI->new($self->base_url);
  $uri->query_form(%params) if %params;

  return HTTP::Request->new(GET => $uri);
}

sub map_data {
  my ($self, %params) = @_;
  # tableID is required for arc-raiders map data
  $params{tableID} //= 'arc_map_data';
  # Accept 'map' as alias for 'mapID'
  $params{mapID} //= delete $params{map} if exists $params{map};
  return $self->_build_request(%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::GameMapData::Request - HTTP request builder for MetaForge Game Map Data API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use WWW::MetaForge::GameMapData::Request;

  my $req = WWW::MetaForge::GameMapData::Request->new;

  # Build request for map data
  my $http_req = $req->map_data(map => 'Dam');

  # With type filter
  my $http_req = $req->map_data(map => 'Dam', type => 'loot');

=head1 DESCRIPTION

Builds L<HTTP::Request> objects for the MetaForge Game Map Data API.
Useful for integrating with async HTTP frameworks.

=head1 ATTRIBUTES

=head2 base_url

Base URL for the API. Defaults to C<https://metaforge.app/api/game-map-data>.

=head1 METHODS

=head2 map_data

  my $http_req = $req->map_data(map => 'Dam');

Returns L<HTTP::Request> for fetching map marker data.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-metaforge>

  git clone https://github.com/Getty/p5-www-metaforge.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
