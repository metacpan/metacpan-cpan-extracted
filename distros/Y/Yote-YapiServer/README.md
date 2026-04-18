# yapi-server

Yote API Server -- a JSON RPC server that lets JavaScript clients call methods on persistent Perl objects. Built on top of Yote::SQLObjectStore for automatic object persistence and SQLite storage.

## Key Features

- **Object-oriented RPC**: Call methods on server-side Perl objects directly from the browser
- **Automatic proxy generation**: Client receives method stubs on connect, no manual mirroring needed
- **Capability-based security**: Clients can only access objects the server has explicitly exposed to their session
- **Method and field authorization**: Declarative access control at both the method and field level
- **Persistent object store**: Uses Yote::SQLObjectStore (SQLite backend) for automatic object persistence
- **Rate limiting**: Configurable per-IP and per-session rate limits

## Architecture

```
Browser                              Server
───────                              ──────
AppProvider                          yapi.pl
  ├─ connect(appName) ────POST───►     └─ Yote::YapiServer
  ├─ login/logout                         └─ Handler.pm
  └─ callMethod(target, method)              ├─ validate token → Session
     │                                       ├─ authorize method
     │                                       ├─ call target.$method()
     ▼                                       └─ serialize result
  App proxy object
    ├─ publicVars                     Site.pm (root DB object)
    └─ method stubs                     ├─ versioned app registry
                                        ├─ user management
                                        └─ session/token validation
```

The server uses a fork-per-connection model. Each incoming HTTP connection is handled by a forked child process with its own SQLite connection.

## Directory Structure

```
yapi.pl                     Entry point (API + page server, compile, pages)
lib/
  Yote/YapiServer.pm        HTTP server (socket, fork, HTTP parsing)
  Yote/YapiServer/
    Site.pm                  Root DB object, versioned app registry, user management
    Handler.pm               JSON request dispatch, auth, serialization
    Session.pm               Token management, object capability tracking
    User.pm                  User model with field visibility
    Compiler.pm              Compiles .yaml and .ydef files to Perl modules
    YapiDef.pm               Parser for .ydef definition format
    App/
      Base.pm                Base class for all apps
      Example.pm             Example message board app
bin/                         (empty — compile via yapi.pl compile)
yaml/                        App definitions (.yaml or .ydef format)
www/webroot/js/
  yapi-provider.js           Client-side AppProvider class
t/server/                    Tests
```

## Dependencies

- Yote::SQLObjectStore
- JSON::PP
- Digest::MD5
- IO::Socket::INET
- Time::Piece / Time::HiRes

## Request/Response Protocol

All communication is via `POST` to the server endpoint (default: `/yapi`).

### Request

```json
{
  "action": "connect | call | login | createUser | logout",
  "token": "session_token",
  "app": "appName",
  "target": "appName | _obj_123",
  "method": "methodName",
  "args": { ... }
}
```

### Response (success)

```json
{
  "ok": 1,
  "token": "session_token",
  "resp": "r_obj_42",
  "classes": { "ClassName": ["method1", "method2"] },
  "objects": {
    "_obj_42": { "_class": "ClassName", "data": { "name": "vAlice", "score": "v98" } }
  },
  "apps": { "_app_example": ["hello", "getStats"] }
}
```

- `token` — always present when there's a session (even anonymous)
- `resp` — return value with v/r prefix encoding (see below)
- `objects` — flat map of all objects encountered during serialization (deduplicated)
- `classes` — map of class name to callable methods (once per class)
- `apps` — map of `_app_<name>` to callable methods (connect only)

### Value encoding (v/r prefixes)

All scalar values in `resp` and within `objects.data` use a single-character prefix to distinguish literal strings from object references:

| Prefix | Meaning | Example |
|--------|---------|---------|
| `v` | Literal value (string, number) | `"vHello"` → `"Hello"` |
| `r` | Reference to an object or app | `"r_obj_42"` → look up `_obj_42` in `objects` |

Arrays and plain hashes are returned as-is, with v/r encoding applied to their leaf values. The client-side `AppProvider` strips prefixes automatically.

### Response (error)

```json
{
  "ok": 0,
  "error": "message"
}
```

## Authorization Model

### Method-Level Access (`%METHODS`)

Each app declares which methods are callable and who can call them:

| Level | Meaning |
|-------|---------|
| `public` | No authentication required |
| `auth` | Requires a valid session |
| `owner_only` | Caller must own the target object |
| `admin_only` | Caller must be an admin |

### Field-Level Access (`%FIELD_ACCESS`)

Controls what fields are included when serializing objects to the client:

| Level | Meaning |
|-------|---------|
| `public` | Visible to everyone |
| `owner_only` | Visible only to the object's owner (and admins) |
| `admin_only` | Visible only to admins |
| `never` | Never sent to the client (e.g., passwords) |

### Object Capability Model

The session tracks which objects have been exposed to the client. When Handler's `serialize_value()` encounters an object, it calls `$session->expose_object($obj)`. Subsequent client requests referencing that object's `_obj_ID` are validated against the session's exposed set. This prevents clients from accessing arbitrary objects by guessing IDs.

## Rate Limiting

Configured in `Yote::YapiServer::Site`:

```perl
our %RATE_LIMITS = (
    createUser => { per_ip => 5,  window => 3600 },   # 5 per hour
    login      => { per_ip => 10, window => 300 },     # 10 per 5 min
    default    => { per_session => 100, window => 60 }, # 100 per min
);
```

Rate limits are enforced in-memory by Handler.pm and reset on server restart.

## Quick Start

```bash
# Scaffold a new project
perl yapi.pl init myproject

# Start both API and page servers (default ports 5001 and 5000)
perl yapi.pl

# Or with custom settings
perl yapi.pl --port 3000 --data-dir /tmp/mydata --www-port 4000
```

### `yapi.pl init [directory]`

Creates a project skeleton with all the standard directories and starter files:

```
myproject/
├── config/
│   └── yapi.yaml           # Database and server configuration
├── data/                   # SQLite database files (created on first run)
├── webroot/                # Web server root (compiled output + static files)
│   └── js/
│       ├── spiderpup.js    # Client-side runtime (copied)
│       └── yapi-provider.js # API client (copied)
├── lib/                    # Compiled Perl modules
├── spiderpup/
│   ├── pages/              # Page definitions (.yaml or .pup)
│   │   └── index.pup       # Starter page
│   └── recipes/            # Reusable components (.yaml or .pup)
└── yapi/
    ├── site.ydef           # Server definition (.yaml or .ydef)
    ├── apps/               # App definitions (.yaml or .ydef)
    └── modules/            # Object definitions (.yaml or .ydef)
```

Safe to re-run — skips existing directories and definition files, always refreshes JS files.

See [HOWTO.md](HOWTO.md) for a step-by-step guide to building apps.
