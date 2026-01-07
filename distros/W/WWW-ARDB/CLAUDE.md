# CLAUDE.md

## Project Overview

Perl client library for [ardb.app](https://ardb.app) ARC Raiders Database API.

## Modules

- **WWW::ARDB** - Main API client (items, quests, arc-enemies)
- **WWW::ARDB::CLI** - Command-line interface

## Key API Endpoints

```
https://ardb.app/api/items
https://ardb.app/api/items/{id}
https://ardb.app/api/quests
https://ardb.app/api/quests/{id}
https://ardb.app/api/arc-enemies
https://ardb.app/api/arc-enemies/{id}
```

## Testing

```bash
prove -l t/                    # Run with MockUA fixtures
USE_LIVE_API=1 prove -l t/     # Run against live API
```

Fixtures in `t/fixtures/` must match exact API response format.

## CLI

Binary: `bin/ardb`

Commands use MooX::Cmd + MooX::Options in `lib/WWW/ARDB/CLI/Cmd/`.

## Code Style

- Moo for OOP
- Result classes parse API responses via `from_hashref()`
- Request classes build HTTP::Request objects
- Support ONLY exact API format - no speculative fallbacks
