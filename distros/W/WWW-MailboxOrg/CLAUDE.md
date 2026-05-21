# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

WWW::MailboxOrg — Perl Client für die Mailbox.org API.

## Architektur

Siehe Plan in `/storage/raid/home/getty/.claude/plans/hazy-baking-lighthouse.md`.

```
WWW::MailboxOrg (Main Client)
├── Role::HTTP (JSON-RPC calls)
│   └── Role::IO (pluggable backend)
│       └── LWPIO (Mojo::UserAgent sync backend)
├── API::* (singleton controller: mail, domain, account, etc.)
└── Entity::* (Account, Domain)
```

## Wichtige Referenzen

- API-Dokumentation: https://api.mailbox.org/铺
- Architektur-Vorbild: WWW::Hetzner

## Wichtige Dateien

- `lib/WWW/MailboxOrg.pm` — Haupt-Client
- `lib/WWW/MailboxOrg/API/*.pm` — API Controller
- `lib/WWW/MailboxOrg/Entity/*.pm` — Entity Objekte
- `bin/mborg` — CLI Tool

## Build & Test

```bash
dzil build        # Distribution bauen
dzil test         # Tests ausführen
prove -l t/       # Direkt mit prove
```

## Authentifizierung

Session-basiert mit HPLS-AUTH Header. Credentials über Environment:
- `MAILBOX_API_KEY` — API Key
- `MAILBOX_LOGIN` — Login
- `MAILBOX_PASSWORD` — Passwort

## POD Dokumentation

### Inline Commands (werden zu =head2)

- `=attr name` → `=head2 name`
- `=method method_name` → `=head2 method_name`
- `=func func_name` → `=head2 func_name`
- `=opt` - CLI options
- `=env` - Environment variables
- `=hook` - Hooks
- `=example` - Examples

PODWeaver generiert NAME, VERSION, etc. automatisch.