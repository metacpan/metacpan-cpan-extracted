# WWW::ARDB

Perl client library for the [ardb.app](https://ardb.app) ARC Raiders Database API.

Provides access to:
- Items (weapons, materials, consumables, etc.)
- Quests
- ARC Enemies with drop tables

## Installation

```bash
cpanm WWW::ARDB
```

Or from source:

```bash
git clone https://github.com/Getty/p5-www-ardb.git
cd p5-www-ardb
cpanm --installdeps .
```

## Command-Line Interface

The distribution includes `ardb` for quick lookups:

```bash
# List items
ardb items
ardb items --search guitar
ardb items --rarity legendary
ardb items --type weapon

# Show item details
ardb item acoustic_guitar

# List quests
ardb quests
ardb quests --trader shani

# Show quest details
ardb quest picking_up_the_pieces

# List ARC enemies
ardb enemies

# Show enemy details with drop table
ardb enemy wasp
```

### Global Options

```bash
--json, -j   # Output as JSON
--no-cache   # Skip cache, fetch fresh data
--debug, -d  # Show debug output
```

## API Usage

```perl
use WWW::ARDB;

my $api = WWW::ARDB->new;

# Items
my $items = $api->items;
for my $item (@$items) {
    printf "%s (%s) - %s\n",
        $item->name,
        $item->rarity // 'n/a',
        $item->type;
}

# Single item with full details
my $item = $api->item('acoustic_guitar');
say $item->description;
say "Weight: " . $item->weight;
say "Breakdown: " . join(", ", map { $_->{name} } @{$item->breakdown});

# Quests
my $quests = $api->quests;
for my $quest (@$quests) {
    say $quest->title . " from " . $quest->trader_name;
}

# Single quest with rewards
my $quest = $api->quest('picking_up_the_pieces');
say "Objectives:";
for my $step (@{$quest->steps}) {
    say "  - $step->{title} (x$step->{amount})";
}

# ARC Enemies
my $enemies = $api->arc_enemies;
for my $enemy (@$enemies) {
    say $enemy->name;
}

# Single enemy with drop table
my $enemy = $api->arc_enemy('wasp');
say "Drops:";
for my $drop (@{$enemy->drop_table}) {
    say "  - $drop->{name} ($drop->{rarity})";
}
```

## Search Methods

Find items by name (case-insensitive):

```perl
my $item = $api->find_item_by_name('Acoustic Guitar');
my $quest = $api->find_quest_by_title('Picking Up The Pieces');
my $enemy = $api->find_arc_enemy_by_name('Wasp');
```

## Caching

Responses are cached by default to reduce API load:

```perl
# Disable caching
my $api = WWW::ARDB->new(use_cache => 0);

# Custom cache directory
my $api = WWW::ARDB->new(cache_dir => '/tmp/ardb');

# Clear cache
$api->clear_cache('items');  # specific endpoint
$api->clear_cache;           # all
```

Cache location defaults to:
- Linux/Mac: `~/.cache/ardb/`
- Windows: `%LOCALAPPDATA%/ardb/`

## Raw API Access

For custom processing, get raw HashRef/ArrayRef responses:

```perl
my $raw = $api->items_raw;
my $raw = $api->item_raw('acoustic_guitar');
my $raw = $api->quests_raw;
my $raw = $api->quest_raw('picking_up_the_pieces');
my $raw = $api->arc_enemies_raw;
my $raw = $api->arc_enemy_raw('wasp');
```

## Async Integration

For use with async frameworks (Mojo, AnyEvent, etc.), get HTTP::Request objects:

```perl
my $request = $api->request->items;
my $request = $api->request->item('acoustic_guitar');
# $request is HTTP::Request, use with your async UA
```

## Debug Mode

```perl
my $api = WWW::ARDB->new(debug => 1);
# Or set environment variable:
# WWW_ARDB_DEBUG=1
```

## Result Classes

All API methods return typed result objects:

| Method | Returns |
|--------|---------|
| `items` | `WWW::ARDB::Result::Item` |
| `item` | `WWW::ARDB::Result::Item` |
| `quests` | `WWW::ARDB::Result::Quest` |
| `quest` | `WWW::ARDB::Result::Quest` |
| `arc_enemies` | `WWW::ARDB::Result::ArcEnemy` |
| `arc_enemy` | `WWW::ARDB::Result::ArcEnemy` |

Each result object provides typed accessors and the original data via `->_raw`.

## Attribution

This module uses the ardb.app API. Per the API documentation, applications using this data must include a disclaimer crediting ardb.app with a link back to the source.

**Data provided by [ardb.app](https://ardb.app)**

## Support

- **Repository:** https://github.com/Getty/p5-www-ardb
- **Issues:** https://github.com/Getty/p5-www-ardb/issues

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
