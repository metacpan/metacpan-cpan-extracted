package WWW::MetaForge::ArcRaiders;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Perl client for the MetaForge ARC Raiders API
our $VERSION = '0.002';

use Moo;
use LWP::UserAgent;
use JSON::MaybeXS;
use Carp qw(croak);
use namespace::clean;

our $DEBUG = $ENV{WWW_METAFORGE_ARCRAIDERS_DEBUG};

use WWW::MetaForge::Cache;
use WWW::MetaForge::GameMapData;
use WWW::MetaForge::ArcRaiders::Request;
use WWW::MetaForge::ArcRaiders::Result::Item;
use WWW::MetaForge::ArcRaiders::Result::Arc;
use WWW::MetaForge::ArcRaiders::Result::Quest;
use WWW::MetaForge::ArcRaiders::Result::Trader;
use WWW::MetaForge::ArcRaiders::Result::EventTimer;
use WWW::MetaForge::ArcRaiders::Result::MapMarker;


# Fixed list of ARC Raiders maps (API mapID format)
our @MAPS = qw(dam spaceport buried-city blue-gate stella-montis);
our %MAP_DISPLAY_NAMES = (
  'dam'           => 'Dam',
  'spaceport'     => 'Spaceport',
  'buried-city'   => 'Buried City',
  'blue-gate'     => 'Blue Gate',
  'stella-montis' => 'Stella Montis',
);

sub maps { return @MAPS }


sub map_display_names { return %MAP_DISPLAY_NAMES }


sub map_display_name {
  my ($self, $map_id) = @_;
  return $MAP_DISPLAY_NAMES{$map_id} // $map_id;
}


has ua => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_ua',
);


has request => (
  is      => 'ro',
  lazy    => 1,
  default => sub { WWW::MetaForge::ArcRaiders::Request->new },
);


has cache => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_cache',
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


sub _debug {
  my ($self, $msg) = @_;
  return unless $self->debug;
  my $ts = localtime;
  warn "[WWW::MetaForge::ArcRaiders $ts] $msg\n";
}

sub _build_ua {
  my ($self) = @_;
  my $ua = LWP::UserAgent->new(
    agent   => 'WWW-MetaForge-ArcRaiders/' . ($WWW::MetaForge::ArcRaiders::VERSION // 'dev'),
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

has game_map_data => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_game_map_data',
);


sub _build_game_map_data {
  my ($self) = @_;
  return WWW::MetaForge::GameMapData->new(
    debug        => $self->debug,
    use_cache    => $self->use_cache,
    cache        => $self->cache,  # Share cache with ArcRaiders
    marker_class => 'WWW::MetaForge::ArcRaiders::Result::MapMarker',
  );
}

sub _fetch {
  my ($self, $endpoint, $http_request, %params) = @_;

  my $skip_cache = delete $params{_skip_cache};

  if ($self->use_cache && !$skip_cache) {
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

  my $count = ref $data eq 'ARRAY' ? scalar(@$data) : 1;
  $self->_debug("PARSED: $count records");

  if ($self->use_cache && !$skip_cache) {
    $self->cache->set($endpoint, \%params, $data);
    $self->_debug("CACHE SET: $endpoint");
  }

  return $data;
}

sub _extract_data {
  my ($self, $response) = @_;

  return $response unless ref $response eq 'HASH';

  # API returns {"data": ...} or {"success": true, "data": ...}
  if (exists $response->{data}) {
    return $response->{data};
  }

  return $response;
}

sub _to_objects {
  my ($self, $data, $class) = @_;

  return [] unless defined $data;

  if (ref $data eq 'ARRAY') {
    return [ map { $class->from_hashref($_) } @$data ];
  } elsif (ref $data eq 'HASH') {
    # Single item from API (e.g., when querying by id=) - wrap in array for consistency
    return [ $class->from_hashref($data) ];
  }

  return $data;
}

# Generic paginated fetch - returns {data => [...], pagination => {...}}
sub _fetch_paginated {
  my ($self, $endpoint, $request_method, $result_class, %params) = @_;

  my $req = $self->request->$request_method(%params);
  my $response = $self->_fetch($endpoint, $req, %params);
  my $data = $self->_extract_data($response);
  my $pagination = ref $response eq 'HASH' ? $response->{pagination} : undef;

  return {
    data       => $self->_to_objects($data, $result_class),
    pagination => $pagination,
  };
}

# Fetch all pages for a paginated endpoint
sub _fetch_all_pages {
  my ($self, $endpoint, $request_method, $result_class, %params) = @_;

  my @all_data;
  my $current_page = 1;

  while (1) {
    $params{page} = $current_page;
    my $result = $self->_fetch_paginated($endpoint, $request_method, $result_class, %params);
    push @all_data, @{$result->{data}};

    my $pagination = $result->{pagination};
    last unless $pagination && $pagination->{hasNextPage};
    $current_page++;
  }

  return \@all_data;
}

sub items {
  my ($self, %params) = @_;
  return $self->_fetch_paginated('items', 'items', 'WWW::MetaForge::ArcRaiders::Result::Item', %params)->{data};
}


sub items_paginated {
  my ($self, %params) = @_;
  return $self->_fetch_paginated('items', 'items', 'WWW::MetaForge::ArcRaiders::Result::Item', %params);
}


sub items_all {
  my ($self, %params) = @_;
  return $self->_fetch_all_pages('items', 'items', 'WWW::MetaForge::ArcRaiders::Result::Item', %params);
}


# Legacy alias
sub items_with_pagination { shift->items_paginated(@_) }

sub arcs {
  my ($self, %params) = @_;
  return $self->_fetch_paginated('arcs', 'arcs', 'WWW::MetaForge::ArcRaiders::Result::Arc', %params)->{data};
}


sub arcs_paginated {
  my ($self, %params) = @_;
  return $self->_fetch_paginated('arcs', 'arcs', 'WWW::MetaForge::ArcRaiders::Result::Arc', %params);
}


sub arcs_all {
  my ($self, %params) = @_;
  return $self->_fetch_all_pages('arcs', 'arcs', 'WWW::MetaForge::ArcRaiders::Result::Arc', %params);
}


sub quests {
  my ($self, %params) = @_;
  return $self->_fetch_paginated('quests', 'quests', 'WWW::MetaForge::ArcRaiders::Result::Quest', %params)->{data};
}


sub quests_paginated {
  my ($self, %params) = @_;
  return $self->_fetch_paginated('quests', 'quests', 'WWW::MetaForge::ArcRaiders::Result::Quest', %params);
}


sub quests_all {
  my ($self, %params) = @_;
  return $self->_fetch_all_pages('quests', 'quests', 'WWW::MetaForge::ArcRaiders::Result::Quest', %params);
}


# Legacy alias
sub quests_with_pagination {
  my ($self, %params) = @_;
  my $result = $self->quests_paginated(%params);
  return { quests => $result->{data}, pagination => $result->{pagination} };
}

sub traders {
  my ($self, %params) = @_;
  my $req = $self->request->traders(%params);
  my $response = $self->_fetch('traders', $req, %params);
  my $data = $self->_extract_data($response);

  # Traders API returns {"TraderName": [...items...], ...}
  # Convert to array of trader objects
  if (ref $data eq 'HASH' && !exists $data->{id}) {
    my @traders;
    for my $name (sort keys %$data) {
      push @traders, WWW::MetaForge::ArcRaiders::Result::Trader->new(
        name      => $name,
        inventory => $data->{$name},
        _raw      => { name => $name, inventory => $data->{$name} },
      );
    }
    return \@traders;
  }

  return $self->_to_objects($data, 'WWW::MetaForge::ArcRaiders::Result::Trader');
}


# event_timers: always fresh (no cache) - time-critical data
sub event_timers {
  my ($self, %params) = @_;
  my $req = $self->request->event_timers(%params);
  my $response = $self->_fetch('event_timers', $req, %params, _skip_cache => 1);
  my $data = $self->_extract_data($response);
  return $self->_group_event_timers($data);
}


# Group flat event list by name+map into EventTimer objects with TimeSlots
sub _group_event_timers {
  my ($self, $data) = @_;

  return [] unless $data && ref $data eq 'ARRAY';

  # Group by name+map
  my %grouped;
  for my $event (@$data) {
    my $key = ($event->{name} // '') . '|' . ($event->{map} // '');
    push @{ $grouped{$key} }, $event;
  }

  # Build EventTimer objects from grouped data
  my @timers;
  for my $key (sort keys %grouped) {
    my $events = $grouped{$key};
    my ($name, $map) = split /\|/, $key, 2;
    push @timers, WWW::MetaForge::ArcRaiders::Result::EventTimer->from_grouped(
      $name, $map, $events
    );
  }

  return \@timers;
}

# event_timers_cached: use cache (for when you don't need live data)
sub event_timers_cached {
  my ($self, %params) = @_;
  my $req = $self->request->event_timers(%params);
  my $response = $self->_fetch('event_timers', $req, %params);
  my $data = $self->_extract_data($response);
  return $self->_group_event_timers($data);
}


# event_timers_hourly: cached but invalidates at the start of each hour
sub event_timers_hourly {
  my ($self, %params) = @_;

  # Calculate current hour boundary (epoch time at minute 0 of current hour)
  my $now = time();
  my $current_hour = int($now / 3600) * 3600;

  # Check if we have valid cached data from this hour
  my $cache_key = 'event_timers_hourly';
  if ($self->use_cache) {
    my $cache_file = $self->cache->_cache_file($cache_key, \%params);
    if ($cache_file->is_file) {
      my $cached = eval { $self->json->decode($cache_file->slurp_utf8) };
      if ($cached && ref $cached eq 'HASH') {
        my $cached_time = $cached->{timestamp} // 0;
        # Valid if cached in the same hour
        if ($cached_time >= $current_hour) {
          $self->_debug("CACHE HIT (hourly): $cache_key");
          my $data = $cached->{data};
          return $self->_group_event_timers($data);
        }
        $self->_debug("CACHE EXPIRED (new hour): $cache_key");
      }
    }
  }

  # Fetch fresh data
  my $req = $self->request->event_timers(%params);
  my $response = $self->_fetch('event_timers', $req, %params, _skip_cache => 1);
  my $data = $self->_extract_data($response);

  # Store in our hourly cache
  if ($self->use_cache) {
    $self->cache->set($cache_key, \%params, $data);
    $self->_debug("CACHE SET (hourly): $cache_key");
  }

  return $self->_group_event_timers($data);
}


sub map_data {
  my ($self, %params) = @_;
  return $self->game_map_data->map_data(%params);
}


sub items_raw {
  my ($self, %params) = @_;
  my $req = $self->request->items(%params);
  return $self->_fetch('items', $req, %params);
}


sub arcs_raw {
  my ($self, %params) = @_;
  my $req = $self->request->arcs(%params);
  return $self->_fetch('arcs', $req, %params);
}

sub quests_raw {
  my ($self, %params) = @_;
  my $req = $self->request->quests(%params);
  return $self->_fetch('quests', $req, %params);
}

sub traders_raw {
  my ($self, %params) = @_;
  my $req = $self->request->traders(%params);
  return $self->_fetch('traders', $req, %params);
}

sub event_timers_raw {
  my ($self, %params) = @_;
  my $req = $self->request->event_timers(%params);
  return $self->_fetch('event_timers', $req, %params);
}

sub map_data_raw {
  my ($self, %params) = @_;
  return $self->game_map_data->map_data_raw(%params);
}

sub clear_cache {
  my ($self, $endpoint) = @_;
  $self->cache->clear($endpoint);
}


# Internal cache for item lookups (populated on first use)
has _items_cache => (
  is      => 'rw',
  default => sub { undef },
);

sub _ensure_items_cache {
  my ($self) = @_;
  return $self->_items_cache if $self->_items_cache;

  $self->_debug("Loading all items for requirements calculation...");
  my $items = $self->items_all(includeComponents => 'true');
  my %by_name;
  my %by_id;
  for my $item (@$items) {
    $by_name{lc($item->name)} = $item;
    $by_id{$item->id} = $item;
  }
  $self->_items_cache({ by_name => \%by_name, by_id => \%by_id, list => $items });
  $self->_debug("Loaded " . scalar(@$items) . " items");
  return $self->_items_cache;
}

sub find_item_by_name {
  my ($self, $name) = @_;
  my $cache = $self->_ensure_items_cache;
  return $cache->{by_name}{lc($name)};
}


sub find_item_by_id {
  my ($self, $id) = @_;
  my $cache = $self->_ensure_items_cache;
  return $cache->{by_id}{$id};
}


# Extract component name from crafting requirement
# Handles both string format and object format from API
sub _component_name {
  my ($self, $component) = @_;
  return unless defined $component;
  return ref($component) eq 'HASH' ? $component->{name} : $component;
}

sub calculate_requirements {
  my ($self, %args) = @_;
  my $items = $args{items} // [];

  my %total;
  my @missing;

  for my $req (@$items) {
    my $name = $req->{item} // $req->{name};
    my $count = $req->{count} // $req->{quantity} // 1;

    my $item = $self->find_item_by_name($name);
    unless ($item) {
      push @missing, { item => $name, count => $count, reason => 'not_found' };
      next;
    }

    my $crafting = $item->crafting_requirements // [];
    if (@$crafting) {
      for my $mat (@$crafting) {
        my $mat_name = $self->_component_name($mat->{component});
        my $mat_count = ($mat->{quantity} // 1) * $count;
        $total{$mat_name} += $mat_count if $mat_name;
      }
    } else {
      # Item has no crafting requirements - it's already a base material
      push @missing, { item => $name, count => $count, reason => 'not_craftable' };
    }
  }

  # Resolve total to item objects
  my @requirements;
  for my $name (sort keys %total) {
    my $item = $self->find_item_by_name($name);
    if ($item) {
      push @requirements, { item => $item, count => $total{$name} };
    } else {
      push @missing, { item => $name, count => $total{$name}, reason => 'material_not_found' };
    }
  }

  return {
    requirements => \@requirements,
    missing      => \@missing,
  };
}


sub calculate_base_requirements {
  my ($self, %args) = @_;
  my $items = $args{items} // [];
  my $max_depth = $args{max_depth} // 20;  # Prevent infinite loops

  my %total;
  my @missing;
  my %seen;  # Track items being processed to detect cycles

  my $resolve;
  $resolve = sub {
    my ($name, $count, $depth) = @_;

    if ($depth > $max_depth) {
      push @missing, { item => $name, count => $count, reason => 'max_depth_exceeded' };
      return;
    }

    my $item = $self->find_item_by_name($name);
    unless ($item) {
      push @missing, { item => $name, count => $count, reason => 'not_found' };
      return;
    }

    my $crafting = $item->crafting_requirements // [];

    # Base material: no crafting requirements
    if (!@$crafting) {
      $total{lc($item->name)} += $count;
      return;
    }

    # Cycle detection
    my $key = lc($item->name);
    if ($seen{$key}) {
      push @missing, { item => $name, count => $count, reason => 'cycle_detected' };
      return;
    }
    $seen{$key} = 1;

    # Recursively resolve each material
    for my $mat (@$crafting) {
      my $mat_name = $self->_component_name($mat->{component});
      my $mat_count = ($mat->{quantity} // 1) * $count;
      $resolve->($mat_name, $mat_count, $depth + 1) if $mat_name;
    }

    delete $seen{$key};
  };

  for my $req (@$items) {
    my $name = $req->{item} // $req->{name};
    my $count = $req->{count} // $req->{quantity} // 1;
    $resolve->($name, $count, 0);
  }

  # Resolve total to item objects
  my @requirements;
  for my $name (sort keys %total) {
    my $item = $self->find_item_by_name($name);
    if ($item) {
      push @requirements, { item => $item, count => $total{$name} };
    } else {
      push @missing, { item => $name, count => $total{$name}, reason => 'base_material_not_found' };
    }
  }

  return {
    requirements => \@requirements,
    missing      => \@missing,
  };
}


# Clear internal item cache (call after items data might have changed)
sub clear_items_cache {
  my ($self) = @_;
  $self->_items_cache(undef);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders - Perl client for the MetaForge ARC Raiders API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::MetaForge::ArcRaiders;

    my $api = WWW::MetaForge::ArcRaiders->new;

    # Get items
    my $items = $api->items;
    for my $item (@$items) {
        say $item->name . " (" . $item->rarity . ")";
    }

    # Search with parameters
    my $ferro = $api->items(search => 'Ferro');

    # Event timers with helper methods
    my $events = $api->event_timers;
    for my $event (@$events) {
        say $event->name;
        say "  Active!" if $event->is_active_now;
    }

    # Disable caching
    my $api = WWW::MetaForge::ArcRaiders->new(use_cache => 0);

    # For async usage (e.g., with WWW::Chain)
    my $request = $api->request->items(search => 'Ferro');

=head1 DESCRIPTION

Perl interface to the MetaForge ARC Raiders API for game data
(items, ARCs, quests, traders, event timers, map data).

=head2 maps

    my @maps = $api->maps;

Returns list of available ARC Raiders map IDs (e.g., C<dam>, C<spaceport>,
C<buried-city>, C<blue-gate>, C<stella-montis>).

=head2 map_display_names

    my %names = $api->map_display_names;

Returns hash of map ID to display name (e.g., C<dam> => "Dam").

=head2 map_display_name

    my $name = $api->map_display_name('dam');  # "Dam"

Returns human-readable display name for a map ID. Falls back to the
ID itself if no display name is available.

=head2 ua

L<LWP::UserAgent> instance. Built lazily with sensible defaults.

=head2 request

L<WWW::MetaForge::ArcRaiders::Request> instance for creating
L<HTTP::Request> objects. Use for async framework integration.

=head2 cache

L<WWW::MetaForge::Cache> instance for response caching.

=head2 use_cache

Boolean, default true. Set to false to disable caching.

=head2 cache_dir

Optional L<Path::Tiny> path for cache directory. Defaults to
XDG cache dir on Unix, LOCALAPPDATA on Windows.

=head2 json

L<JSON::MaybeXS> instance for encoding/decoding JSON responses.

=head2 debug

Boolean. Enable debug output. Also settable via
C<$ENV{WWW_METAFORGE_ARCRAIDERS_DEBUG}>.

=head2 game_map_data

L<WWW::MetaForge::GameMapData> instance used for C<map_data> calls.
Configured automatically with ARC Raiders specific marker class.

=head2 items

    my $items = $api->items(%params);

Returns ArrayRef of L<WWW::MetaForge::ArcRaiders::Result::Item> from
first page. Supports C<search>, C<page>, C<limit> parameters.

=head2 items_paginated

    my $result = $api->items_paginated(%params);
    my $items = $result->{data};
    my $pagination = $result->{pagination};

Returns HashRef with C<data> (items ArrayRef) and C<pagination> info
(total, page, totalPages, hasNextPage).

=head2 items_all

    my $items = $api->items_all(%params);

Fetches all pages and returns complete ArrayRef of all items.
Use with caution on large datasets.

=head2 arcs

    my $arcs = $api->arcs(%params);

Returns ArrayRef of L<WWW::MetaForge::ArcRaiders::Result::Arc> from
first page. Supports C<includeLoot> parameter.

=head2 arcs_paginated

    my $result = $api->arcs_paginated(%params);

Returns HashRef with C<data> and C<pagination> info.

=head2 arcs_all

    my $arcs = $api->arcs_all(%params);

Fetches all pages and returns complete ArrayRef of all ARCs.

=head2 quests

    my $quests = $api->quests(%params);

Returns ArrayRef of L<WWW::MetaForge::ArcRaiders::Result::Quest> from
first page. Supports C<type> parameter.

=head2 quests_paginated

    my $result = $api->quests_paginated(%params);

Returns HashRef with C<data> and C<pagination> info.

=head2 quests_all

    my $quests = $api->quests_all(%params);

Fetches all pages and returns complete ArrayRef of all quests.

=head2 traders

    my $traders = $api->traders(%params);

Returns ArrayRef of L<WWW::MetaForge::ArcRaiders::Result::Trader>.

=head2 event_timers

    my $events = $api->event_timers(%params);

Returns ArrayRef of L<WWW::MetaForge::ArcRaiders::Result::EventTimer>.
Always fetches fresh data (bypasses cache) since event timers are time-sensitive.

=head2 event_timers_cached

    my $events = $api->event_timers_cached(%params);

Like C<event_timers> but uses cache. Only use when you don't need
real-time event status.

=head2 event_timers_hourly

    my $events = $api->event_timers_hourly;

Like C<event_timers_cached> but invalidates the cache at the start of
each hour (when minute becomes 0). Useful for scheduled data that
updates hourly.

=head2 map_data

    my $markers = $api->map_data(%params);

Returns ArrayRef of L<WWW::MetaForge::ArcRaiders::Result::MapMarker>.
Supports C<map> parameter.

=head2 items_raw

=head2 arcs_raw

=head2 quests_raw

=head2 traders_raw

=head2 event_timers_raw

=head2 map_data_raw

Same as the corresponding methods but return raw HashRef/ArrayRef instead of result objects.

=head2 clear_cache

    $api->clear_cache('items');  # Clear specific endpoint
    $api->clear_cache;           # Clear all

Clear cached responses.

=head2 find_item_by_name

    my $item = $api->find_item_by_name('Ferro I');

Find an item by exact name (case-insensitive). Loads all items on first
call for fast subsequent lookups.

=head2 find_item_by_id

    my $item = $api->find_item_by_id('ferro-i');

Find an item by its ID.

=head2 calculate_requirements

    my $result = $api->calculate_requirements(
      items => [
        { item => 'Ferro II', count => 2 },
        { item => 'Advanced Circuit', count => 1 },
      ]
    );

    for my $req (@{$result->{requirements}}) {
      say $req->{item}->name . " x" . $req->{count};
    }

Calculate the direct crafting materials needed to build the given items.
Returns a hashref with:

=over

=item requirements

ArrayRef of C<< { item => $item_obj, count => N } >>

=item missing

ArrayRef of items that couldn't be resolved (not found, not craftable, etc.)

=back

=head2 calculate_base_requirements

    my $result = $api->calculate_base_requirements(
      items     => [{ item => 'Ferro III', count => 1 }],
      max_depth => 10,  # optional, default 20
    );

Like C<calculate_requirements> but recursively resolves all crafting
chains down to base materials (items with no crafting requirements).
Includes cycle detection and depth limiting.

=head2 clear_items_cache

    $api->clear_items_cache;

Clear the internal item lookup cache. Call this if item data may have
changed and you need fresh data for C<find_item_*> and C<calculate_*>
methods.

=head1 ATTRIBUTION

This module uses the MetaForge ARC Raiders API. Please respect their terms:

  Terms of Usage

  This API contains data maintained by our team and community
  contributors. If you use this API in a public project, you must
  include attribution and a link to metaforge.app/arc-raiders so
  others know where the data comes from.

  Commercial/Paid Projects: If you plan to use this API in a paid
  app, subscription service, or any product monetized in any way,
  please contact us first via Discord.

  For (limited) support, visit our Discord.

=over

=item *

MetaForge ARC Raiders: L<https://metaforge.app/arc-raiders>

=item *

MetaForge Discord: L<https://discord.gg/8UEK9TrQDs>

=back

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
