# WWW::MetaForge

Perl client library for the [MetaForge.app](https://metaforge.app) game data API.

Currently supports **ARC Raiders** with:
- Items, ARCs, Quests, Traders
- Event timers with live status
- Interactive map data (POIs, loot locations, etc.)

## Installation

```bash
cpanm WWW::MetaForge
```

Or from source:

```bash
git clone https://github.com/Getty/p5-www-metaforge.git
cd p5-www-metaforge
cpanm --installdeps .
```

## Command-Line Interface

The distribution includes `metaforge-arcraiders` for quick lookups:

```bash
# List items
metaforge-arcraiders items
metaforge-arcraiders items --search Ferro

# Show item details
metaforge-arcraiders item ferro-i

# List quests
metaforge-arcraiders quests

# Show traders and their inventory
metaforge-arcraiders traders

# Event timers (sorted by time)
metaforge-arcraiders events
metaforge-arcraiders events --active   # only currently active

# ARCs (missions/events)
metaforge-arcraiders arcs
```

### Global Options

```bash
--json      # Output as JSON
--no-cache  # Skip cache, fetch fresh data
--debug     # Show debug output
```

## API Usage

```perl
use WWW::MetaForge::ArcRaiders;

my $api = WWW::MetaForge::ArcRaiders->new;

# Items
my $items = $api->items;
my $ferro = $api->items(search => 'Ferro');

for my $item (@$items) {
    say $item->name . " (" . $item->rarity . ")";
    say "  Weight: " . $item->weight if $item->weight;
}

# Quests
my $quests = $api->quests;
for my $quest (@$quests) {
    say $quest->name;
    say "  " . $_ for @{$quest->objectives};
}

# Traders
my $traders = $api->traders;
for my $trader (@$traders) {
    say $trader->name;
    if ($trader->has_item('Ferro I')) {
        my $info = $trader->find_item('Ferro I');
        say "  Sells Ferro I for $info->{trader_price}";
    }
}

# Event timers
my $events = $api->event_timers;
for my $event (@$events) {
    say $event->name . " on " . $event->map;
    if ($event->is_active_now) {
        say "  ACTIVE! Ends in " . $event->time_until_end;
    } else {
        say "  Starts in " . $event->time_until_start;
    }
}

# Map data
my $markers = $api->map_data(map => 'dam');
for my $marker (@$markers) {
    say $marker->category . "/" . $marker->subcategory;
    say "  Position: " . $marker->x . ", " . $marker->y;
}
```

## Pagination

For large result sets, use paginated methods:

```perl
# Get first page with pagination info
my $result = $api->items_paginated(page => 1, limit => 50);
my $items      = $result->{data};
my $pagination = $result->{pagination};
# $pagination = { page => 1, limit => 50, total => 500, totalPages => 10, hasNextPage => 1 }

# Or fetch all pages automatically
my $all_items = $api->items_all;
```

## Caching

Responses are cached by default to reduce API load:

```perl
# Disable caching
my $api = WWW::MetaForge::ArcRaiders->new(use_cache => 0);

# Custom cache directory
my $api = WWW::MetaForge::ArcRaiders->new(cache_dir => '/tmp/metaforge');

# Clear cache
$api->clear_cache('items');  # specific endpoint
$api->clear_cache;           # all
```

Cache location defaults to:
- Linux/Mac: `~/.cache/www-metaforge/`
- Windows: `%LOCALAPPDATA%/www-metaforge/`

**Note:** `event_timers()` always fetches fresh data (time-critical). Use `event_timers_cached()` if you want cached data.

## Raw API Access

For custom processing, get raw HashRef/ArrayRef responses:

```perl
my $raw = $api->items_raw(search => 'Ferro');
# Returns the API response as-is
```

## Async Integration

For use with async frameworks (Mojo, AnyEvent, etc.), get HTTP::Request objects:

```perl
my $request = $api->request->items(search => 'Ferro');
# $request is HTTP::Request, use with your async UA
```

## Available Maps

```perl
my @maps = WWW::MetaForge::ArcRaiders->maps;
# ('dam', 'spaceport', 'buried-city', 'blue-gate', 'stella-montis')

my $display = $api->map_display_name('buried-city');
# 'Buried City'
```

## Debug Mode

```perl
my $api = WWW::MetaForge::ArcRaiders->new(debug => 1);
# Or set environment variable:
# WWW_METAFORGE_ARCRAIDERS_DEBUG=1
```

## Result Classes

All API methods return typed result objects:

| Method | Returns |
|--------|---------|
| `items` | `WWW::MetaForge::ArcRaiders::Result::Item` |
| `arcs` | `WWW::MetaForge::ArcRaiders::Result::Arc` |
| `quests` | `WWW::MetaForge::ArcRaiders::Result::Quest` |
| `traders` | `WWW::MetaForge::ArcRaiders::Result::Trader` |
| `event_timers` | `WWW::MetaForge::ArcRaiders::Result::EventTimer` |
| `map_data` | `WWW::MetaForge::ArcRaiders::Result::MapMarker` |

Each result object provides typed accessors and the original data via `->_raw`.

## Attribution

This module uses the MetaForge API: https://metaforge.app

## Support

- **Repository:** https://github.com/Getty/p5-www-metaforge
- **Issues:** https://github.com/Getty/p5-www-metaforge/issues
- **Discord:** https://discord.gg/Y2avVYpquV
- **IRC:** irc://irc.perl.org/ai

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
