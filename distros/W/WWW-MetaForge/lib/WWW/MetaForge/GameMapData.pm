package WWW::MetaForge::GameMapData;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Perl client for the MetaForge Game Map Data API
our $VERSION = '0.002';

use Moo;
use LWP::UserAgent;
use JSON::MaybeXS;
use Carp qw(croak);
use namespace::clean;

use WWW::MetaForge::Cache;
use WWW::MetaForge::GameMapData::Request;
use WWW::MetaForge::GameMapData::Result::MapMarker;

our $DEBUG = $ENV{WWW_METAFORGE_GAMEMAPDATA_DEBUG};


has ua => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_ua',
);


has request => (
  is      => 'ro',
  lazy    => 1,
  default => sub { WWW::MetaForge::GameMapData::Request->new },
);


has cache => (
  is        => 'ro',
  lazy      => 1,
  builder   => '_build_cache',
  predicate => 'has_cache',
);


has use_cache => (
  is      => 'ro',
  default => 1,
);


has cache_dir => (
  is => 'ro',
);


has json => (
  is      => 'ro',
  lazy    => 1,
  default => sub { JSON::MaybeXS->new(utf8 => 1) },
);


has debug => (
  is      => 'ro',
  default => sub { $DEBUG },
);


has marker_class => (
  is      => 'ro',
  default => 'WWW::MetaForge::GameMapData::Result::MapMarker',
);


sub _debug {
  my ($self, $msg) = @_;
  return unless $self->debug;
  my $ts = localtime;
  warn "[WWW::MetaForge::GameMapData $ts] $msg\n";
}

sub _build_ua {
  my ($self) = @_;
  my $ua = LWP::UserAgent->new(
    agent   => 'WWW-MetaForge-GameMapData/' . ($WWW::MetaForge::GameMapData::VERSION // 'dev'),
    timeout => 30,
  );
  return $ua;
}

sub _build_cache {
  my ($self) = @_;
  my %args;
  $args{cache_dir} = $self->cache_dir if defined $self->cache_dir;
  return WWW::MetaForge::Cache->new(%args);
}

sub _fetch {
  my ($self, $endpoint, $http_request, %params) = @_;

  if ($self->use_cache) {
    my $cached = $self->cache->get($endpoint, \%params);
    if (defined $cached) {
      $self->_debug("CACHE HIT: $endpoint");
      return $cached;
    }
    $self->_debug("CACHE MISS: $endpoint");
  }

  my $url = $http_request->uri;
  $self->_debug("REQUEST: GET $url");

  my $response = $self->ua->request($http_request);

  $self->_debug("RESPONSE: " . $response->code . " " . $response->message);

  unless ($response->is_success) {
    croak sprintf("API request failed: %s %s",
      $response->code, $response->message);
  }

  my $data = eval { $self->json->decode($response->decoded_content) };
  croak "Failed to parse JSON response: $@" if $@;

  if ($self->use_cache) {
    $self->cache->set($endpoint, \%params, $data);
    $self->_debug("CACHE SET: $endpoint");
  }

  return $data;
}

sub _extract_markers {
  my ($self, $response) = @_;

  return $response unless ref $response eq 'HASH';

  # API returns {"allData": [...]} for arc_map_data tableID
  if (exists $response->{allData}) {
    return $response->{allData};
  }
  # Fallback: {"markers": [...]} or {"data": {"markers": [...]}}
  if (exists $response->{markers}) {
    return $response->{markers};
  }
  if (exists $response->{data} && ref $response->{data} eq 'HASH') {
    return $response->{data}{markers} // [];
  }

  return $response;
}

sub _to_objects {
  my ($self, $data) = @_;

  return [] unless defined $data;

  my $class = $self->marker_class;

  if (ref $data eq 'ARRAY') {
    return [ map { $class->from_hashref($_) } @$data ];
  } elsif (ref $data eq 'HASH') {
    # Single item - wrap in array for consistency
    return [ $class->from_hashref($data) ];
  }

  return $data;
}

sub map_data {
  my ($self, %params) = @_;
  my $req = $self->request->map_data(%params);
  my $response = $self->_fetch('map_data', $req, %params);
  my $markers = $self->_extract_markers($response);
  return $self->_to_objects($markers);
}


sub map_data_raw {
  my ($self, %params) = @_;
  my $req = $self->request->map_data(%params);
  return $self->_fetch('map_data', $req, %params);
}


sub clear_cache {
  my ($self, $endpoint) = @_;
  $self->cache->clear($endpoint);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::GameMapData - Perl client for the MetaForge Game Map Data API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::MetaForge::GameMapData;

    my $api = WWW::MetaForge::GameMapData->new;

    # Get map markers for a specific map
    my $markers = $api->map_data(map => 'dam');
    for my $marker (@$markers) {
        say $marker->type . " at " . $marker->x . "," . $marker->y;
    }

    # Filter by marker type
    my $loot = $api->map_data(map => 'dam', type => 'loot');

=head1 DESCRIPTION

Perl interface to the MetaForge Game Map Data API. This API provides
map marker data (POIs, loot locations, quest markers, etc.) for games
supported by MetaForge.

This is a generic base module. Game-specific distributions (like
L<WWW::MetaForge::ArcRaiders>) can use this module and extend the
result classes with game-specific attributes.

=head2 ua

L<LWP::UserAgent> instance. Built lazily with sensible defaults.

=head2 request

L<WWW::MetaForge::GameMapData::Request> instance for creating
L<HTTP::Request> objects.

=head2 cache

L<WWW::MetaForge::Cache> instance for response caching.

=head2 use_cache

Boolean, default true. Set to false to disable caching.

=head2 cache_dir

Optional L<Path::Tiny> path for cache directory. Defaults to
XDG cache dir on Unix, LOCALAPPDATA on Windows.

=head2 json

L<JSON::MaybeXS> instance for encoding/decoding JSON.

=head2 debug

Boolean. Enable debug output. Also settable via
C<$ENV{WWW_METAFORGE_GAMEMAPDATA_DEBUG}>.

=head2 marker_class

Class to use for map marker objects. Defaults to
L<WWW::MetaForge::GameMapData::Result::MapMarker>. Override this
to use a subclass with game-specific attributes.

=head2 map_data

    my $markers = $api->map_data(map => 'dam');
    my $markers = $api->map_data(map => 'dam', type => 'loot');

Returns ArrayRef of L<WWW::MetaForge::GameMapData::Result::MapMarker>
(or subclass specified by C<marker_class>).

Required parameter: C<map> - name of the map to fetch markers for.
Optional parameter: C<type> - filter by marker type.

=head2 map_data_raw

Same as C<map_data> but returns raw HashRef/ArrayRef instead of objects.

=head2 clear_cache

    $api->clear_cache('map_data');  # Clear specific endpoint
    $api->clear_cache;              # Clear all

Clear cached responses.

=head1 ATTRIBUTION

This module uses the MetaForge API: L<https://metaforge.app>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-metaforge/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
