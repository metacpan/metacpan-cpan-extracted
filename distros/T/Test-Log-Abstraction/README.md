## Name

Test::Log::Abstraction - Capture log output in tests and assert on it

## Version

0.001.0

## Synopsis

```perl
use Test::Most;
use Test::Log::Abstraction;

my $logger = Test::Log::Abstraction->new();
my $obj = Some::Class->new(logger => $logger);

$obj->do_something();

# Assertions on what was logged
$logger->like(qr/updated/, 'do_something() logs that it updated');
$logger->has_level('error');
$logger->unlike(qr/fatal/);
$logger->count() == 3;
$logger->clear();

# Or simply see the messages
diag($_) foreach @{ $logger->messages() };
```

## Description

A test double for [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction), drop-in wherever code under test is
passed a `logger =`> object.

Every level method that [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) offers (`trace`, `debug`,
`info`, `notice`, `warn`, `error`, `critical`, `alert`, `emergency`
and their syslog aliases) records the message instead of writing it to a
file, and optionally sends it to TAP diagnostics.  Nothing is ever written to
disk, and no logging backend is loaded.

### Diagnostics

Messages at `warning` and above are printed with ["diag" in Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder#diag) by
default, so a test that accidentally triggers a warning is visible; `trace`,
`debug`, `info` and `notice` are printed only in verbose mode.  Verbose
mode is on when `verbose => 1` is passed to `new()` or `$ENV{TEST_VERBOSE}`
is true.

Change it with the `diag` option: `'all'` prints everything,
`'none'` prints nothing (unless verbose), a level name such as `'error'`
prints that level and everything more severe, and an array reference prints
just those levels.

### Migrating From T/Lib/MyLogger.pm

Replace, in each test file:

```perl
use lib 't/lib';
use MyLogger;
...
logger => MyLogger->new()
```

with:

```perl
use Test::Log::Abstraction;
...
logger => Test::Log::Abstraction->new()
```

and delete `t/lib/MyLogger.pm`.  Unlike the old MyLogger copies, this
implementation is identical everywhere, never recurses when a level method is
called with `undef` (see `t/autoload.t`), and records every message so tests
can assert on it instead of only printing it.

## Methods

### New

```perl
my $logger = Test::Log::Abstraction->new();
my $logger = Test::Log::Abstraction->new(verbose => 1, diag => 'none');
```

Takes optional `verbose` and `diag` options (see ["DESCRIPTION"](#description)); any
other arguments are accepted and ignored, as ["new" in Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction#new) allows a
configuration hash to be passed through.  Called on an existing logger it
makes a clone with the same options and a copy of the captured messages, as
["new" in Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction#new) does.

### Messages

```perl
my $arrayref = $logger->messages();
```

Array reference of `{ level, message }` hash references, in the order they
were logged.  Entries logged with [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)'s structured fields
also carry a `fields` hash reference.

### Clear

```
$logger->clear();
```

Empties the captured messages and returns the logger.

### Count

```perl
my $n = $logger->count();          # all messages
my $n = $logger->count('error');   # just one level
```

Number of captured messages, optionally restricted to one level.

### Like

```
$logger->like(qr/updated/, 'optional test name');
```

Passes if any captured message matches the pattern.  Returns the result, and
reports it as a test through [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder), so count it in your plan (or
use `done_testing()`).

### Unlike

```
$logger->unlike(qr/fatal/, 'optional test name');
```

Passes if no captured message matches the pattern.

### Has\_Level

```
$logger->has_level('error', 'optional test name');
```

Passes if at least one message was logged at that level.

### Empty

```
$logger->empty('nothing was logged');
```

Passes if nothing at all was captured - the usual assertion after a clean run.

### Verbose

```perl
my $verbose = $logger->verbose();
$logger->verbose(1);
```

Gets or sets verbose mode.

## Diagnostics

`no method 'foo'` - the code under test called `$logger->foo()`, which
is not a log level; the message is captured under that name and the notice is
always printed, so a typo'd level cannot pass silently.

### Trace, Debug, Info, Notice, Warn, Error, Critical, Alert, Emergency

```perl
$logger->warn('something looks wrong');
$logger->info('started', { pid => $$ });
$logger->error({ error => 'cannot open file' });
```

Every [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) level and syslog alias is a method.  Each records
the call and, subject to the `diag` setting, prints it.  Arguments follow
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)'s rules: they are concatenated into the message, a hash
reference at the end of two or more arguments is captured as structured
`fields`, and a lone hash reference is the message and is rendered as
`key => value` pairs so it can be matched.  `undef` arguments become the
string `undef` and never warn.

Levels are thin wrappers over `_record`; they exist so that `AUTOLOAD` only
sees genuinely unknown methods.

- `trace`, `debug`, `info`, `informational`, `notice`

    Captured; printed only in verbose mode by default.

- `warn`, `warning`, `error`, `err`, `critical`, `crit`,
`fatal`, `alert`, `emergency`, `emerg`, `panic`

    Captured and printed by default.

### New

See ["new"](#new) above.

### Autoload

Any other method call - typically a level name that doesn't exist, such as a
typo - captures the message under that name and prints a notice, instead of
dying part way through a test.

### Messages, Clear, Count, Like, Unlike, Has\_Level, Empty, Verbose

See ["METHODS"](#methods) above.

## See Also

[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction), [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder), [Test::Most](https://metacpan.org/pod/Test%3A%3AMost)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
