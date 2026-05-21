---
name: perl-mailbox-org-api
description: "WWW::MailboxOrg API patterns, JSON-RPC methods, session auth, entity objects, CLI tool mborg"
user-invocable: true
allowed-tools: Read, Grep, Bash
model: sonnet
---

When working with WWW::MailboxOrg:

## Architektur

```
WWW::MailboxOrg (Main Client)
├── Role::HTTP (JSON-RPC calls über session)
│   └── Role::IO (pluggable backend → LWPIO mit Mojo::UserAgent)
├── API::* (singleton controller: mail, domain, account, etc.)
└── Entity::* (Account, Domain)
```

## JSON-RPC Protocol

Mailbox.org nutzt JSON-RPC 2.0:
- Methodennamen statt REST-Pfade: `account.get`, `mail.find`
- Session-Auth via HPLS-AUTH header (nicht Bearer token)
- Benannte Parameter

## Auth Environment Variables

```bash
MAILBOX_API_KEY    # API Key
MAILBOX_LOGIN     # Login
MAILBOX_PASSWORD  # Passwort
```

## API Controller (alle mit MooX::Singleton)

| Controller | Wichtige Methoden |
|------------|-------------------|
| API::Mail | `find(query)`, `list(folder, unseen_only)` |
| API::Account | `add`, `del`, `get`, `list`, `set` |
| API::Domain | `add`, `del`, `get`, `list`, `set` |
| API::Mailinglist | `add`, `del`, `get`, `list`, `set`, `add_member`, `del_member`, `list_members` |
| API::Blacklist | `add`, `del`, `list` |
| API::Spamprotect | `status`, `set` |
| API::Videochat | `status`, `create_room`, `list_rooms`, `delete_room` |
| API::Backup | `list`, `create`, `restore`, `delete` |
| API::Invoice | `list`, `get`, `download` |
| API::System | `hello`, `test`, `capabilities`, `context` |
| API::Passwordreset | `request`, `set` |
| API::Validate | `email` |
| API::Utils | `parse_headers`, `parse_date`, `generate_message_id` |

## CLI Tool: mborg

```bash
mborg mail find 'from:user@example.com'
mborg mail list --folder INBOX --unseen-only
mborg account list
mborg domain list
```

Config Datei: `~/.config/mborg.conf` oder `mborg.conf` im cwd.

## Wichtige Dateien

- `lib/WWW/MailboxOrg.pm` — Haupt-Client
- `lib/WWW/MailboxOrg/Role/HTTP.pm` — JSON-RPC Role
- `lib/WWW/MailboxOrg/Role/IO.pm` — IO Interface
- `lib/WWW/MailboxOrg/LWPIO.pm` — Mojo::UserAgent Backend
- `lib/WWW/MailboxOrg/API/*.pm` — Alle API Controller
- `lib/WWW/MailboxOrg/Entity/*.pm` — Entity Objekte
- `bin/mborg` — CLI Tool

## POD Conventions

- `=method method_name` für Methoden (→ =head2 method_name)
- `=attr attr_name` für Attribute (→ =head2 attr_name)
- `=type TypeName` für Types (→ =head2 TypeName)
- `=head1 SEE ALSO` für Verweise auf verwandte Module
- KEINE manuellen NAME/VERSION/AUTHOR/COPYRIGHT Sektionen (auto-generiert)

## Build & Test

```bash
dzil build        # Distribution bauen
dzil test         # Tests ausführen
prove -l t/       # Direkt mit prove
```