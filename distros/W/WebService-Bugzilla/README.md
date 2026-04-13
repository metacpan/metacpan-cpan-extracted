# WebService::Bugzilla

A Perl client for the Bugzilla REST API (v2).

## Overview

WebService::Bugzilla provides a modern, object-oriented Perl interface to Bugzilla's REST API. It supports all major operations: searching and retrieving bugs, creating and updating issues, managing comments, attachments, users, and more.

**Features:**
- Simple, intuitive API mirroring Bugzilla REST endpoints
- Automatic error handling with custom exception objects
- Support for all Bugzilla 5.0+ REST API endpoints
- Lazy-loaded service objects for efficiency
- Comprehensive POD documentation with examples
- Full test coverage (177 passing tests)

## Installation

```bash
cpanm WebService::Bugzilla
```

Or manually:

```bash
perl Makefile.PL
make test
make install
```

## Quick Start

```perl
use WebService::Bugzilla;

my $bz = WebService::Bugzilla->new(
    base_url => 'https://bugzilla.example.com',
    api_key  => 'your-api-key-here',
);

# Get a bug
my $bug = $bz->bug->get(123);
say 'Summary: ', $bug->summary;

# Search for bugs
my $bugs = $bz->bug->search(
    product => 'Firefox',
    status  => 'OPEN',
    limit   => 10,
);

    for my $b (@$bugs) {
    say $b->id, ': ', $b->summary;
}

# Create a bug
my $new = $bz->bug->create(
    product     => 'Firefox',
    component   => 'General',
    version     => '130.0',
    summary     => 'Bug title',
    description => 'Bug description',
);

# Update a bug
$bz->bug->update(456,
    status     => 'RESOLVED',
    resolution => 'FIXED',
);

# Get bug comments
my $comments = $bz->comment->get($bug->id);
    for my $comment (@$comments) {
    say $comment->creator->{name}, ': ', $comment->text;
}

# Create a comment
$bz->comment->create($bug->id,
    comment => 'This is my comment',
);
```

## Configuration

### Base URL

The `base_url` can be either a full domain or just the domain name. If you provide just the domain, `/bugzilla/rest/` is automatically appended:

```perl
# Both are equivalent:
my $bz1 = WebService::Bugzilla->new(
    base_url => 'https://bugzilla.example.com/bugzilla/rest/',
);

my $bz2 = WebService::Bugzilla->new(
    base_url => 'https://bugzilla.example.com',
);
```

### API Key

Get your API key from your Bugzilla user preferences. Then pass it when creating the client:

```perl
my $bz = WebService::Bugzilla->new(
    base_url => 'https://bugzilla.example.com',
    api_key  => 'abc123def456',
);
```

### CloudFlare Bot Protection

Some Bugzilla instances sit behind CloudFlare which blocks automated requests. To work around this, spoof browser headers:

```perl
my $bz = WebService::Bugzilla->new(
    base_url => 'https://bugzilla.example.com',
    api_key  => 'your-api-key',
);

# Spoof a real browser
$bz->ua->default_header('User-Agent' => 'curl/8.7.1');
$bz->ua->default_header('Accept' => '*/*');
$bz->ua->default_header('Accept-Encoding' => 'gzip, deflate, br');

# Now API calls work
my $bug = $bz->bug->get(123);
```

## Services

The main client (`$bz`) provides access to various service objects:

- **`$bz->bug`** - Query, create, and update bugs
- **`$bz->comment`** - Read and create comments, manage reactions and tags
- **`$bz->attachment`** - Access and create attachments
- **`$bz->user`** - User information and authentication
- **`$bz->product`** - Product information
- **`$bz->component`** - Component information
- **`$bz->field`** - Bug field metadata
- **`$bz->group`** - User group management
- **`$bz->classification`** - Product classifications
- **`$bz->flag_activity`** - Code review flag activity
- **`$bz->bug_user_last_visit`** - Track last visit to bugs
- **`$bz->reminder`** - Schedule reminders
- **`$bz->information`** - Server version and status
- **`$bz->github`** - GitHub integration endpoints

## Common Tasks

### Search Bugs

```perl
# Simple search
my $bugs = $bz->bug->search(
    product => 'Firefox',
    status  => 'OPEN',
);

# Advanced search with multiple criteria
my $bugs = $bz->bug->search(
    product     => 'Firefox',
    component   => 'General',
    status      => ['NEW', 'ASSIGNED'],
    severity    => 'critical',
    priority    => 'P1',
    assigned_to => 'user@example.com',
    limit       => 50,
    offset      => 0,
);

# Quick search
my $bugs = $bz->bug->search(
    quicksearch => 'status:open component:general',
);
```

### Work with Bug Details

```perl
my $bug = $bz->bug->get(123);

# Read attributes
say $bug->id;
say $bug->summary;
say $bug->status;
say $bug->assigned_to->{name};
say $bug->creation_time;

# Get full history
my $history = $bz->bug->history(123);
    for my $entry (@$history) {
    say 'Changed by ', $entry->who, ' at ', $entry->when;
    for my $change (@{ $entry->changes }) {
        say '  ', $change->field_name, ': ',
            $change->removed, ' -> ', $change->added;
    }
}

# Find duplicates
my $dupes = $bz->bug->possible_duplicates(123);
for my $dup (@$dupes) {
    say 'Possible duplicate: ', $dup->id, ' - ', $dup->summary;
}
```

### Manage Comments

```perl
# Get all comments on a bug
my $comments = $bz->comment->get($bug_id);
    for my $c (@$comments) {
    say $c->id, ': ', $c->text;
}

# Get a specific comment
my $comment = $bz->comment->get_by_id($comment_id);

# Create a comment
my $new = $bz->comment->create($bug_id,
    comment    => 'This is my comment',
    is_private => 0,
);

# Add reactions (emoji)
$bz->comment->update_reactions($comment_id,
    add => ['thumbs_up', 'heart'],
);

# Get who reacted
my $reactions = $bz->comment->get_reactions($comment_id);
for my $emoji (keys %$reactions) {
    my $users = $reactions->{$emoji};
    say "$emoji: ", join(', ', map { $_->{name} } @$users);
}
```

### Manage Attachments

```perl
# Get attachments on a bug
my $attachments = $bz->attachment->search(bug_id => $bug_id);
for my $att (@$attachments) {
    say $att->filename, ' (', $att->size, ' bytes)';
}

# Get a specific attachment
my $att = $bz->attachment->get($attachment_id);

# Create an attachment
my $new = $bz->attachment->create($bug_id,
    data         => $file_contents,
    filename     => 'patch.diff',
    content_type => 'text/plain',
    description  => 'Proposed fix',
    is_patch     => 1,
);

# Update attachment
$bz->attachment->update($attachment_id,
    description => 'Updated description',
    is_obsolete => 1,
);
```

### User Management

```perl
# Get current user
my $me = $bz->user->whoami();
say 'You are: ', $me->login_name;

# Get a user by email
my $user = $bz->user->get('user@example.com');

# Search for users
my $users = $bz->user->search(match => 'admin');

# Validate credentials
my $valid = $bz->user->valid_login(
    login    => 'user@example.com',
    password => 'password',
);

# Update user
$bz->user->update('user@example.com',
    real_name  => 'New Name',
    is_enabled => 1,
);
```

### Query Field Metadata

```perl
# Get all fields
my $fields = $bz->field->get();
for my $f (@$fields) {
    say $f->name, ': ', $f->display_name;
}

# Get a specific field
my $status = $bz->field->get_field('status');

# Get legal values for a field
my $values = $bz->field->legal_values('status');
for my $v (@$values) {
    say $v->{name};
}

# Get values for a specific product
my $comp_values = $bz->field->legal_values('component', $product_id);
```

### Server Information

```perl
# Get server version
my $version = $bz->information->server_version;
say "Bugzilla version: $version";

# Get server time
my $time = $bz->information->server_time;
say 'Server time: ', $time->{db_time};

# Get installed extensions
my $exts = $bz->information->server_extensions;
for my $ext (keys %$exts) {
    say "Extension: $ext version ", $exts->{$ext};
}

# Refresh cached data
$bz->information->refresh();
```

## Error Handling

All API errors throw `WebService::Bugzilla::Exception`:

```perl
use WebService::Bugzilla;
use Try::Tiny;

my $bz = WebService::Bugzilla->new(
    base_url => 'https://bugzilla.example.com',
    api_key  => 'your-api-key',
);

try {
    my $bug = $bz->bug->get(999999);
} catch {
    my $e = $_;
    if (ref($e) eq 'WebService::Bugzilla::Exception') {
        say 'API Error: ', $e->message;
        say 'HTTP Status: ', $e->http_status;
        say 'Bugzilla Code: ', $e->bz_code if $e->bz_code;
    } else {
        die $e;
    }
};
```

GET requests returning 404 or 410 (not found) return `undef` rather than throwing:

```perl
my $bug = $bz->bug->get(999999);  # Returns undef, doesn't throw
if ($bug) {
    say 'Found: ', $bug->summary;
} else {
    say 'Bug not found';
}
```

## Examples

The `eg/` directory contains working example scripts:

- `01-connect-and-inspect.pl` - Connect and inspect server
- `02-search-bugs.pl` - Various search patterns
- `03-bug-details.pl` - Get bug details, comments, history
- `04-list-products.pl` - List all products
- `05-active-bugs.pl` - Recently changed bugs
- `06-create-bug.pl` - Create a bug (dry-run + curl equivalent)
- `07-update-bug.pl` - Update a bug (dry-run + curl equivalent)
- `08-bug-history.pl` - Full bug history with grouping
- `09-bug-attachments.pl` - List bug attachments
- `10-find-duplicates.pl` - Find duplicate bugs
- `11-server-info.pl` - Get server information

Run any example with a Bugzilla URL:

```bash
perl eg/01-connect-and-inspect.pl https://bugs.freebsd.org
```

## API Reference

Full API documentation is available via `perldoc`:

```bash
# Main client
perldoc WebService::Bugzilla

# Service classes
perldoc WebService::Bugzilla::Bug
perldoc WebService::Bugzilla::Comment
perldoc WebService::Bugzilla::User
# ... and so on for all service classes
```

## Testing

Run the test suite:

```bash
prove -Ilib t/
```

The test suite includes 177 tests across 13 test files, all passing.

## Requirements

- Perl 5.24+
- Moo
- strictures
- namespace::clean
- WebService::Client 1.0001+
- URI::Escape
- LWP::UserAgent (via WebService::Client)

## License

MIT

## Support

For issues, questions, or contributions:

1. Check the POD documentation: `perldoc WebService::Bugzilla`
2. Review the examples in the `eg/` directory
3. Check the PLAN.md for architecture and design decisions
4. Report bugs or request features on GitHub

## Related

- [Bugzilla REST API Documentation](https://bmo.readthedocs.io/en/latest/api/core/v1/)
- [BZ::Client](https://metacpan.org/pod/BZ::Client) - Alternative Perl client for older XML-RPC/JSON-RPC APIs
- [WebService::Client](https://metacpan.org/pod/WebService::Client) - Base HTTP client library

## Author

Dean Hamstead

## Version

0.001 (initial release)
