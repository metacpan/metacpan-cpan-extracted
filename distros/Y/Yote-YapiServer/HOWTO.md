# HOWTO: Building Apps with yapi-server

Definition files define both the front-end and back-end of a yote application. Spiderpup pages (`.pup` or `.yaml`) compile into HTML and JavaScript. Yapi definitions (`.ydef` or `.yaml`) compile into Perl modules -- persistent model classes backed by a database, with client-callable methods, access control, and automatic serialization. Together, a set of definition files becomes a full web application.

The `.ydef` format is a brace-delimited DSL designed for defining apps, objects, and servers. It's more natural than YAML for embedding Perl code. The `.pup` format is a single-file component format (SFC) using `<script>`, `<style>`, and `<template>` blocks. Both YAML equivalents remain supported.

## 1. Setting Up a Project

```bash
perl yapi.pl init myproject
cd myproject
```

This creates the standard layout:

- `config/yapi.yaml` — database and server configuration
- `data/` — SQLite database files
- `webroot/js/` — `spiderpup.js` and `yapi-provider.js`
- `spiderpup/pages/` — page definitions (`.pup` or `.yaml`, compiled to HTML/JS)
- `spiderpup/recipes/` — reusable components (`.pup` or `.yaml`)
- `yapi/site.ydef` — server definition (`.ydef` or `.yaml`)
- `yapi/apps/` — app definitions (`.ydef` or `.yaml`, compiled to Perl)
- `yapi/modules/` — object definitions (`.ydef` or `.yaml`, compiled to Perl)
- `lib/` — compiled Perl modules

## 2. Configuration

`config/yapi.yaml` configures the database and upload limits:

```yaml
db:
  type: SQLite            # SQLite or MariaDB
  data_dir: data          # SQLite: directory for database files

  # MariaDB settings (used when type is MariaDB):
  # dbname: myproject
  # username: dbuser
  # password: dbpass

# max_file_size: 5000000  # Maximum upload size in bytes (default: 5MB)
# webroot_dir: www/webroot  # Where uploaded files are stored
```

## 3. Starting the Server

```bash
perl yapi.pl
```

This starts both the API server (port 5001) and the page server (port 5000). Override with flags:

```bash
perl yapi.pl --port 3000 --www-port 4000 --config path/to/yapi.yaml
```

On first run, the server initializes the database and creates tables for all registered app classes.

## 4. Creating an App

A definition file defines persistent model classes with client-callable methods. Here's a complete todo-list app in both formats.

### YAML format

```yaml
# yapi/apps/todo.yaml
type: app
package: Yote::YapiServer::App::Todo

public_vars:
  appName: Todo List
  appVersion: 1.0.0

cols:
  items: '*ARRAY_*::Item'

field_access:
  items:
    auth: 1

methods_public:
  listItems: |
    my ($self, $args, $session) = @_;
    return 1, $self->get_items // [];

methods_auth:
  addItem:
    code: |
      my ($self, $args, $session) = @_;
      my $user = $session->get_user;

      my $text = $args->{text};
      return 0, "text required" unless $text;

      my $item = $self->store->new_obj(
          'Yote::YapiServer::App::Todo::Item',
          text  => $text,
          owner => $user,
      );

      push @{$self->get_items}, $item;
      return 1, $item;

methods:
  removeItem:
    access:
      auth: 1
      owner_only: 1
    code: |
      my ($self, $args, $session) = @_;
      my $item = $args->{item};
      my $items = $self->get_items;
      @$items = grep { $_->id ne $item->id } @$items;
      return 1, { removed => 1 };

objects:
  Item:
    cols:
      text: VARCHAR(500)
      owner: '*Yote::YapiServer::User'
      done: BOOLEAN DEFAULT 0
      created: TIMESTAMP DEFAULT CURRENT_TIMESTAMP

    field_access:
      text: public
      owner: public
      done: public
      created: public
```

### .ydef format

The same app in `.ydef` format -- a brace-delimited DSL that's more natural for embedding Perl code:

```
# yapi/apps/todo.ydef
app Yote::YapiServer::App::Todo {

    values {
        appName     Todo List
        appVersion  1.0.0
    }

    cols {
        items   *ARRAY_*::Item
    }

    field_access {
        items   auth
    }

    method public listItems {
        my ($self, $args, $session) = @_;
        return 1, $self->get_items // [];
    }

    method auth addItem {
        my ($self, $args, $session) = @_;
        my $user = $session->get_user;

        my $text = $args->{text};
        return 0, "text required" unless $text;

        my $item = $self->store->new_obj(
            'Yote::YapiServer::App::Todo::Item',
            text  => $text,
            owner => $user,
        );

        push @{$self->get_items}, $item;
        return 1, $item;
    }

    method auth,owner_only removeItem {
        my ($self, $args, $session) = @_;
        my $item = $args->{item};
        my $items = $self->get_items;
        @$items = grep { $_->id ne $item->id } @$items;
        return 1, { removed => 1 };
    }

    object Item {
        cols {
            text     VARCHAR(500)
            owner    *Yote::YapiServer::User
            done     BOOLEAN DEFAULT 0
            created  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        }

        field_access {
            text     public
            owner    public
            done     public
            created  public
        }
    }
}
```

Both formats compile to the same Perl module with two classes: `Todo` (the app) and `Todo::Item` (a nested model). Both are persistent -- backed by auto-generated database tables -- and serialize themselves to clients according to their `field_access` rules.

### YAML Reference

| Key | Description |
|-----|-------------|
| `type` | `app`, `object`, or `server` |
| `package` | Full Perl package name for the generated class |
| `base` | Base class (default: `Yote::YapiServer::App::Base` for apps, `Yote::YapiServer::BaseObj` for objects) |
| `uses` | List of extra Perl modules to `use` |
| `public_vars` | Key-value pairs sent to the client on `connect` |
| `vars` | Package-level `our` scalar variables |
| `cols` | Database column definitions (merged with base for apps) |
| `field_access` | Field visibility rules for client serialization |
| `methods` | Client-callable methods with access level, `files` flag, and code |
| `methods_public` | Shorthand for methods with `access: public` |
| `methods_auth` | Shorthand for methods with `access: auth` |
| `subs` | Internal utility methods (not exposed to clients) |
| `objects` | Nested model definitions (compiled as sub-packages) |

### .ydef Reference

| Block | Description |
|-------|-------------|
| `app Pkg { }` | App definition (equivalent to `type: app`) |
| `object Name { }` | Nested object (inside an app) or standalone object |
| `server Pkg { }` | Server definition (equivalent to `type: server`) |
| `cols { k type }` | Database columns |
| `field_access { k level }` | Field visibility rules |
| `values { k val }` | Public vars sent to client on connect |
| `vars { k val }` | Package-level `our` scalar variables |
| `uses { Mod }` | Extra Perl modules to `use` |
| `method ACCESS name { code }` | Client-callable method with access level(s) |
| `sub name { code }` | Internal utility method (not exposed to clients) |
| `base Pkg` | Base class (server definitions only) |
| `apps { name Pkg }` | App registry (server definitions only) |

Access levels in `method` are comma-separated: `method auth,owner_only removeItem { ... }`.

### Column Types

Columns use Yote::SQLObjectStore type syntax:

```yaml
cols:
  name: VARCHAR(125)                          # simple scalar
  count: INTEGER DEFAULT 0                     # integer with default
  items: '*ARRAY_*::Item'                     # array of objects (relative ref)
  owner: '*Yote::YapiServer::User'             # reference to object (absolute)
  settings: '*HASH<64>_TEXT'                   # hash of key => text
```

The `*::` prefix is shorthand for the current app's package. In a `Yote::YapiServer::App::Todo` app, `*::Item` expands to `*Yote::YapiServer::App::Todo::Item`.

### Access Levels

```yaml
methods:
  getStats:
    access: public          # no auth required

  postMessage:
    access: auth            # logged-in users only

  clearAll:
    access: admin_only      # admins only

  deleteItem:
    access:                 # compound access
      auth: 1
      owner_only: 1         # caller must own the target object
```

### Method Shorthand Keys

Group methods by access level using `methods_public` and `methods_auth` instead of repeating `access:` on each:

```yaml
methods_public:
  hello:
    code: |
      my ($self, $args, $session) = @_;
      return 1, "Hello!";

  # Bare string shorthand (value is the code body directly)
  getStats: |
    my ($self, $args, $session) = @_;
    return 1, { version => $PUBLIC_VARS{appVersion} };

methods_auth:
  postMessage:
    code: |
      my ($self, $args, $session) = @_;
      return 0, "text required" unless $args->{text};
      return 1, $args->{text};

methods:
  clearAll:
    access: admin_only
    code: |
      my ($self, $args, $session) = @_;
      return 1, { cleared => 1 };
```

All three keys can be used together. `methods_public` implies `access: public`, `methods_auth` implies `access: auth`.

### Field Access (shorthand and hash forms)

```yaml
# Shorthand (single keyword)
field_access:
  title: public
  email: owner_only
  password: never
  status: admin_only

# Hash form (for compound rules)
field_access:
  messages:
    auth: 1
```

### Method Signature

Every method receives the same arguments and must return a two-value list -- `1, $result` for success or `0, $error_message` for failure:

```yaml
code: |
  my ($self, $args, $session) = @_;
  # $self    - the app or object instance (persistent)
  # $args    - hashref of arguments from the client
  # $session - current Session (undef for public methods without a token)

  my $user = $session->get_user;  # logged-in user
  return 0, "name required" unless $args->{name};
  return 1, "Hello, $args->{name}!";
```

On success, the result is serialized and sent as `resp`. On failure, the error string is sent as `{ ok: 0, error: "..." }`.

### Nested Objects

Define related models in `objects:`. They are compiled as sub-packages of the app, each with their own database table:

```yaml
objects:
  Item:
    cols:
      owner: '*Yote::YapiServer::User'
      text: VARCHAR(500)

    field_access:
      owner: public
      text: public
```

The `BaseObj` superclass provides a default `to_client_hash` that serializes fields according to `field_access` rules. Override it in `subs:` for custom behavior.

### Ownership

Apps are their own owners (`get_owner` returns `$self`). Nested objects should include an `owner` column for authorization -- AUTOLOAD provides `get_owner()` automatically:

```yaml
objects:
  Item:
    cols:
      owner: '*Yote::YapiServer::User'
      text: VARCHAR(500)
```

The `owner_only` access level uses `get_owner()` to check if the calling user owns the object.

## 5. Compiling

```bash
# Compile a single definition file to a Perl module
perl yapi.pl compile yapi/apps/todo.ydef lib/
perl yapi.pl compile yapi/apps/todo.yaml lib/  # YAML also works

# Compile an entire directory (finds .ydef and .yaml files)
perl yapi.pl compile yapi/ lib/
```

This generates `.pm` files matching the package path. For the todo example, it produces `lib/Yote/YapiServer/App/Todo.pm` containing both the `Todo` app class and the nested `Todo::Item` model.

Spiderpup pages are compiled separately:

```bash
# Compile all pages to HTML/JS
perl yapi.pl pages

# Watch for changes and recompile automatically
perl yapi.pl pages --watch
```

## 6. Registering Your App

### Server Definition

Create a server definition to register your apps.

**`.ydef` format:**

```
# yapi/site.ydef
server MyProject::Site {
    base Yote::YapiServer::Site

    uses {
        Yote::YapiServer::App::Todo
    }

    apps {
        todo    Yote::YapiServer::App::Todo
    }
}
```

**YAML format:**

```yaml
# yapi/site.yaml
type: server
package: MyProject::Site
base: Yote::YapiServer::Site

uses:
  - Yote::YapiServer::App::Todo

apps:
  todo: Yote::YapiServer::App::Todo
```

The server definition inherits the base Site's `%INSTALLED_APPS`, so built-in apps remain available alongside your new ones.

### Direct Registration (no definition file)

Add your app directly to `%INSTALLED_APPS` in `lib/Yote/YapiServer/Site.pm`:

```perl
our %INSTALLED_APPS = (
    example => 'Yote::YapiServer::App::Example',
    todo    => 'Yote::YapiServer::App::Todo',
);
```

## 7. App Versioning

Apps are versioned. Each app class has a class-level version number, and the server stores multiple versions of the same app side by side.

### Setting the Version

Override the `$app_version` package variable in your app class:

```perl
package Yote::YapiServer::App::Todo;
use base 'Yote::YapiServer::App::Base';

our $app_version = 2;  # default is 1
```

In definition files, use the `vars` key:

```
# .ydef
vars {
    app_version  2
}
```

```yaml
# .yaml
vars:
  app_version: 2
```

### How It Works

The Site stores apps as a nested hash: `app_name => { version => app_object }`. When the server starts, `init()` checks each installed app's version. If that version doesn't exist yet, a new app object is created alongside any existing versions.

When a client connects to an app, the latest (highest) version is used by default. A specific version can be requested:

```perl
my $app = $site->get_app('todo');      # latest version
my $app = $site->get_app('todo', 1);   # specific version
```

This means you can deploy a new version of an app while the old version's data remains accessible.

## 8. Client-Side Usage

Include `yapi-provider.js` in your page and use the `AppProvider` class.

### Connecting to an App

```javascript
const provider = new AppProvider('/yapi');
const app = await provider.connect('todo');

// Public vars from the definition are available as properties
console.log(app.appName);     // "Todo List"
console.log(app.appVersion);  // "1.0.0"
```

`connect()` returns a proxy object with method stubs for all methods the current user is allowed to call. Reconnect after login to get authenticated method stubs.

### Calling Methods

```javascript
// Public method -- works without login
const items = await app.listItems();

// Authenticated method -- requires login first
const newItem = await app.addItem({ text: 'Buy groceries' });
```

Arguments are automatically encoded with v/r/f prefixes before sending (see Argument Encoding below). You pass plain JavaScript values.

### Working with Returned Objects

Returned objects have `_objId`, `_class`, data fields, and method stubs:

```javascript
const item = await app.addItem({ text: 'Buy groceries' });

console.log(item._objId);   // "_obj_42"
console.log(item._class);   // "Item"
console.log(item.text);     // "Buy groceries"

// Call a method on the returned object
await item._call('toggleDone');
```

When passing objects as arguments, just pass the object directly -- the provider encodes the reference automatically:

```javascript
await app.removeItem({ item: item });
```

### Argument Encoding

Method call arguments use v/r/f prefixes to distinguish value types. The `AppProvider` handles this automatically:

- **Scalars** get a `v` prefix: `"Hello"` becomes `"vHello"`, `42` becomes `"v42"`
- **Object references** get an `r` prefix: an object with `_objId: "_obj_42"` becomes `"r_obj_42"`
- **Files** get an `f` prefix: encoded via `provider.fileArg()` (see below)
- **Arrays and objects** are containers -- their leaf values are recursively encoded

This mirrors the response format where `v` marks values and `r` marks object references.

### File Uploads

Methods that accept file uploads must declare `files: true` in the method definition:

```yaml
methods_auth:
  uploadAvatar:
    files: true
    code: |
      my ($self, $args, $session) = @_;
      my $file = $args->{avatar};
      # $file is a Yote::YapiServer::File object
      return 1, $file;  # sends url, type, size to client
```

On the client side, use `provider.fileArg()` to prepare a File for upload:

```javascript
const fileInput = document.querySelector('input[type="file"]');
const encoded = await provider.fileArg(fileInput.files[0]);
await app.uploadAvatar({ avatar: encoded });
```

Files are stored content-addressed (SHA-256 hash as filename) under `webroot/img/`. The server creates a `File` object with public fields `url`, `type`, `size` and private fields `original_name`, `file_path`.

Configure the maximum file size in `config/yapi.yaml`:

```yaml
max_file_size: 5000000    # 5MB (default)
```

Supported MIME types: `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml`, `application/pdf`, `text/plain`, `text/csv`, `application/json`.

## 9. Authentication

### Creating an Account

```javascript
const result = await provider.createUser({
    handle: 'alice',
    email: 'alice@example.com',
    password: 'secret123'
});

if (result.ok) {
    // Auto-logged in after registration
    console.log(provider.getUser().handle);  // "alice"
}
```

### Logging In

```javascript
const result = await provider.login({
    handle: 'alice',
    password: 'secret123'
});

if (result.ok) {
    // Token stored in localStorage automatically
    // Reconnect to get authenticated method stubs
    const app = await provider.connect('todo');
}
```

### Checking Login State

```javascript
if (provider.isLoggedIn()) {
    const user = provider.getUser();
    console.log(user.handle);
}
```

### Logging Out

```javascript
await provider.logout();
// Token cleared, object cache cleared
```

The token persists in `localStorage` across page reloads. On page load, if a token exists, include it with your connect call and the server will restore the session.

## 10. Custom Serialization

The `BaseObj` superclass provides a default `to_client_hash` that filters fields by `field_access` rules. Override it in `subs:` to control what data the client receives:

```yaml
objects:
  Story:
    cols:
      owner: '*Yote::YapiServer::User'
      sections: '*ARRAY_*::Section'
      completed: BOOLEAN DEFAULT 0

    subs:
      to_client_hash: |
        my ($self, $session, $viewer) = @_;

        my %result = (
            completed => $self->get_completed ? 1 : 0,
            owner     => $self->get_owner,
        );

        # Only show full content if the story is finished
        if ($self->get_completed) {
            $result{sections} = $self->get_sections;
        } else {
            my $last = $self->get_sections->[-1];
            $result{hint} = substr($last->get_text, -200);
        }

        return \%result;
```

Return **only data fields** -- no `_objId`, `_class`, or `expose_object`. The Handler handles all metadata and session tracking. Objects returned as values (like `owner` above) are automatically serialized into the flat `objects` map and replaced with `r_obj_ID` references.

## 11. Package Variables

Use `vars` for package-level constants that methods can reference:

```yaml
vars:
  SECTIONS_TO_COMPLETE: 5
  VISIBLE_CHARS: 200

methods:
  startStory:
    access: auth
    code: |
      my ($self, $args, $session) = @_;
      ...
      my $story = $self->store->new_obj(
          'MyApp::Story',
          sections_needed => $SECTIONS_TO_COMPLETE,
      );
```

These compile to `our $SECTIONS_TO_COMPLETE = 5;` etc. at the package level.

## 12. Walkthrough: The Example App

The built-in example app (`yaml/example.yaml` or `yaml/example.ydef`) is a simple message board.

**Compile and start:**
```bash
perl yapi.pl compile yaml/ lib/
perl yapi.pl
```

**Use from JavaScript:**
```javascript
const provider = new AppProvider('/yapi');
const app = await provider.connect('example');

// Public methods -- no login needed
const greeting = await app.hello({ name: 'World' });
// => "Hello, World!"

const stats = await app.getStats();
// => { messageCount: 5, appVersion: "1.0.0" }

// Login, then use authenticated methods
await provider.login({ handle: 'alice', password: 'secret123' });

const msg = await app.postMessage({ text: 'Hello everyone!' });
// => { _objId: "_obj_42", _class: "Message", text: "Hello everyone!", ... }

const { messages, total } = await app.getMessages({ limit: 10, offset: 0 });

// Admin-only
await app.clearMessages();
```

See `yaml/example.yaml` for the full YAML source and `yaml/corpse.ydef` for a more complex example in `.ydef` format with multiple object types, custom serialization, and package variables.
