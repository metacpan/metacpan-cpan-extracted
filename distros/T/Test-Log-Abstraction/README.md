## Name

Test::Log::Abstraction - Capture log output in tests and assert on it

## Version

0.002.1

## Synopsis

### Check What Your Code Logged

```perl
use Test::Most;
use Test::Log::Abstraction;

# Give the test logger to the code that you are testing
my $logger = Test::Log::Abstraction->new();
my $obj = Some::Class->new(logger => $logger);

$obj->do_something();

# Each of these is one TAP test
$logger->like(qr/updated/, 'do_something() logs that it updated');
$logger->has_level('error', 'an error was logged');
$logger->unlike(qr/fatal/, 'nothing fatal was logged');
is($logger->count(), 3, 'three messages were logged');

done_testing();
```

### Check That Nothing Was Logged

```perl
my $logger = Test::Log::Abstraction->new();
Some::Class->new(logger => $logger)->run();
$logger->empty('a normal run logs nothing');
```

### Test Several Steps With One Logger

```perl
my $logger = Test::Log::Abstraction->new();
my $obj = Some::Class->new(logger => $logger);

$obj->load('good.csv');
$logger->empty('good file: no messages');

$logger->clear();    # forget the messages from the first step
$obj->load('bad.csv');
$logger->has_level('warn', 'bad file: a warning');
```

### Look at the Messages Yourself

```perl
foreach my $entry (@{ $logger->messages() }) {
    print "$entry->{level}: $entry->{message}\n";
}

# Structured fields, from a call such as
# $logger->info('user logged in', { user => 'alice' })
is($logger->messages()->[0]->{fields}->{user}, 'alice', 'user field');
```

### Control What Is Printed While the Test Runs

```perl
# Print nothing (the messages are still captured)
my $quiet = Test::Log::Abstraction->new(diag => 'none');

# Print everything
my $loud = Test::Log::Abstraction->new(verbose => 1);

# Print only errors and more serious messages
my $errors = Test::Log::Abstraction->new(diag => 'error');
```

### Test Code That Checks the Log Level

```perl
# The code under test does: if($logger->is_debug()) { ... }
my $logger = Test::Log::Abstraction->new(level => 'warning');
ok(!$logger->is_debug(), 'debug output is turned off');
```

### Get This Module's Own Messages in Another Language

```perl
my $logger = Test::Log::Abstraction->new(lang => 'de');    # German
my $french = Test::Log::Abstraction->new(country => 'FR');    # French
```

## Description

### What This Module Is

Some code writes log messages through a logger object.  In production that
object is usually a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) logger.  In a test, you give the code
a `Test::Log::Abstraction` object instead.

This object does not write the messages to a file.  It keeps them in a list
in memory.  After the code has run, your test can check the list: was a
message logged, at which level, and what did it say?

It never writes to disk, and it does not load any logging backend.

### Which Methods It Has

- **Log levels.**  The level methods of [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction):
`trace`, `debug`, `info`, `notice`, `warn`, `error`, `fatal`,
`critical`, `alert` and `emergency`.  It also accepts the syslog names
`warning`, `err`, `crit`, `emerg`, `panic` and `informational`.
- **Other logger methods.**  `level()`, `is_debug()` and the other
`is_<level>()` methods, `messages()`, `flush()` and
`reopen()`.  Code under test may call these, so they work as they do in
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction).
- **Test methods.**  `like`, `unlike`, `has_level` and `empty`.
Each one reports one test result, like `ok()` in [Test::More](https://metacpan.org/pod/Test%3A%3AMore).
- **Helper methods.**  `count`, `clear`, `verbose` and `lang`.

### Which Messages Are Printed

Every message is always stored.  This section is only about which messages
are also printed in the test output, as TAP comments (lines that start with
`#`).

By default, `warning` and more serious levels are printed.  So if a test
causes a warning by accident, you see it.  `trace`, `debug`, `info` and
`notice` messages are not printed.

Verbose mode prints every message.  Verbose mode is on when you pass
`verbose => 1` to `new()`.  If you do not pass `verbose`, it is on
when the environment variable `TEST_VERBOSE` is true (`prove -v` sets
it), or when `VERBOSE` is true.

To choose the levels, use the `diag` option of `new()`:

- `'all'` - print every message.
- `'none'` - print nothing (verbose mode still prints everything).
- A level name, such as `'error'` - print that level and every more
serious level.
- A list, such as `['info', 'error']` - print only these levels.

Put exactly: a message is printed when **any one** of these is true, and
not otherwise:

- 1. Verbose mode is on.
- 2. `diag` is `'all'`.
- 3. `diag` is a list, and the message's level name is in it.
- 4. `diag` is a level name, the message's level is a known level, and
its number is the same as, or lower than, that level's number.

So a misspelt level (caught by ["AUTOLOAD"](#autoload)) is printed only by rules 1 to
3; and `'none'` or an empty list means only rule 1 can apply.

When a test method fails, the messages that explain the failure are printed
under it.  So you can see why it failed without running the test again.

### Global Variables Are Left Alone

No method changes `$@`, `$!` or `$_`, and none of them touches an
`alarm()` timer.  So you can log, or test the log, inside an error
handler, and `$@` still holds the error afterwards.  (A method that stops
with an error does set `$@`, as every Perl error does.)

### Levels and How Serious They Are

Each level has a number.  A lower number means a more serious message.
These are the syslog numbers.  The names and numbers come from
[Readonly::Values::Syslog](https://metacpan.org/pod/Readonly%3A%3AValues%3A%3ASyslog), so they are the same as in other modules that
use it.

```
0  emergency, emerg, panic
1  alert
2  critical, crit, fatal
3  error, err
4  warning, warn
5  notice
6  info, informational
7  debug, trace
```

### Language of This Module's Messages

This module has its own messages: error messages, warnings, and the text
that explains a failed test.  They can be in English (`en`), German
(`de`), French (`fr`) or Simplified Chinese (`zh`).

The language is chosen like this.  The first rule that gives an answer is
used:

- 1. The `lang` option, for example `lang => 'de'`.
- 2. The `country` option, a two-letter country code such as `'FR'`.
- 3. Only when `lang => 'auto'`: the environment variables
`LC_ALL`, `LC_MESSAGES` and `LANG`, in that order.
- 4. `$Test::Log::Abstraction::config{lang}`, which is `'en'`.

The default is English, not the language of your computer.  This is on
purpose: the test output is then the same on every computer.

If a message has no translation, the English message is used.  You can add
or change messages with the `i18n` option of `new()`.

This only changes this module's own messages.  The messages that your code
logs are never changed.

### Default Settings

The defaults for `new()` are in the hash
`%Test::Log::Abstraction::config`.  It has the same keys as the options of
`new()`.  You can change it in a test, or fill it with
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure):

```
$Test::Log::Abstraction::config{'diag'} = 'none';
```

A change only affects loggers that are created after it.

You can also pass the result of [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) straight to `new()`.
Settings in environment variables named `Test__Log__Abstraction__KEY`
then override the arguments; the extra keys that [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)
adds (such as its own `logger`) are ignored:

```perl
# In the shell: export Test__Log__Abstraction__diag=none
my $params = Object::Configure::configure('Test::Log::Abstraction', { level => 'error' });
my $logger = Test::Log::Abstraction->new($params);
```

## Common Pitfalls

- **The test methods are tests.**  `like`, `unlike`, `has_level`
and `empty` each add one test to the TAP output.  If you give a test
plan (`tests => 5`), count them.  Or use `done_testing()`.
- **Messages from earlier steps are still there.**  A logger keeps
every message until you call `clear()`.  If one logger is used for
several steps, `like` may match a message from an earlier step.
- **A string pattern is a regular expression.**  `like('a.c')`
matches `'abc'`, because `.` means "any character".  To match the text
exactly, use `qr/\Qa.c\E/`.
- **Different names for one level are counted apart.**  `warn` and
`warning` have the same number, but `count('warn')` and
`has_level('warn')` do not see messages logged with `warning()`.  Check
the name that the code under test uses.  `fatal` is stored as `fatal`,
but [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) stores it as `error`.
- **`undef` is not the same as "no value".**
    - An `undef` argument to a level method becomes the text
    `undef` in the message.  ([Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) drops it.)
    - `verbose => undef` turns verbose mode **off**.  To use the
    environment variables instead, do not pass `verbose` at all.
    - `diag => undef` and `level => undef` use the default
    from `%config`.
    - `count(undef)` counts all messages.  `level(undef)` returns the
    level number and changes nothing.
    - `like(undef)`, `unlike(undef)` and `has_level(undef)` stop the
    test with an error.
- **One hash reference, or a hash reference at the end.**
`$logger->info({ a => 1 })` logs the text `{a => 1}`.  But
`$logger->info('text', { a => 1 })` logs the text `text` and stores
`{ a => 1 }` in `fields`.  An empty hash at the end is dropped.
- **Copies are shallow (only one level deep).**
    - When a message has `fields`, the fields hash is copied.  But a
    hash or array **inside** the fields is not copied.  If your code changes it
    later, the stored message changes too.  And if the fields contain the
    logger itself, the logger is never freed (a reference cycle) until you
    call `clear()`.
    - `messages()` returns a new list, but the entries in it are the
    stored entries.  Do not change them, unless you want to change what was
    captured.
    - `new()` keeps its own copy of the `diag` list and the `i18n`
    tables.  Changing your array or hash afterwards does not change the
    logger.  (A part of an `i18n` table that contains itself is left out of
    the copy; it would only ever render as an empty string.)
    - When you clone a logger with `$logger->new(%options)`, each
    option replaces the old option completely.  For example,
    `$logger->new(i18n => { de => {...} })` replaces the whole `i18n`
    hash.  The translations in the old hash are not kept.
- **The `i18n` option is merged message by message.**  You only
need to give the messages that you want to change.  For each message,
this module looks in your `i18n` hash first, and then in its own list.
So any message that you do not give keeps its normal text.
- **A misspelt method name does not stop the test.**
`$logger->wran('x')` stores the message under the name `wran` and
prints a notice.  The test still passes, unless you check the messages.
A misspelt level name given to `count()` is not caught either: see
["LIMITATIONS"](#limitations).
- **`prove -v` prints everything.**  `prove -v` sets
`TEST_VERBOSE`, which turns verbose mode on.  If a test checks what is
printed, set `verbose => 0` or `$ENV{TEST_VERBOSE} = 0`.
- **`level()` does not hide messages.**  It only changes the answers
of the `is_*` methods.  Every message is still stored.

## Encoding

This module never changes the text that your code logs.  It stores each
message exactly as it was given.

- **Log messages and fields: any text.**  ASCII, other languages and
emoji are all stored safely.  It does not matter if the text is a Perl
character string (decoded, for example with `use utf8` or
["decode" in Encode](https://metacpan.org/pod/Encode#decode)) or a byte string (for example, UTF-8 bytes read from a
file).
- **Matching with `like` and `unlike`.**  The pattern is matched
against the stored text as it is.  So the pattern and the message must be
the same kind of string.  A pattern with a character, such as
`qr/\x{1F600}/`, does not match the same emoji stored as UTF-8 bytes.
- **Printed messages.**  A Perl character string that has any
character above ASCII is printed as UTF-8.  A byte string is printed
unchanged.  Perl cannot always see the difference: a string that was not
decoded, and has no character above 255 (such as `"caf\x{e9}"`), is
treated as bytes.  If the output already has an encoding layer (for example, set
by [Test2::Plugin::UTF8](https://metacpan.org/pod/Test2%3A%3APlugin%3A%3AUTF8)), the text is not encoded again.
- **This module's own messages.**  German, French and Chinese messages
are character strings, and they are printed as UTF-8.  There is one
problem case: a translated message that includes a logged message that is
a non-ASCII byte string.  That part of the text is printed wrongly (it is
encoded twice).  English messages do not have this problem.
- **Options.**  `lang` and `country` must be ASCII, in the formats
given under ["new"](#new).  Level names are ASCII.  Templates in the `i18n`
option may contain any characters, but placeholder names must be ASCII
letters, digits or `_`.
- **Test names.**  Test names are passed to [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder)
unchanged.

## Methods

### New

Create a new test logger.

#### Purpose

Make a logger that stores every message it is given, so that your test can
check the messages later.

#### Args

All options are optional.  Give them as a list (`key => value`) or as
one hash reference.

- `verbose` - true: print every message.  False: use the `diag`
rule.  If you do not give it, the value of `$ENV{TEST_VERBOSE}` or
`$ENV{VERBOSE}` is used.
- `diag` - which messages to print.  `'all'`, `'none'`, a level
name (print that level and every more serious level), or an array
reference of level names.  Upper or lower case does not matter.  The
default is `'warning'`.
- `level` - the level that `level()` and the `is_*` methods
report.  The default is `'trace'`, so every `is_*` method returns 1, and
the code under test runs all its debug code.  This option does not stop
any message from being stored.
- `lang` - the language of this module's own messages: `'en'`,
`'de'`, `'fr'`, `'zh'`, a locale name such as `'de_DE.UTF-8'`, or
`'auto'` (read the environment).  Must be 2 or 3 ASCII letters, then
optionally `_`, `.`, `@` or `-` and more text.
- `country` - a two-letter country code such as `'GB'` or
`'fr'` (upper or lower case).  Used to choose the language when `lang`
is not given.
- `i18n` - your own message texts, as
`{ language => { message_key => template } }`.  See ["i18n"](#i18n).

Other options are allowed and ignored.  (A [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
configuration hash can be passed unchanged.)  If you pass an odd number of
arguments, they are all ignored.

#### Three Ways to Call It

- `Test::Log::Abstraction->new(%options)` - the usual way.
- `$logger->new(%options)` - make a **clone**: a new logger with
the same options, the same `verbose` and `level` settings, and a copy of
the stored messages.  The options that you pass replace the old ones.
- `Test::Log::Abstraction::new(%options)` - called as a function.
This works too.

#### Returns

The new logger object.

#### Side Effects

Reads `%ENV` to decide on verbose mode, and, with `lang => 'auto'`,
to choose the language.  Nothing else changes.  A clone does not change the
original logger.

#### Example

```perl
# The usual way
my $logger = Test::Log::Abstraction->new();

# Store everything, print nothing
my $quiet = Test::Log::Abstraction->new(diag => 'none');

# A hash reference works too; messages in German
my $german = Test::Log::Abstraction->new({ country => 'DE' });

# A clone that prints everything; $logger is not changed
my $loud = $logger->new(diag => 'all');
```

#### Api Specification

##### Input

```perl
{
    verbose => { type => 'scalar', optional => 1 },
    diag => { type => ['string', 'arrayref'], optional => 1 },
    level => { type => 'string', optional => 1 },
    lang => { type => 'string', optional => 1, matches => qr/\A(?:(?i:auto)|[A-Za-z]{2,3}(?:[_.\@-][\w.\@-]*+)?)\z/ },
    country => { type => 'string', optional => 1, matches => qr/\A[A-Za-z]{2}\z/ },
    i18n => { type => 'hashref', optional => 1 },
}
```

Domains (valid / invalid / boundaries):

```
verbose   valid: any plain value, Perl truth decides ('0', '' and undef
          are off; '00', '0.0' and ' ' are on); absent: from
          TEST_VERBOSE or VERBOSE.  Invalid: any reference.
diag      valid: 'all' or 'none' (any case); a level name (any case),
          which prints severity 0 (emergency) up to that level's
          number, 7 (trace) being every level; an array reference of
          level names, [] printing nothing and duplicates counting
          once; absent or undef: $config{diag}.  Invalid: any other
          string, including '' and numbers such as '4'; a list
          element that is not a level name (or is 'all'); a hash,
          code or scalar reference.
level     valid: the 16 level names, any case, setting 0 (emergency)
          to 7 (trace); absent or undef: $config{level}.  Invalid:
          '', numbers (even 0 to 7), any other name.  The error shows
          the name as it was given ('LOUD', not 'loud').
lang      valid: 'auto' (any case); 2 or 3 ASCII letters, then
          optionally one of _ . @ - and anything else ('de',
          'eng', 'de_DE.UTF-8', 'zh-Hant').  A code with no catalogue
          ('ja', 'eng') gives 'en'.  Invalid: 1 letter, 4 or more
          letters, '', digits, a non-ASCII letter in the code, any
          whitespace or newline.
country   valid: exactly 2 ASCII letters, any case; one with no
          mapping ('JP') gives 'en'.  Invalid: 1 or 3 letters, '',
          digits, non-ASCII letters.
i18n      valid: a hash reference (even empty).  Invalid: any other
          type.
```

An "invalid argument" explanation, and a level or diag name repeated in an
error, is at most 200 characters; one longer is cut to 200 and ends with
"...".  Control characters in it are shown as `\xNN`.

##### Output

```perl
{ type => 'object', isa => 'Test::Log::Abstraction' }
```

#### Messages

All of these stop the program (`croak`).

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
invalid diag level 'X'          X is not a level name         Use a name from the level table
diag must be a level name ...   diag is a hash or code ref    Give a string or an array ref
invalid syslog level 'X'        the level option is unknown   Use a name from the level table
invalid argument: ...           an option has the wrong type  Fix the option that is named
                                or format
```

#### Pseudocode

```
if new() was called on a logger object:
    options = the object's options, replaced by the new options
    build a logger from the options, with a copy of the messages
    copy verbose and level from the object, unless new values were given
else:
    if new() was called as a function, the first argument is an option
    turn the arguments into a hash (ignore an odd-length list)
    check the options
    choose the language, then the diag rule, then the level
return the logger
```

### Trace, Debug, Info, Notice, Warn, Error, Fatal, Critical, Alert, Emergency

Store a message at this level.

#### Purpose

These are the methods that the code under test calls to log something.
There is one method for each [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) level, and one for each
syslog name: `warning`, `err`, `crit`, `emerg`, `panic` and
`informational`.  Each method stores the message under the name that was
called, and may print it (see ["Which messages are printed"](#which-messages-are-printed)).

By default:

- `trace`, `debug`, `info`, `informational`, `notice` - stored,
not printed.
- `warn`, `warning`, `error`, `err`, `critical`, `crit`,
`fatal`, `alert`, `emergency`, `emerg`, `panic` - stored and printed.

#### Args

Any list of values.  They are turned into one message like this:

- With no values at all, `warn` and the more serious levels
(`warning`, `error`, `err`, `critical`, `crit`, `fatal`, `alert`,
`emergency`, `emerg`, `panic`) store nothing, as in [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction).
The less serious levels (`trace`, `debug`, `info`, `informational`,
`notice`) store an empty message, as [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) does.
- All the values are joined together, with nothing between them.
- One newline at the end is removed.
- If the only value is an array reference, its items are the parts
of the message.
- If there are two or more values and the last one is a hash
reference, that hash is not part of the message.  A copy of it is stored as
`fields`.  An empty hash is dropped.  A tied hash that dies when it is
read cannot be copied, so it stays in the message, written in Perl's
plain form (`HASH(0x...)`), and the log call still works.
- A hash reference in the message is written as
`{key => value, ...}`, with the keys sorted.  An array reference is
written as `[a, b]`.  So you can match their contents.
- `undef` is written as the text `undef`.  There is no warning.
- An object is written as Perl normally writes it.  If the object
has its own text form (overloaded `""`), that form is used.  If that text
form dies, the object is written in Perl's plain form, such as
`My::Class=HASH(0x55d0c8a1e2f8)`, and the log call still works.
- A structure that contains itself is written as `(cycle)` at the
point where it repeats.

#### Returns

The logger, as in [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction).  So you can chain calls:
`$logger->info('a')->info('b')`.

#### Side Effects

Adds one entry to the stored messages (none for a call with no values at
`warn` or above; see ["Args"](#args)).  May print the message.  The
variables `$@` and `$!` are not changed.  So you can log inside an error
handler without losing the error.

#### Example

```perl
$logger->warn('something looks wrong');
$logger->warn('file ', $name, ' is empty');          # joined: one message
$logger->info('started', { pid => $$ });             # message + fields
$logger->error({ error => 'cannot open file' });     # hash as the message
$logger->debug(['part 1, ', 'part 2']);              # array of parts
```

#### Api Specification

##### Input

```perl
{
    messages => { type => 'arrayref', position => 0, slurp => 1 },
}
```

Domains: any number of arguments (0 gives an empty message) of any
kind and length.  Exactly one trailing newline is removed (so "m\\n\\n"
keeps one).  A trailing hash after one or more values is fields; an empty
one is dropped; a blessed hash is part of the message.  Text may be ASCII,
decoded text in any script (accents, CJK, emoji and emoji sequences,
combining marks, right-to-left text, zero-width characters) or bytes; it
is stored with its length unchanged.  See ["ENCODING"](#encoding) for how it is
printed.

##### Output

```perl
{ type => 'object', isa => 'Test::Log::Abstraction' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
X() must be called on an        not called on a logger        Call it on a logger object
object, not on the class        (croak)
```

### Is\_Trace, Is\_Debug, Is\_Info, Is\_Notice, Is\_Warn, Is\_Error, Is\_Critical, Is\_Alert, Is\_Emergency

Ask if a level is turned on.

#### Purpose

Some code only builds a log message if the level is turned on, for
example `if($logger->is_debug()) { ... }`.  These methods answer that
question, as [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) does.

#### Args

None.

#### Returns

1 if the level is turned on, otherwise 0.  A level is turned on when its
number is the same as, or lower than, the logger's level (see ["level"](#level)).
The default level is `trace`, so all these methods return 1.

#### Side Effects

None.

#### Example

```
$logger->level('warning');
$logger->is_warn();     # 1
$logger->is_error();    # 1 (more serious than warning)
$logger->is_info();     # 0 (less serious than warning)
```

#### Api Specification

##### Input

```
{}
```

Domains: no arguments.  Each predicate is 1 exactly when its level's
number is at or below the logger's level: at level 0 (emergency) only
is\_emergency is 1; at level 7 (trace) all are 1.

##### Output

```perl
{ type => 'boolean' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
is_X() must be called on an     not called on a logger        Call it on a logger object
object, not on the class        (croak)
```

### Autoload

Handle a call to a method that does not exist.

#### Purpose

Perl calls this when the code under test calls a method that this class
does not have - usually a misspelt level, such as `wran`.  Any name
works, even an empty one (`$logger->$name()` with `$name = ''`).  Instead of
stopping the test, the message is stored under the name that was called,
and a notice is printed.  The notice is always printed, whatever the
`diag` setting, so the mistake is not hidden.

#### Args

The same as a level method.

#### Returns

The logger.

#### Side Effects

Adds one entry, with the called name as its level.  Prints
`no method 'name'`.

#### Example

```
$logger->wran('oops');    # stored at level 'wran'; a notice is printed
is($logger->count('wran'), 1, 'the misspelt call was stored');
```

#### Api Specification

##### Input

```perl
{
    messages => { type => 'arrayref', position => 0, slurp => 1 },
}
```

Domains: any method name, including '', non-ASCII names and very long
names.  The message is stored under the name in lower case, in full.  The
notice shows the name escaped and cut: up to 200 characters it is shown
whole, and from 201 on it is cut to 200 followed by '...' (see
["DIAGNOSTICS"](#diagnostics)).  The length is counted in characters, not bytes.

##### Output

```perl
{ type => 'object', isa => 'Test::Log::Abstraction' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
no method 'X'                   X is not a method or a level  Fix the method name
                                (notice; the test goes on)
                                (X is shown escaped and cut;
                                see DIAGNOSTICS)
X() must be called on an        an unknown method was called  Call it on a logger object
object, not on the class        on the class name (croak)
```

### Messages

Get the stored messages.

#### Purpose

Let your test look at everything that was logged.

#### Args

None.

#### Returns

A reference to a new array.  It has one hash reference for each message,
oldest first.  Each hash has these keys:

- `level` - the level name, in lower case, as it was called.
- `message` - the message text.
- `fields` - only when fields were given: a hash reference.

The array is a copy, as in [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction).  Adding or removing items
in it does not change the stored messages.  But the hashes in it are the
stored hashes (see ["COMMON PITFALLS"](#common-pitfalls)).

#### Side Effects

None.

#### Example

```perl
foreach my $entry (@{ $logger->messages() }) {
    diag("$entry->{level}: $entry->{message}");
}

my $first = $logger->messages()->[0];
is($first->{level}, 'warn', 'the first message is a warning');
```

#### Api Specification

##### Input

```
{}
```

Domains: no arguments; any that are given are ignored.

##### Output

```perl
{ type => 'arrayref' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
messages() must be called on    not called on a logger        Call it on a logger object
an object, not on the class     (croak)
```

### Clear

Delete all stored messages.

#### Purpose

Start again with an empty list, for example between two steps of a test.

#### Args

None.

#### Returns

The logger, so you can chain calls.

#### Side Effects

All stored messages are deleted.  The settings (`verbose`, `level`,
`diag`, language) do not change.  On a logger with no messages, it does
nothing, so it is safe to call before every step.

#### Example

```
$logger->clear();
$logger->clear()->empty('nothing logged yet');
```

#### Api Specification

##### Input

```
{}
```

Domains: no arguments; any that are given are ignored.

##### Output

```perl
{ type => 'object', isa => 'Test::Log::Abstraction' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
clear() must be called on an    not called on a logger        Call it on a logger object
object, not on the class        (croak)
```

### Count

Count the stored messages.

#### Purpose

Check how much was logged, in total or at one level.

#### Args

- `$level` - optional.  Count only messages at this level.  Upper or
lower case does not matter.  Different names for the same level are counted
apart: `count('warn')` does not count `warning()` calls.

#### Returns

The number of messages: 0 or more.

#### Side Effects

None.

#### Example

```
is($logger->count(), 3, 'three messages in total');
is($logger->count('error'), 1, 'one of them is an error');
```

#### Api Specification

##### Input

```perl
{
    level => { type => 'string', optional => 1, position => 0 },
}
```

Domains: undef counts every message; a string counts messages at that
level, any case ('', '0' and unknown names give 0; aliases are separate
names).  Invalid: any reference.

##### Output

```perl
{ type => 'integer', min => 0 }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
count() must be called on an    not called on a logger        Call it on a logger object
object, not on the class        (croak)
invalid argument: ...           the level is not a string     Give a level name
                                (croak)
```

### Like

Test that a stored message matches a pattern.

#### Purpose

The test passes if at least one stored message matches the pattern.

#### Args

- `$pattern` - required.  A `qr//` regular expression, or a string.
A string is also used as a regular expression.
- `$name` - optional.  The name of the test.

#### Returns

True if the test passed, false if it failed.

#### Side Effects

Adds one test result to the TAP output.  If the test fails, all stored
messages are printed under it (at most 20, then a count of the others).

#### Example

```
$logger->like(qr/updated/, 'the update was logged');
$logger->like(qr/^Cannot open/i, 'the open error was logged');
```

#### Api Specification

##### Input

```perl
{
    pattern => { type => ['regex', 'string'], position => 0 },
    name => { type => 'string', optional => 1, position => 1 },
}
```

Domains: pattern - a qr// or a string, which is compiled as a regular
expression ('' matches every message).  Invalid: undef, any other
reference, a string that does not compile or can never match.  name -
undef, or any string (including '' and non-ASCII text).  Invalid: a
reference.

##### Output

```perl
{ type => 'boolean' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
like() needs a pattern          no pattern was given (croak)  Give a qr// or a string
invalid argument: ...           the pattern is not a qr// or  Give a qr// or a string
                                a string, does not compile,   that is a valid regex
                                or can never match (croak)
N messages were captured:       the test failed; the stored   Compare them with the pattern
                                messages follow (output)
like() must be called on        not called on a logger        Call it on a logger object
an object, not on the class     (croak)
```

### Unlike

Test that no stored message matches a pattern.

#### Purpose

The test passes if no stored message matches the pattern.  It also passes
when there are no messages.

#### Args

- `$pattern` - required.  A `qr//` regular expression, or a string.
A string is also used as a regular expression.
- `$name` - optional.  The name of the test.

#### Returns

True if the test passed, false if it failed.

#### Side Effects

Adds one test result to the TAP output.  If the test fails, the messages
that matched are printed under it.

#### Example

```
$logger->unlike(qr/fatal/i, 'nothing fatal was logged');
```

#### Api Specification

##### Input

```perl
{
    pattern => { type => ['regex', 'string'], position => 0 },
    name => { type => 'string', optional => 1, position => 1 },
}
```

Domains: as for ["like"](#like).  Note that '' matches every message, so
unlike('') fails whenever anything was logged.

##### Output

```perl
{ type => 'boolean' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
unlike() needs a pattern        no pattern was given (croak)  Give a qr// or a string
invalid argument: ...           the pattern is not a qr// or  Give a qr// or a string
                                a string, does not compile,   that is a valid regex
                                or can never match (croak)
N messages matched:             the test failed; the          Look at the listed messages
                                matching messages follow
unlike() must be called on      not called on a logger        Call it on a logger object
an object, not on the class     (croak)
```

### Has\_Level

Test that something was logged at a level.

#### Purpose

The test passes if at least one message was stored at this level.

#### Args

- `$level` - required.  The level name.  Upper or lower case does
not matter.  Different names for the same level are different:
`has_level('warn')` does not see `warning()` calls.
- `$name` - optional.  The name of the test.

#### Returns

True if the test passed, false if it failed.

#### Side Effects

Adds one test result to the TAP output.  If the test fails, all stored
messages are printed under it, so you can see which levels were used.

#### Example

```
$logger->has_level('error', 'the failure was logged');
```

#### Api Specification

##### Input

```perl
{
    level => { type => 'string', position => 0 },
    name => { type => 'string', optional => 1, position => 1 },
}
```

Domains: level - a string, any case ('' and unknown names match
nothing; aliases are separate names).  Invalid: undef, any reference.
name - as for ["like"](#like).

##### Output

```perl
{ type => 'boolean' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
has_level() needs a level name  no level was given (croak)    Give a level name
invalid argument: ...           the level is not a string     Give a level name
                                (croak)
N messages were captured:       the test failed; the stored   Look at the listed levels
                                messages follow (output)
has_level() must be called on   not called on a logger        Call it on a logger object
an object, not on the class     (croak)
```

### Empty

Test that nothing was logged.

#### Purpose

The test passes if there are no stored messages.  Use it to check that a
normal run logs nothing.

#### Args

- `$name` - optional.  The name of the test.

#### Returns

True if the test passed, false if it failed.

#### Side Effects

Adds one test result to the TAP output.  If the test fails, the stored
messages are printed under it.

#### Example

```
$logger->empty('a normal run logs nothing');
```

#### Api Specification

##### Input

```perl
{
    name => { type => 'string', optional => 1, position => 0 },
}
```

Domains: name - undef, or any string.  Invalid: a reference.

##### Output

```perl
{ type => 'boolean' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
N messages were captured:       the test failed; the stored   Look at the listed messages
                                messages follow (output)
empty() must be called on       not called on a logger        Call it on a logger object
an object, not on the class     (croak)
```

### Verbose

Get or change verbose mode.

#### Purpose

In verbose mode, every message is printed, whatever the `diag` rule says.
This helps when you are finding out why a test fails.

#### Args

- `$value` - optional.  True turns verbose mode on, false turns it
off.  Without an argument, nothing changes.

#### Returns

The setting after the call: 1 (on) or 0 (off).

#### Side Effects

Changes the setting, when you give an argument.

#### Example

```perl
$logger->verbose(1);           # print everything from now on
my $on = $logger->verbose();   # 1
```

#### Api Specification

##### Input

```perl
{
    value => { type => 'scalar', optional => 1, position => 0 },
}
```

Domains: absent - get only; otherwise Perl truth decides ('0', '' and
undef are off; '0.0' is on).

##### Output

```perl
{ type => 'integer', min => 0, max => 1 }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
verbose() must be called on an  not called on a logger        Call it on a logger object
object, not on the class        (croak)
```

### Level

Get or change the logger's level.

#### Purpose

Code under test may read or change the level, as it can with
["level" in Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction#level).  The level only changes the answers of the
`is_*` methods.  Every message is still stored.

#### Args

- `$name` - optional.  A level name.  Upper or lower case does not
matter.

#### Returns

- No argument: the level's number, from 0 to 7.
- A known level name: the logger, so you can chain calls.
- An unknown level name: `undef`, as in [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction).

#### Side Effects

With a known name, the level changes.  With an unknown name, nothing
changes and a warning is printed.

#### Example

```
$logger->level('error');
print $logger->level(), "\n";    # 3
```

#### Api Specification

##### Input

```perl
{
    name => { type => 'string', optional => 1, position => 0 },
}
```

Domains: absent or undef - get only; one of the 16 level names, any
case - set (0 for emergency to 7 for trace).  Anything else - '', numbers
such as '0' or '8', unknown names - warns and returns undef.  A reference
is treated as its text form: a plain reference such as ARRAY(0x...) is
never a level name, so it warns; an object whose overloaded text form is
a level name sets that level; an object whose text form dies is shown in
plain form in the warning.

##### Output

```perl
{ type => ['integer', 'object'], optional => 1 }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
invalid syslog level 'X'        X is not a level name         Use a name from the level table
                                (warning; returns undef)
level() must be called on       not called on a logger        Call it on a logger object
an object, not on the class     (croak)
```

### Flush

Do nothing.

#### Purpose

In [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction), `flush()` sends e-mail messages that are waiting.
The test logger never sends e-mail, but the code under test may still call
`flush()`, so it exists.

#### Args

None.

#### Returns

The logger, so you can chain calls.

#### Side Effects

None.

#### Example

```
$logger->flush();
```

#### Api Specification

##### Input

```
{}
```

Domains: no arguments; any that are given are ignored.

##### Output

```perl
{ type => 'object', isa => 'Test::Log::Abstraction' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
flush() must be called on an    not called on a logger        Call it on a logger object
object, not on the class        (croak)
```

### Reopen

Do nothing.

#### Purpose

In [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) 0.41 and later, `reopen()` closes the log files, so
that the next message opens them again.  A program calls it after another
program has moved or renamed its log files (log rotation), often from a
`$SIG{HUP}` handler.  The test logger has no files, but the code under
test may still call `reopen()`, so it exists.  Without it, the call would
be stored as a message at level `reopen`, and a "no method" notice would
be printed.

#### Args

None.

#### Returns

The logger, so you can chain calls.

#### Side Effects

None.  No message is stored or printed, and `$@` and `$!` do not change.

#### Example

```perl
# The code under test reopens its logs when it gets SIGHUP
local $SIG{HUP} = sub { $logger->reopen() };
kill('HUP', $$);
$logger->empty('reopening the logs logged nothing');
```

#### Api Specification

##### Input

```
{}
```

Domains: no arguments; any that are given are ignored.

##### Output

```perl
{ type => 'object', isa => 'Test::Log::Abstraction' }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
reopen() must be called on an   not called on a logger        Call it on a logger object
object, not on the class        (croak)
```

### Lang

Get the language of this module's messages.

#### Purpose

Let a test check which language was chosen from the `lang` and `country`
options or the environment.

#### Args

None.

#### Returns

A language code: `en`, `de`, `fr`, `zh`, or a code that you gave in the
`i18n` option.

#### Side Effects

None.

#### Example

```perl
my $lang = Test::Log::Abstraction->new(country => 'FR')->lang();    # 'fr'
```

#### Api Specification

##### Input

```
{}
```

Domains: no arguments; any that are given are ignored.

##### Output

```perl
{ type => 'string', matches => qr/\A[a-z]{2,3}\z/ }
```

#### Messages

```
Message                         Meaning                       What to do
------------------------------  ----------------------------  ------------------------------
lang() must be called on an     not called on a logger        Call it on a logger object
object, not on the class        (croak)
```

## Methods for Subclasses

These methods are for this class, and classes that inherit from it.  A
subclass may call them, or replace them.  Nothing stops other code calling
them, but they are not part of the public interface, and may change.

### \_Emit

Print one line of test output.

#### Purpose

Every line that this module prints goes through this method.  A subclass
can replace it to send the lines somewhere else.

#### Args

- `$text` - the line to print.

#### Returns

The logger.

#### Side Effects

Prints the line as a TAP comment, with ["diag" in Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder#diag).  This works
even if the test did not load [Test::More](https://metacpan.org/pod/Test%3A%3AMore).  A Perl character string is
encoded as UTF-8 first, unless the output already has an encoding layer
(see ["ENCODING"](#encoding)).

#### Example

```perl
package My::Logger;
use parent -norequire, 'Test::Log::Abstraction';

# Send the lines to STDERR instead of the TAP output
sub _emit {
    my ($self, $text) = @_;
    print STDERR "$text\n";
    return $self;
}
```

#### Api Specification

##### Input

```perl
{
    text => { type => 'string', position => 0 },
}
```

##### Output

```perl
{ type => 'object', isa => 'Test::Log::Abstraction' }
```

#### Messages

None.  It never fails.

### i18n

Make one of this module's messages, in the logger's language.

#### Purpose

All the text that this module shows to people comes from here.  So the
text can be translated, or changed, without changing the code.

#### Args

- `$key` - the name of the message, such as `needs_pattern`.
- `\%args` - optional.  Values for the placeholders in the message.
`class` is filled in for you (the logger's class).  `count` chooses the
singular or plural form.  `gender` chooses a gender form.

#### How a Message Template Works

A template is a string.  `%{name}s` is replaced by the value called
`name`.  After the name you can use any `sprintf` format letter, for
example `%{count}d` or `%{ratio}.2f`.  `%%` gives one `%`.  A value
that is missing becomes the text `undef`, with no warning.  A value that
the format cannot show is written as it was given: text, infinity and NaN
for any number format, and a number too big for an integer format such as
`%d` or `%x`, which `sprintf` would turn into `-1`.

A template can also be a hash.  The keys are gender names (such as
`male`, `female`) or plural forms (`zero`, `one`, `two`, `few`,
`many`, `other`).  The values are templates, so they can be hashes too.
`other` is used when nothing else fits.  `zero` is used for a count of
0, if it is there.

```perl
{
    zero  => 'no messages',
    one   => '%{count}d message',
    other => '%{count}d messages',
}
```

#### Where the Template Is Found

The first one found is used:

- 1. Your `i18n` option, in the logger's language.
- 2. This module's messages, in the logger's language.
- 3. Your `i18n` option, in English.
- 4. This module's messages, in English.

If the key is not found anywhere, the key itself is returned.

#### Returns

The finished message, as a Perl character string.

#### Side Effects

None.

#### Example

```perl
# Inside a subclass
my $text = $self->i18n('needs_pattern', { method => 'like' });
# "Test::Log::Abstraction: like() needs a pattern"

# Your own message, with gender and plural forms.  i18n() is
# meant for subclasses, so call it from a method of your subclass.
my $logger = My::Logger->new(i18n => {
    en => {
        logged => {
            male => { one => 'He logged %{count}d line', other => 'He logged %{count}d lines' },
            other => 'They logged %{count}d lines',
        },
    },
});
# In a method of My::Logger:
$self->i18n('logged', { gender => 'male', count => 2 });    # 'He logged 2 lines'
```

#### Api Specification

##### Input

```perl
{
    key => { type => 'string', position => 0 },
    args => { type => 'hashref', optional => 1, position => 1 },
}
```

Domains: key - any string; undef renders as '', a reference as its
string form, and an unknown key is returned as it is.  args - a hash
reference; anything else is ignored.  count - a number selects a plural
form (0 uses 'zero' when present); anything else uses 'other'.
Placeholder values: any value.  With an integer format, `%d` and `%i`
show -2\*\*63 to 2\*\*63-1, and `%u`, `%o`, `%x`, `%X`, `%b` and `%c`
show 0 to 2\*\*64-1 (a negative number down to -2\*\*63 in two's
complement).  Leading zeros and a leading `+` are allowed, and '-0' is 0.
A value outside these ranges, text, infinity and NaN are shown as written.
(These limits are for a Perl with 64-bit integers.)

##### Output

```perl
{ type => 'string' }
```

#### Messages

None.  It never fails, for any key or arguments.

#### Pseudocode

```
language = the logger's language (for a class name: the configured one)
template = the first one found in the four places listed above
if no template was found, return the key
while the template is a hash:
    choose by gender, else by plural form, else 'other'
replace each %{name}format with sprintf(format, the value of name)
return the text
```

## Limitations

- **It accepts more than the real logger.**  The syslog names
(`warning`, `err`, `crit`, `emerg`, `panic`, `informational`) are
methods here, but not in [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) (checked up to version
0.41).  Code that calls them passes its tests, and then stops with an
error in production.
A `strict` option, which allows only the
real [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) methods, would be safer.
- **A misspelt level in `count()` is not caught.**  `count('wran')`
returns 0, so `is($logger->count('wran'), 0)` passes whatever was
logged.  Any name is accepted because ["AUTOLOAD"](#autoload) stores messages under
names that are not levels.  `has_level('wran')` fails, so the typo shows
there.  Prefer `empty()`, or `count()` with no level, when checking that
nothing was logged.
- **Messages are stored under the name that was called.**  See
["COMMON PITFALLS"](#common-pitfalls).  Your test must use the same name as the code under
test.
- **`level()` does not hide messages.**  [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) drops
messages below its level.  This module stores them all, which is usually
what a test wants.
- **Message text is not always the same as in [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction).**
`undef` becomes `undef` instead of being dropped, and hashes and arrays
are written out as data.  A test that compares the exact text may give a
different result with the real logger.
- **Mixed encodings in translated output.**  See ["ENCODING"](#encoding).
- **Internal methods are not locked.**  Methods whose names start
with `_`, and the subclass methods `_emit` and `i18n`, can be called by
any code.  Nothing checks the caller: a test helper should not need
compiled modules to do that.  Do not rely on them outside a subclass.
- **Many modules are needed.**  [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict),
[Params::Get](https://metacpan.org/pod/Params%3A%3AGet), [Readonly](https://metacpan.org/pod/Readonly), [Readonly::Values::Syslog](https://metacpan.org/pod/Readonly%3A%3AValues%3A%3ASyslog), and [autodie](https://metacpan.org/pod/autodie)
(with [IPC::System::Simple](https://metacpan.org/pod/IPC%3A%3ASystem%3A%3ASimple)) must be installed, for what is a small test
helper.  [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) is not used, because it loads
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction), and a test logger should not need that.
- **Simple translation system.**  [Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext) uses numbered
placeholders and has no gender forms.  Modules based on gettext need
compiled files.  Neither fits a small table with named placeholders, so
this module has its own.  Native speakers have not yet checked the
German, French and Chinese texts.
- **Slow patterns are not stopped.**  `like` and `unlike` run the
pattern against every stored message.  A pattern with nested quantifiers,
such as `qr/(a+)+$/`, can take a very long time on some messages.  This
module does not limit the time.
- **How long things take.**  `like()` and `has_level()` stop at
the first message that matches.  `unlike()` that passes, `count()` with
a level, and `messages()` look at every stored message, so their time
grows with the number of messages (about 0.1 to 0.25 microseconds a
message on a typical machine).  A log call costs about 3 microseconds.
For tests that log hundreds of thousands of messages, call `clear()`
between phases.
- **One process only.**  Messages are kept in the memory of the
logger object.  Messages logged in a child process (after `fork`) are not
seen by the parent.

## Diagnostics

Each method lists its messages under `MESSAGES`.  All messages can be
translated or changed; see ["i18n"](#i18n).

The text after `invalid argument:` explains what was wrong, and may show
the value that was given.  Other errors, warnings and notices repeat a name
you gave: a level name, a diag name, or a method name.  Every value repeated
like this is cut to 200 characters, and control characters in it (such as
a newline, or the escape character that starts a terminal control
sequence) are shown as `\xNN`.  In a character string, the C1 controls
U+0080 to U+009F are shown as `\xNN` too; in a byte string those bytes
are kept, because they are usually part of UTF-8 text.  So a hostile value cannot make an error
message enormous, add a forged `ok` line to the output, or control your
terminal.  An object whose text form (overloaded `""`) dies is shown in
Perl's plain form, such as `My::Class=HASH(0x55d0c8a1e2f8)`: the error
or warning you get is this module's, not the object's.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Test-Log-Abstraction/coverage/)

[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction), [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder), [Test::Most](https://metacpan.org/pod/Test%3A%3AMost)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

This section describes each method in the Z notation.  You do not need it
to use the module.  It is here so that the behaviour is exact.

### State

```
[TEXT, NAME, KEY, TEMPLATE, TAG, VALUE]
BOOL ::= true | false
SEVERITY == 0 .. 7
BUILTIN == { en, de, fr, zh }

severity : NAME ⇸ SEVERITY
lower : NAME → NAME
catalogue : TAG ⇸ (KEY ⇸ TEMPLATE)
render : seq VALUE → TEXT
─────────
dom catalogue = BUILTIN
∀ n : dom severity • lower n = n

Entry ≙ [ level : NAME; message : TEXT; fields : TEXT ⇸ VALUE ]

Rule ::= all | none | levels⟨⟨ℙ NAME⟩⟩ | atleast⟨⟨SEVERITY⟩⟩

Logger
  log       : seq Entry
  verbose   : BOOL
  threshold : SEVERITY
  lang      : TAG
  overrides : TAG ⇸ (KEY ⇸ TEMPLATE)
  rule      : Rule
  ─────────
  lang ∈ BUILTIN ∪ dom overrides
  ∀ e : ran log • e.level = lower e.level

ΔLogger ≙ [ Logger; Logger' | overrides' = overrides ∧ rule' = rule ]

printed : Logger × NAME → BOOL
─────────
∀ L : Logger; n : NAME •
  printed (L, n) = true ⇔
    L.verbose = true ∨ L.rule = all
    ∨ (∃ S : ℙ NAME • L.rule = levels S ∧ n ∈ S)
    ∨ (∃ t : SEVERITY • L.rule = atleast t ∧ n ∈ dom severity ∧ severity n ≤ t)
```

`severity` is the level table under ["Levels and how serious they are"](#levels-and-how-serious-they-are).
`lower` is Perl's `lc`.  `catalogue` is the built-in message table, and
`overrides` is the logger's `i18n` option; so a logger's language may be
one that only `overrides` has.  `render` turns a log call's arguments
into its message text (see the level methods' ["Args"](#args)).  `rule` is the
`diag` option, and `printed` says whether a stored message is also
printed.  `ΔLogger` means the method may change the log and the settings,
but never `overrides` or `rule`; `ΞLogger` means it changes nothing.

### New

```
New
  Logger'
  opts? : NAME ⇸ VALUE
  config : NAME ⇸ VALUE
  env : NAME ⇸ TEXT
  ─────────
  let get ≙ λ k : NAME • (if k ∈ dom opts? then opts? k else config k) •
    lower (get level) ∈ dom severity
    log' = ⟨⟩
    verbose' = (if verbose ∈ dom opts? then opts? verbose
                else env TEST_VERBOSE ∨ env VERBOSE)
    threshold' = severity (lower (get level))
    overrides' = (if i18n ∈ dom opts? then opts? i18n else ∅)
    rule' = rule_of (get diag)
    lang' = language (opts?, config, env, overrides')

Clone
  ΞLogger
  clone! : Logger
  ─────────
  clone!.log = log
  clone!.verbose = verbose
  clone!.threshold = threshold
  clone!.lang = lang
```

`config` is ["Default settings"](#default-settings) and `env` is `%ENV`.  `rule_of`
turns the `diag` option into a `Rule`, and fails (croaks) for anything
else.  `language` applies the order under ["Language of this module's
messages"](#language-of-this-module-s-messages): `lang`, then `country`, then (for `lang => 'auto'`) the
locale variables in `env`, then `config`; the result is the first two or
three letters, if `BUILTIN` or `overrides'` has that language, and
otherwise `en`.

`Clone` is `$logger->new()` with no options.  Options that are given
replace the matching values, as in `New`.

### Trace, Debug, Info, Notice, Warn, Error, Fatal, Critical, Alert, Emergency

```
Log
  ΔLogger
  name? : NAME
  args? : seq VALUE
  ─────────
  name? ∈ dom severity
  args? = ⟨⟩ ∧ severity name? ≤ severity warn ⇒ log' = log
  ¬ (args? = ⟨⟩ ∧ severity name? ≤ severity warn) ⇒
      log' = log ⁀ ⟨⟨ level ↦ name?, message ↦ render args? ⟩⟩
  verbose' = verbose ∧ threshold' = threshold ∧ lang' = lang
```

A stored entry is also printed exactly when `printed (θLogger, name?)`.

### Is\_Trace, Is\_Debug, Is\_Info, Is\_Notice, Is\_Warn, Is\_Error, Is\_Critical, Is\_Alert, Is\_Emergency

```
IsLevel
  ΞLogger
  name? : NAME
  result! : BOOL
  ─────────
  name? ∈ dom severity
  result! = true ⇔ severity name? ≤ threshold
```

### Autoload

```
Unknown
  ΔLogger
  name? : NAME
  args? : seq VALUE
  ─────────
  name? ∉ dom severity
  log' = log ⁀ ⟨⟨ level ↦ lower name?, message ↦ render args? ⟩⟩
  verbose' = verbose ∧ threshold' = threshold ∧ lang' = lang
```

The notice `no method 'name?'` is always printed.  The name in it is
escaped and cut, as described under ["DIAGNOSTICS"](#diagnostics); the stored `level`
is not.  A name in another case,
such as `INFO`, is not a method, so it comes here, and is stored as
`info`.

### Messages

```
Messages
  ΞLogger
  result! : seq Entry
  ─────────
  result! = log
```

### Clear

```
Clear
  ΔLogger
  ─────────
  log' = ⟨⟩
  verbose' = verbose ∧ threshold' = threshold ∧ lang' = lang
```

### Count

```
Count
  ΞLogger
  level? : NAME
  result! : ℕ
  ─────────
  result! = # (log ↾ { e : Entry | e.level = lower level? })

CountAll
  ΞLogger
  result! : ℕ
  ─────────
  result! = # log
```

### Like

```
Like
  ΞLogger
  pattern? : ℙ TEXT
  result! : BOOL
  ─────────
  result! = true ⇔ (∃ e : ran log • e.message ∈ pattern?)
```

### Unlike

```
Unlike
  ΞLogger
  pattern? : ℙ TEXT
  result! : BOOL
  ─────────
  result! = true ⇔ (∀ e : ran log • e.message ∉ pattern?)
```

### Has\_Level

```
HasLevel
  ΞLogger
  level? : NAME
  result! : BOOL
  ─────────
  result! = true ⇔ (∃ e : ran log • e.level = lower level?)
```

### Empty

```
Empty
  ΞLogger
  result! : BOOL
  ─────────
  result! = true ⇔ log = ⟨⟩
```

### Verbose

```
SetVerbose
  ΔLogger
  value? : BOOL
  result! : BOOL
  ─────────
  verbose' = value?
  result! = verbose'
  log' = log ∧ threshold' = threshold ∧ lang' = lang

GetVerbose
  ΞLogger
  result! : BOOL
  ─────────
  result! = verbose
```

### Level

```
SetLevel
  ΔLogger
  name? : NAME
  ─────────
  name? ∈ dom severity ⇒ threshold' = severity name?
  name? ∉ dom severity ⇒ threshold' = threshold
  log' = log ∧ verbose' = verbose ∧ lang' = lang

GetLevel
  ΞLogger
  result! : SEVERITY
  ─────────
  result! = threshold
```

### Flush

```
Flush
  ΞLogger
```

### Reopen

```
Reopen
  ΞLogger
```

### Lang

```
Lang
  ΞLogger
  result! : LANG
  ─────────
  result! = lang
```

### i18n

```
I18n
  ΞLogger
  key? : KEY
  result! : TEXT
  ─────────
  let find ≙ λ t : TAG •
      { m : (TAG ⇸ (KEY ⇸ TEMPLATE)) | m ∈ { overrides, catalogue }
          ∧ t ∈ dom m ∧ key? ∈ dom (m t) } •
    find lang ≠ ∅ ⇒ result! = fill (first (find lang) lang key?)
    find lang = ∅ ∧ find en ≠ ∅ ⇒ result! = fill (first (find en) en key?)
    find lang = ∅ ∧ find en = ∅ ⇒ result! = key?
```

`fill` chooses the gender or plural form and fills in the placeholders.
`first` takes `overrides` before `catalogue` when both have the key: the
`i18n` option is searched first in each language.

## State Diagram

A logger has two main states: **EMPTY** (no stored messages) and
**CAPTURING** (one or more stored messages).  Two settings, **verbose** and
**level**, can change in either state; they do not move the logger between
states.  Methods that only read or test (`like`, `count`, `is_debug`,
and so on) never change the state.

```perl
              new(%options)
              [check options; choose language,
               diag rule and level]
                    |
                    | invalid option
                    +----------------------> croak, no logger made
                    |
                    v
+-----------------------------------------+
|                 EMPTY                   |<----------------+
|  messages = ()                          |                 |
+-----------------------------------------+                 |
     |       ^                                              |
     |       | clear()                                      |
     +-------+ [nothing to delete; return the logger]       |
     |                                                      |
     | trace() ... emergency(), warning() ... panic()       | clear()
     | [store the message; print it if the diag rule        | [delete all
     |  or verbose allows; $@ and $! are kept.  With no     |  messages;
     |  arguments, warn() and above store nothing and stay  |  return the
     |  in EMPTY (or CAPTURING), as in Log::Abstraction]    |  logger]
     |                                                      |
     | wran() or any unknown method (AUTOLOAD)              |
     | [store under that name; always print                 |
     |  "no method 'wran'", the name escaped and cut to     |
     |  200 characters]                                     |
     v                                                      |
+-----------------------------------------+                 |
|               CAPTURING                 |-----------------+
|  messages = (m1, m2, ...)               |
+-----------------------------------------+
     |       ^
     |       | any level method, or an unknown method
     +-------+ [store one more message; maybe print it]

Changes allowed in BOTH states (the state stays the same):

  verbose(1) / verbose(0)   verbose on / off
                            [from now on: print every message / use
                             the diag rule]
  level('error')            level number = 3
                            [the is_* answers change; nothing is
                             hidden]
  level('bogus')            no change [warning; returns undef]

Read-only calls in BOTH states (the state stays the same):

  like, unlike, has_level, empty
                            [one TAP result; on failure, print the
                             messages that explain it]
  count, messages, lang, is_trace ... is_emergency, flush, reopen,
  i18n
                            [return a value only]
  DESTROY() called directly [does nothing; the logger stays]
  like(undef), has_level(undef), a bad argument, or any method
  called on something that is not a logger (the class name, undef,
  a plain reference, or another class's object)
                            [croak; no change]

On the class name, with no logger at all (see METHODS FOR
SUBCLASSES):

  i18n                      [return the text, in the configured
                             language]
  _emit                     [print the text; return the class name]

Copying (the original logger does not change):

  EMPTY     --- $logger->new(%options) ---> a new logger in EMPTY
  CAPTURING --- $logger->new(%options) ---> a new logger in CAPTURING
                [the new logger has copies of the messages, and the
                 same verbose and level, unless new values are given]

End:

  EMPTY or CAPTURING --- the last reference goes away ---> destroyed
                [DESTROY does nothing; nothing is stored or printed]
```

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
