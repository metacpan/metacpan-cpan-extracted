# CLAUDE.md

## Project Overview

Perl client library for [MetaForge.app](https://metaforge.app) game data API.

## Modules

- **WWW::MetaForge::ArcRaiders** - ARC Raiders game API (items, quests, arcs, traders, events)
- **WWW::MetaForge::GameMapData** - Generic map marker API (separate from ArcRaiders)

## Key API Endpoints

```
ArcRaiders:     https://metaforge.app/api/arc-raiders/{items,quests,arcs,traders,event-timers}
GameMapData:    https://metaforge.app/api/game-map-data?tableID=arc_map_data&mapID={dam,spaceport,...}
```

## Testing

```bash
prove -l t/                    # Run with MockUA fixtures
USE_LIVE_API=1 prove -l t/     # Run against live API
```

Fixtures in `t/fixtures/` must match exact API response format.

## CLI

Binary: `bin/metaforge-arcraiders` (installed as `arcraiders`)

Commands use MooX::Cmd + MooX::Options in `lib/WWW/MetaForge/ArcRaiders/CLI/Cmd/`.

## Code Style

- Moo for OOP
- Result classes parse API responses via `from_hashref()`
- Request classes build HTTP::Request objects
- Support ONLY exact API format - no speculative fallbacks
