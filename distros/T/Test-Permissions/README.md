## Name

Test::Permissions - Find out whether chmod can really take access away, so tests know when to skip

## Version

0.001.0

## Synopsis

```perl
    use Test::Most;
    use File::Temp qw(tempdir);
    use Test::Permissions qw(:revoke :guard :report);

    my $dir = tempdir(CLEANUP => 1);        # where the fixtures live
    diag(permissions_report($dir)); # once, for CPAN Testers reports

    SKIP: {
            skip why_not('read', $dir), 1 unless can_revoke_read($dir);

            with_revoked(read => "$dir/fixture", sub {
                    ok(!open(my $fh, '<', "$dir/fixture"), 'unreadable file is refused');
            });     # the mode is restored, even if the block dies
    }

    SKIP: {
            skip_unless_can_revoke('search', 1, $dir);
            ...
    }

    done_testing();
```

## Description

Test suites often need to know whether `chmod` really takes access away,
so they can skip tests that rely on an unreadable file or an unsearchable
directory.  The usual guess, `skip ... if $> == 0`, is wrong on:

- Windows, where `chmod` only sets the read-only attribute;
- `fakeroot`, and containers where a non-root user holds
`CAP_DAC_OVERRIDE`;
- filesystems that ignore mode bits (FAT, some SMB/NFS/FUSE mounts,
Cygwin `noacl` mounts);
- root in a user namespace, where root may _not_ be able to bypass
modes;
- root on an NFS export with `root_squash`, where root is treated
as "nobody".

Test::Permissions does not guess.  It tries the operation on a scratch
file in the directory you care about, and reports what actually happened.
Results are cached per process.

Seven kinds of access can be probed:

```
    Kind     Question                                          Restricted mode
    read     can a file be made unreadable?                    file 0
    write    can a file be made unwritable?                    file 0400
    create   can a directory be made to refuse new files?      directory 0500
    search   can a directory be made unsearchable (stat of a   directory 0
             file inside it fails)?
    exec     can a script be made unrunnable?                  file 0600
    delete   can a directory be made to keep its files?        directory 0500
    sticky   does the sticky bit stop one user deleting        directory 01777
             another user's file?
```

What to expect (your tests must not rely on these; that is the point):

```
    Environment                        read write create search exec delete sticky
    Linux/BSD/macOS, normal user        1    1     1      1      1    1      0 (a)
    Unix root, or CAP_DAC_OVERRIDE      0    0     0      0      1(b) 0      1
    fakeroot                            0    0     0      0      1(b) 0      0
    Windows (NTFS)                      0    1     0 (c)  0      0    0 (c)  0
    FAT or a mount that ignores modes   0    0     0      0      0    0      0
    a noexec mount                      .    .     .      .      0    .      .

    (a) the sticky probe must act as two users, so it needs root
    (b) even root cannot run a file that has no execute bit at all
    (c) Windows ignores the read-only attribute on directories
```

### Which Directory to Probe

The answer depends on the filesystem, so pass the directory your fixtures
live in (usually your own `tempdir`).  If you pass nothing, the probe
runs in `File::Spec->tmpdir`, which may be on a different filesystem
from your fixtures (a `tmpfs`, for example) and give a different answer.

### How a Probe Works

Each probe creates a fresh directory `P` inside the target directory and
then:

- 1. **Setup**: creates the scratch objects with explicit modes, so the
answer does not depend on your `umask`.
- 2. **Baseline**: does the operation while it is allowed.  If that
fails, the filesystem cannot tell us anything, and the answer is 0.
- 3. **Restrict**: `chmod`s to the restricted mode and checks, with
`stat`, that the owner's permission bits (for `sticky`: all the mode
bits) really changed.  If not (this is what happens on Windows), the
answer is 0.
- 4. **Attempt**: does the operation again.  It must fail with
`EACCES` or `EPERM` for the answer to be 1.
- 5. **Restore and clean up**: always, even if an earlier step failed.
Nothing is left in the target directory.

A probe never dies and never warns: anything that goes wrong becomes an
answer of 0, and ["why\_not(kind, dir)"](#why_not-kind-dir) tells you why.  Only mistakes in
the call itself (an unknown kind, a directory that does not exist) croak.

### Paths With Non-ASCII Characters

Directory and file names are used exactly as perl's own file functions
use them: as byte strings.  On Unix, pass the same (usually UTF-8
encoded) bytes you would pass to `open`.  On Windows, perl's file
functions use the ANSI code page, so a name with characters outside it
cannot be found, and the call croaks with `error_not_a_directory` or
`error_no_such_path`.  Names in messages are shown as they are, except
that control and bidirectional-override characters are escaped.

### Taint Mode

The functions work under `perl -T`.  The directory you pass is checked
with `-d`, and its canonical path is then untainted, because the probe
only creates its own scratch directory inside it.  `with_revoked`
likewise untaints the path you give it, because changing its mode is what
you asked for.  The `exec` probe runs its script with `PATH`, `IFS`,
`CDPATH`, `ENV` and `BASH_ENV` removed from the environment.

## Subroutines/Methods

Nothing is exported by default.  Import what you need by name, or use a
tag:

```
    :revoke   can_revoke_* , can_revoke, why_not, skip_unless_can_revoke
    :acl      acl_denies
    :guard    with_revoked
    :report   permissions_report
    :all      all of these, plus clear_cache, set_cache_scope, set_messages
```

Every function that takes `dir` accepts it in any of these forms:

```perl
    f()                  # dir is File::Spec->tmpdir
    f($dir)
    f(dir => $dir)
    f({ dir => $dir })
```

An object that stringifies (such as a [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object) is accepted
wherever a directory or path name is.

### Can\_Revoke\_Read(dir)

#### Purpose

Find out whether a file with mode 0 refuses `open '<'`: that is,
whether `chmod` can make a file unreadable in `dir`.  The same as
`can_revoke('read', $dir)`.

#### Arguments

- `dir` - optional.  The directory to probe in.  It must exist
and be a directory.  Default: `File::Spec->tmpdir`.

#### Returns

1 if `chmod` can take that access away in `dir`, otherwise 0.  Never
undef.

#### Side Effects

- The first call for a kind and directory creates and removes a
probe directory inside `dir`.  Later calls use the cache and do not touch
the filesystem.
- Never dies or warns because of what it finds; see
["FAILURE POLICY"](#failure-policy).
- Does not change the caller's `$@`, `$!` or `umask`.

#### Usage Example

```
    SKIP: {
            skip 'chmod cannot make a file unreadable here', 1
                    unless Test::Permissions::can_revoke_read($dir);
            ...
    }
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

Errors (the call dies):

```
    '$dir' is not a directory                     (error_not_a_directory)
        dir does not exist, or is not a directory.
        What to do: pass the directory your fixtures live in.

    Too many arguments: expected at most 1, got N (error_too_many_arguments)
        More than one positional argument was given.
        What to do: pass only the directory.

    (an error from Params::Validate::Strict or Params::Get)
        dir is not a string (for example an array reference), is empty,
        or the named form has an unknown key.
```

The reason for a 0 answer is available from ["why\_not(kind, dir)"](#why_not-kind-dir), which
lists every `reason_*` message.

### Can\_Revoke\_Write(dir)

#### Purpose

Find out whether a file with mode 0400 refuses `open '>>'`: that
is, whether `chmod` can make a file unwritable in `dir`.  The same as
`can_revoke('write', $dir)`.

#### Arguments

- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

1 or 0, never undef.

#### Side Effects

As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Usage Example

```perl
    SKIP: {
            skip 'chmod cannot make a file read-only here', 1
                    unless Test::Permissions::can_revoke_write($dir);
            chmod 0400, $file;
            ok(!open(my $fh, '>>', $file), 'read-only file is refused');
            chmod 0600, $file;
    }
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

The same as ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

### Can\_Revoke\_Create(dir)

#### Purpose

Find out whether a directory with mode 0500 refuses `open '>'` of a
new file in it: that is, whether `chmod` can stop files being created
in a directory in `dir`.  The same as `can_revoke('create', $dir)`.

Note: in App-makefilepl2cpanfile's private copy of this module, this
question was called `can_revoke_write`.  ["can\_revoke\_write(dir)"](#can_revoke_write-dir) now
asks about a file's own write bit.

On Windows the answer is 0 with `reason_not_enforced`: Windows ignores
the read-only attribute on directories.

#### Arguments

- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

1 or 0, never undef.

#### Side Effects

As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Usage Example

```
    SKIP: {
            skip Test::Permissions::why_not('create', $dir), 1
                    unless Test::Permissions::can_revoke_create($dir);
            chmod 0500, $outdir;
            ok(!eval { write_report($outdir) }, 'cannot write the report');
            chmod 0700, $outdir;
    }
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

The same as ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

### Can\_Revoke\_Search(dir)

#### Purpose

Find out whether a directory with mode 0 makes `stat` of a file inside
it fail: that is, whether `chmod` can make a directory in `dir`
unsearchable.  The same as `can_revoke('search', $dir)`.

#### Arguments

- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

1 or 0, never undef.

#### Side Effects

As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Usage Example

```
    SKIP: {
            skip 'chmod cannot hide a directory here', 1
                    unless Test::Permissions::can_revoke_search($dir);
            chmod 0, $subdir;
            ok(!-e "$subdir/file", 'file inside is hidden');
            chmod 0700, $subdir;
    }
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

The same as ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

### Can\_Revoke\_Exec(dir)

#### Purpose

Find out whether a script with mode 0600 refuses to run: that is, whether
`chmod` can take away the execute bit in `dir`.  The probe runs a
two-line `/bin/sh` script with `system`, so it needs `/bin/sh`, and a
filesystem not mounted `noexec`.  The same as `can_revoke('exec', $dir)`.

Unlike the other kinds, the answer is usually 1 even for root: root can
run a file only if at least one of its execute bits is set.

#### Arguments

- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

1 or 0, never undef.

#### Side Effects

As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir); also starts two short-lived processes.

#### Usage Example

```
    SKIP: {
            skip Test::Permissions::why_not('exec', $dir), 1
                    unless Test::Permissions::can_revoke_exec($dir);
            chmod 0600, $hook;
            ok(!run_hook($hook), 'a hook without the execute bit is not run');
    }
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

The same as ["can\_revoke\_read(dir)"](#can_revoke_read-dir).  On a `noexec` mount, or without
`/bin/sh`, the reason is `reason_baseline_failed`.

### Can\_Revoke\_Delete(dir)

#### Purpose

Find out whether a directory with mode 0500 refuses `unlink` of a file
in it: that is, whether `chmod` can stop files being deleted from a
directory in `dir`.  The same as `can_revoke('delete', $dir)`.

#### Arguments

- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

1 or 0, never undef.

#### Side Effects

As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Usage Example

```
    SKIP: {
            skip Test::Permissions::why_not('delete', $dir), 1
                    unless Test::Permissions::can_revoke_delete($dir);
            chmod 0500, $spool;
            ok(!eval { purge($spool) }, 'purge reports the failure');
            chmod 0700, $spool;
    }
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

The same as ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

### Can\_Revoke\_Sticky(dir)

#### Purpose

Find out whether the sticky bit works in `dir`: in a directory with mode
01777, can one user be stopped from deleting another user's file?  The
same as `can_revoke('sticky', $dir)`.

This needs two users, so the probe only runs as root (real and effective
uid 0), and not on Windows.  It gives its file to uid 65534 and tries to
delete it as uid 65533, by setting `$>` for the moment of the
`unlink`.  Anywhere else the answer is 0 with `reason_needs_root`.

#### Arguments

- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

1 or 0, never undef.

#### Side Effects

As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).  While it runs, the process briefly
changes its effective uid and its working directory; both are restored
before it returns.

#### Usage Example

```
    SKIP: {
            skip Test::Permissions::why_not('sticky', $dir), 1
                    unless Test::Permissions::can_revoke_sticky($dir);
            ...
    }
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

The same as ["can\_revoke\_read(dir)"](#can_revoke_read-dir).  When not running as root, the
reason is `reason_needs_root`.

### Can\_Revoke(kind, Dir)

#### Purpose

The general form of the `can_revoke_*` functions: answer the question
for the kind of access named by `kind`.

#### Arguments

- `kind` - required.  One of `read`, `write`, `create`,
`search`, `exec`, `delete` or `sticky`.
- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

Positional (`can_revoke('read', $dir)`), named
(`can_revoke(kind => 'read', dir => $dir)`) and hash reference
(`can_revoke({ kind => 'read' })`) forms are all accepted.

#### Returns

1 or 0, never undef.

#### Side Effects

As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Usage Example

```perl
    for my $kind (qw(read search)) {
            SKIP: {
                    skip "cannot revoke $kind access", 1
                            unless Test::Permissions::can_revoke($kind, $dir);
                    ...
            }
    }
```

#### Api Specification

##### Input

```perl
    {
            kind => {
                    type     => 'string',
                    memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete', 'sticky' ],
                    position => 0,
            },
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 1,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

Errors (the call dies):

```perl
    Unknown access kind '$kind'; expected one of: read, write, create,
    search, exec, delete, sticky                  (error_unknown_kind)
        What to do: use one of the listed kinds.

    '$dir' is not a directory                     (error_not_a_directory)
        What to do: pass an existing directory.

    Too many arguments: expected at most 2, got N (error_too_many_arguments)

    (an error from Params::Validate::Strict or Params::Get)
        kind is missing or not a string, dir is not a string or is empty,
        or the named form has an unknown key.
```

### Why\_Not(kind, Dir)

#### Purpose

Say why the answer for `kind` in `dir` is 0, in words suitable for a
skip message.

#### Arguments

The same as ["can\_revoke(kind, dir)"](#can_revoke-kind-dir).

#### Returns

undef when the answer is 1.  Otherwise a non-empty string: one of the
`reason_*` messages below.

#### Side Effects

Runs the probe if it has not run yet for this kind and directory, exactly
as ["can\_revoke(kind, dir)"](#can_revoke-kind-dir) would, and caches the result.

#### Usage Example

```perl
    SKIP: {
            my $why = Test::Permissions::why_not('search', $dir);
            skip $why, 2 if defined $why;
            ...
    }
```

#### Api Specification

##### Input

```perl
    {
            kind => {
                    type     => 'string',
                    memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete', 'sticky' ],
                    position => 0,
            },
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 1,
            },
    }
```

##### Output

```perl
    { type => 'string', optional => 1 }
```

#### Messages

Errors: the same as ["can\_revoke(kind, dir)"](#can_revoke-kind-dir).

Reasons (returned, never thrown or warned).  `$dir` is the canonical
path of the directory; `$error` is the system's error text, in the
current locale (so a reason may mix these English texts, or your own from
["set\_messages(%overrides)"](#set_messages-overrides), with another language).

```
    chmod cannot revoke $kind access in '$dir' (running as root, or the
    filesystem ignores permissions)               (reason_not_enforced)
        The operation still worked after chmod.  You are root, hold
        CAP_DAC_OVERRIDE, run under fakeroot, or the filesystem ignores
        modes.  On Windows, create and delete give this reason because
        Windows ignores the read-only attribute on directories.
        What to do: nothing; skip the test.  To run it, run the suite as
        an ordinary user on a filesystem that honours modes.

    chmod did not set mode $wanted in '$dir' (got $got)
                                                  (reason_chmod_ignored)
        chmod "worked" but the permission bits did not change.  This is
        Windows, or a FAT or noacl mount.
        What to do: nothing; skip the test.

    $kind access fails in '$dir' even when it is allowed: $error
                                                  (reason_baseline_failed)
        The operation failed before any permission was removed, so the
        probe learnt nothing.  The filesystem may be read-only or broken;
        for exec, it may be mounted noexec, or /bin/sh may be missing.
        What to do: check the directory and the filesystem.

    $kind access in '$dir' failed for a reason other than permissions: $error
                                                  (reason_other_error)
        After chmod the operation failed, but not with EACCES or EPERM
        (for example ENOSPC).
        What to do: check the error; the directory may be full or odd.

    Could not set up the $kind probe in '$dir': $error
                                                  (reason_setup_failed)
        The probe could not create its scratch files, usually because you
        cannot write to dir.
        What to do: pass a directory you can write to.

    The sticky probe in '$dir' must act as two users, which needs root
    (not Windows)                                 (reason_needs_root)
        Only the sticky probe gives this reason.
        What to do: nothing; run the suite as root to probe it.

    $reason; also could not clean up '$probe_dir': $error
                                                  (reason_cleanup_failed)
        Restoring the modes or removing the probe directory failed, so
        the answer is 0 whatever the probe found.  $reason is one of the
        reasons above, or, if the probe itself succeeded, the text of
        reason_probe_succeeded:

    chmod revoked $kind access in '$dir'          (reason_probe_succeeded)
        Only ever seen as the first part of reason_cleanup_failed.
        What to do: remove $probe_dir by hand; it is also removed when
        the process exits.
```

Paths and error texts in reasons have control characters and Unicode
direction-override characters replaced by `\x{..}` escapes.

### Skip\_Unless\_Can\_Revoke(kind, Count, Dir)

#### Purpose

Skip the rest of the enclosing `SKIP:` block, with the reason from
["why\_not(kind, dir)"](#why_not-kind-dir), when `chmod` cannot revoke `kind` access.

#### Arguments

- `kind` - required.  As for ["can\_revoke(kind, dir)"](#can_revoke-kind-dir).
- `count` - required.  The number of tests in the block, as for
`Test::More::skip`.  A whole number, 1 or more.
- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

Nothing, when the answer is 1.  When the answer is 0 it does not return:
it records `count` skipped tests and leaves the enclosing `SKIP:` block,
exactly as a direct `skip` call would.

#### Side Effects

- Runs the probe, as ["can\_revoke(kind, dir)"](#can_revoke-kind-dir) does.
- When the answer is 0, records `count` skipped tests.  With
[Test::More](https://metacpan.org/pod/Test%3A%3AMore) (or anything else that loads [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder)) it calls
`Test::More::skip`.  In a [Test2::V0](https://metacpan.org/pod/Test2%3A%3AV0) suite, which does not load
Test::Builder, it records the skips through [Test2::API](https://metacpan.org/pod/Test2%3A%3AAPI) instead.
- Must be called inside a `SKIP:` block, like `Test::More::skip`.
Outside one, perl dies with `Label not found for "last SKIP"`.

#### Usage Example

```perl
    SKIP: {
            Test::Permissions::skip_unless_can_revoke('search', 2, $dir);
            chmod 0, $subdir;
            ok(!-e "$subdir/file", 'file hidden');
            ok(!opendir(my $dh, $subdir), 'directory unreadable');
            chmod 0700, $subdir;
    }
```

#### Api Specification

##### Input

```perl
    {
            kind => {
                    type     => 'string',
                    memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete', 'sticky' ],
                    position => 0,
            },
            count => {
                    type     => 'integer',
                    min      => 1,
                    position => 1,
            },
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 2,
            },
    }
```

##### Output

```perl
    { type => 'void' }
```

Returns nothing (an empty list) when the answer is 1.

#### Messages

Errors: the same as ["can\_revoke(kind, dir)"](#can_revoke-kind-dir), plus an error from
Params::Validate::Strict when `count` is missing, not a whole number, or
less than 1.

The skip message is one of the reasons listed under
["why\_not(kind, dir)"](#why_not-kind-dir).

### Acl\_Denies(kind, Path)

#### Purpose

Find out whether something other than the mode bits - usually an access
control list - denies you `kind` access to an existing `path`, even
though its mode bits allow it.  Use it to skip or explain a test that
fails because of a fixture's ACL, not its mode.

It compares what the mode bits say (for your effective uid and groups)
with what the system says, using `access(2)` (perl's `-r`, `-w` and
`-x` under `use filetest 'access'`), which takes ACLs into account.  It
does not open, change or run `path`.

#### Arguments

- `kind` - required.  `read`, `write` or `exec` (for a
directory, `exec` means search).
- `path` - required.  An existing file or directory.

#### Returns

1 if the mode bits allow the access but the system denies it, otherwise 0
(including when the mode bits themselves deny it).

#### Side Effects

None.  It is not cached: each call looks at `path` again.

Besides ACLs, a read-only mount, an immutable flag or a mandatory access
control policy (SELinux, AppArmor) can also make it return 1.  On Windows,
perl's file tests do not consult ACLs, so it returns 0.

#### Usage Example

```perl
    SKIP: {
            skip "an ACL denies reading $fixture", 1
                    if Test::Permissions::acl_denies(read => $fixture);
            ok(load($fixture), 'fixture loads');
    }
```

#### Api Specification

##### Input

```perl
    {
            kind => {
                    type     => 'string',
                    memberof => [ 'read', 'write', 'exec' ],
                    position => 0,
            },
            path => {
                    type     => 'string',
                    min      => 1,
                    position => 1,
            },
    }
```

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

Errors (the call dies):

```
    Unknown access kind '$kind'; expected one of: read, write, exec
                                                  (error_unknown_kind)

    '$path' does not exist                        (error_no_such_path)
        What to do: pass an existing file or directory.

    Too many arguments: expected at most 2, got N (error_too_many_arguments)

    (an error from Params::Validate::Strict or Params::Get)
```

### With\_Revoked(kind, Path, Code)

#### Purpose

Take `kind` access away from `path`, run `code`, and put the mode back
\- always, even if `code` dies.  It uses the same restricted modes as the
probes, so a test written as

```perl
    SKIP: {
            skip_unless_can_revoke('read', 1, $dir);
            with_revoked(read => $file, sub { ok(!load($file), 'refused') });
    }
```

cannot leave an unreadable file behind for the next test, or for
`File::Temp`'s cleanup.

#### Arguments

- `kind` - required.  `read` (mode 0), `write` (0400) or
`exec` (0600), which apply to a file; or `create` (0500), `search`
(0) or `delete` (0500), which apply to a directory.
- `path` - required.  An existing file (for read, write, exec) or
directory (for create, search, delete).
- `code` - required.  A code reference, called with no arguments.

#### Returns

Whatever `code` returns, in the same (list, scalar or void) context.  If
`code` dies, the mode is restored and the exception is passed on
unchanged.

#### Side Effects

- Changes the mode of `path` while `code` runs, then restores the
mode it had before.
- Does not check that `chmod` really takes the access away: use
["can\_revoke(kind, dir)"](#can_revoke-kind-dir) (or `skip_unless_can_revoke`) first.
- Under taint mode, `path` is untainted; see ["Taint mode"](#taint-mode).

#### Usage Example

```perl
    my $content = Test::Permissions::with_revoked(search => $dir, sub {
            return eval { read_config("$dir/app.conf") };
    });
    ok(!defined $content, 'config in an unsearchable directory is not read');
```

#### Api Specification

##### Input

```perl
    {
            kind => {
                    type     => 'string',
                    memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete' ],
                    position => 0,
            },
            path => {
                    type     => 'string',
                    min      => 1,
                    position => 1,
            },
            code => {
                    type     => 'coderef',
                    position => 2,
            },
    }
```

##### Output

Whatever `code` returns; it is not checked.

#### Messages

Errors (the call dies):

```
    Unknown access kind '$kind'; expected one of: read, write, create,
    search, exec, delete                          (error_unknown_kind)
        sticky is not accepted: it does not take the owner's access away.

    '$path' does not exist                        (error_no_such_path)

    '$path' is not a directory                    (error_not_a_directory)
        create, search and delete apply to a directory.

    '$path' is a directory; $kind access is revoked on a file
                                                  (error_not_a_file)
        read, write and exec apply to a file.

    Could not chmod '$path' to $mode: $error      (error_chmod_failed)
        code was not run.
        What to do: check that you own path.

    Could not restore mode $mode on '$path': $error
                                                  (error_restore_failed)
        code ran (and any exception it threw is lost), but the old mode
        could not be put back.
        What to do: fix the mode by hand.

    (an error from Params::Validate::Strict or Params::Get)
        For example, code is not a code reference.

    (anything code dies with, unchanged)
```

### Permissions\_Report(dir)

#### Purpose

Describe, in a few lines, what `chmod` can revoke in `dir`: every kind,
with the reason for each 0.  Print it once with `diag` (or `note`) so
that a CPAN Testers report shows the environment the tests ran in.

#### Arguments

- `dir` - optional.  As for ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

#### Returns

A string of lines, ending without a newline:

```
    Test::Permissions 0.001.0 in '/tmp/abc' (effective uid 1000):
      read: yes
      ...
      sticky: no - The sticky probe in '/tmp/abc' must act as two users, ...
```

#### Side Effects

Probes every kind that is not already cached for `dir`, as
["can\_revoke(kind, dir)"](#can_revoke-kind-dir) would.

#### Usage Example

```
    diag(Test::Permissions::permissions_report($dir));
```

#### Api Specification

##### Input

```perl
    {
            dir => {
                    type     => 'string',
                    optional => 1,
                    min      => 1,
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'string', min => 1 }
```

#### Messages

Errors: the same as ["can\_revoke\_read(dir)"](#can_revoke_read-dir).

The lines come from the messages `report_header` (arguments: version,
directory, effective uid), `report_yes` (kind) and `report_no` (kind,
reason), which ["set\_messages(%overrides)"](#set_messages-overrides) can translate.

### Clear\_Cache()

#### Purpose

Forget every answer, so the next call probes again.  This is mainly for
the module's own tests, and for a directory whose permissions or mount
have changed since it was probed.

#### Arguments

None.

#### Returns

Nothing.

#### Side Effects

Empties the cache.

#### Usage Example

```
    Test::Permissions::clear_cache();
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'void' }
```

#### Messages

None.

### Set\_Cache\_Scope(scope)

#### Purpose

Choose how answers are shared between directories.

- `directory` (the default) - each directory is probed on its own.
This is always right, because ACLs, bind mounts and mount options can
differ between directories on one device.
- `device` - directories on the same device (the same `st_dev`)
share answers.  A suite that makes a new `tempdir` for every test can
use this to probe once instead of once per directory, when it knows its
directories are alike.  The reason text names the first directory probed
on the device.

#### Arguments

- `scope` - required.  `directory` or `device`.

#### Returns

Nothing.

#### Side Effects

Applies to later calls.  Answers already cached under the other scope
stay in the cache but are not used.

#### Usage Example

```
    Test::Permissions::set_cache_scope('device');
```

#### Api Specification

##### Input

```perl
    {
            scope => {
                    type     => 'string',
                    memberof => [ 'directory', 'device' ],
                    position => 0,
            },
    }
```

##### Output

```perl
    { type => 'void' }
```

#### Messages

Errors (the call dies): an error from Params::Validate::Strict when scope
is missing or not one of the two names.

### Set\_Messages(%Overrides)

#### Purpose

Replace message texts by key, for example to translate them.

#### Arguments

Pairs of message key and text, as a list or a hash reference.  The keys
are those listed under MESSAGES for each function (`error_*`, `reason_*`
and `report_*`).  Each text is a `sprintf` format taking the same
arguments, in the same order, as the default text.

#### Returns

Nothing.

#### Side Effects

- Changes the texts for the rest of the process.
- Reasons are worded when a probe runs, so answers already in the
cache keep their old wording until ["clear\_cache()"](#clear_cache).
- All pairs are checked before any is applied: if one is invalid,
nothing changes.
- A text with more or fewer `%s` than the default does not warn:
missing arguments are empty and extra ones are ignored.

#### Usage Example

```perl
    Test::Permissions::set_messages(
            reason_not_enforced => q{chmod ne peut pas retirer l'acces %s dans '%s'},
    );
```

#### Api Specification

##### Input

```perl
    {
            error_unknown_kind       => { type => 'string', min => 1, optional => 1 },
            error_not_a_directory    => { type => 'string', min => 1, optional => 1 },
            error_not_a_file         => { type => 'string', min => 1, optional => 1 },
            error_no_such_path       => { type => 'string', min => 1, optional => 1 },
            error_unknown_message    => { type => 'string', min => 1, optional => 1 },
            error_too_many_arguments => { type => 'string', min => 1, optional => 1 },
            error_chmod_failed       => { type => 'string', min => 1, optional => 1 },
            error_restore_failed     => { type => 'string', min => 1, optional => 1 },
            reason_not_enforced      => { type => 'string', min => 1, optional => 1 },
            reason_chmod_ignored     => { type => 'string', min => 1, optional => 1 },
            reason_baseline_failed   => { type => 'string', min => 1, optional => 1 },
            reason_other_error       => { type => 'string', min => 1, optional => 1 },
            reason_setup_failed      => { type => 'string', min => 1, optional => 1 },
            reason_cleanup_failed    => { type => 'string', min => 1, optional => 1 },
            reason_probe_succeeded   => { type => 'string', min => 1, optional => 1 },
            reason_needs_root        => { type => 'string', min => 1, optional => 1 },
            report_header            => { type => 'string', min => 1, optional => 1 },
            report_yes               => { type => 'string', min => 1, optional => 1 },
            report_no                => { type => 'string', min => 1, optional => 1 },
    }
```

##### Output

```perl
    { type => 'void' }
```

#### Messages

Errors (the call dies, and no text is changed):

```perl
    Unknown message key '$key'                    (error_unknown_message)
        What to do: use a key listed under MESSAGES.

    (an error from Params::Validate::Strict or Params::Get)
        A text is empty or not a string, or the arguments are not pairs.
```

## Failure Policy

- **Caller errors croak**: an unknown kind, a `dir` that is not an
existing directory, a `path` that does not exist, bad arguments
(reported by Params::Validate::Strict or Params::Get), or an unknown
message key.  `with_revoked` also croaks if it cannot change or restore
the mode it was asked to change.
- **Probe errors never escape.**  Anything that goes wrong inside a
probe becomes a 0 answer with a reason.  A helper whose job is to decide
whether to skip must never be the thing that fails your test file.
- **No warnings.**  Many suites run under [Test::Warnings](https://metacpan.org/pod/Test%3A%3AWarnings) or `-W`,
so a warning would itself fail them.  Use ["why\_not(kind, dir)"](#why_not-kind-dir) for
diagnostics.
- A failed restore or cleanup makes the answer 0, and is added to
the reason (`reason_cleanup_failed`).

## Limitations

- Results are per directory (or per device, see
["set\_cache\_scope(scope)"](#set_cache_scope-scope)), per effective user and groups, and per
process.
- A directory whose permissions or mount change after the first
call keeps its cached answer until ["clear\_cache()"](#clear_cache).
- Probing needs write access to `dir`: the probe creates a scratch
directory there.  Without it the answer is 0 (`reason_setup_failed`).
- The probes change only mode bits.  ["acl\_denies(kind, path)"](#acl_denies-kind-path)
detects an ACL that denies access to an existing path, but no probe
creates ACLs.
- The mode check after `chmod` compares the owner's permission
bits (all bits for `sticky`), because the probe runs as the owner of its
scratch files, and because perl on Windows reports a read-only file as
0444.
- The `sticky` probe needs root, and assumes that uids 65533 and
65534 can own files.  In a user namespace that maps only one uid (such as
`unshare -r`), giving the file away fails and the answer is 0 with
`reason_setup_failed`.
- Reasons embed the system's error text in the current locale.
- Needs perl 5.26 or later, because Params::Validate::Strict does.

## See Also

[Test::More](https://metacpan.org/pod/Test%3A%3AMore), [Test2::V0](https://metacpan.org/pod/Test2%3A%3AV0), [Test::Warnings](https://metacpan.org/pod/Test%3A%3AWarnings), [File::Temp](https://metacpan.org/pod/File%3A%3ATemp),
[filetest](https://metacpan.org/pod/filetest).

## Support

This module is provided as-is without any warranty.

Please report bugs and feature requests at
[https://github.com/nigelhorne/Test-Permissions/issues](https://github.com/nigelhorne/Test-Permissions/issues).

## Author

Nigel Horne <njh@nigelhorne.com>

## State Diagram

The cache, for one key: a kind, the effective uid and groups, and the
canonical directory (or, with the `device` scope, its device).
`can_revoke`, `can_revoke_*`, `why_not`, `skip_unless_can_revoke` and
`permissions_report` are all "queries".  A call that croaks does not
change the state.

```
                       query: probe, answer 1
        +---------+ ---------------------------> +------------+
        |  EMPTY  |                              | CACHED_YES | --+ query: no probe
        +---------+ ---------------------------> +------------+ <-+
          ^  ^  ^      query: probe, answer 0          |
          |  |  |                                      |
          |  |  +------------- clear_cache ------------+
          |  |                                      +-----------+
          |  +-------------- clear_cache ---------- | CACHED_NO | --+ query: no probe
          |                                         +-----------+ <-+
          +-- clear_cache (from EMPTY: no change)
```

There is no edge between CACHED\_YES and CACHED\_NO: a cached answer stays
until `clear_cache`, even if the environment changes.  `set_messages`
changes no state; a cached reason keeps the wording it was given when the
probe ran.  `set_cache_scope` and a change of effective uid or groups do
not change any key's state; they change which key later queries use.

## Formal Specification

The specification below uses Z notation.  The English sections above are
the normative description for everyday use.

```
    [PATH, ERRNO, CHAR, UID, GID, DEV]
    Kind   ::= read | write | create | search | exec | delete | sticky
    Answer == { 0, 1 }
    DENIED == { EACCES, EPERM }
    Reason == seq₁ CHAR
    Scope  ::= directory | device

    -- Outcome of one probe step.
    Outcome ::= ok | failed⟨⟨ERRNO⟩⟩ | threw

    restricted : Kind → ℕ
    restricted = { read ↦ 0, write ↦ 0400, create ↦ 0500, search ↦ 0,
                   exec ↦ 0600, delete ↦ 0500, sticky ↦ 01777 }
    bits : Kind → ℕ
    bits = (λ k : Kind • 0700) ⊕ { sticky ↦ 07777 }

    Env ≙ [ ruid, euid : UID; egids : 𝔽 GID; windows : 𝔹 ]
    precondition : Kind × Env → 𝔹
    precondition(k, e) ⇔ k ≠ sticky ∨ (e.ruid = 0 ∧ e.euid = 0 ∧ ¬ e.windows)

    Probe
      kind? : Kind
      dir?  : PATH
      env   : Env
      setup, baseline, attempt, cleanup : Outcome
      gotMode : ℕ
      modeSet : 𝔹
      answer! : Answer
      reason! : Reason ∪ {⊥}
      ---------------------------------------------
      modeSet ⇔ gotMode ∧ bits(kind?) = restricted(kind?) ∧ bits(kind?)
      answer! = 1 ⇔ precondition(kind?, env)
                    ∧ setup = ok ∧ baseline = ok ∧ modeSet
                    ∧ (∃ e : DENIED • attempt = failed(e))
                    ∧ cleanup = ok
      answer! = 1 ⇔ reason! = ⊥

    Key   == Kind × UID × 𝔽 GID × (PATH ∪ DEV)
    Cache == Key ⇸ Answer × (Reason ∪ {⊥})
    scope : Scope

    key : Kind × Env × PATH → Key
    key(k, e, p) = (k, e.euid, e.egids, if scope = device then dev(p) else canon(p))

    CanRevoke
      ΔCache ; Probe
      ---------------------------------------------
      key(kind?, env, dir?) ∈ dom cache  ⇒ cache' = cache
                                           ∧ answer! = first(cache key(kind?, env, dir?))
      key(kind?, env, dir?) ∉ dom cache  ⇒ cache' = cache ∪ { key(kind?, env, dir?) ↦ (answer!, reason!) }

    WhyNot
      ΞCache after CanRevoke
      why! : Reason ∪ {⊥}
      ---------------------------------------------
      why! = second(cache key(kind?, env, dir?))

    SkipUnlessCanRevoke
      CanRevoke
      count? : ℕ₁
      skipped! : ℕ
      ---------------------------------------------
      answer! = 1 ⇒ skipped! = 0 ∧ the SKIP block continues
      answer! = 0 ⇒ skipped! = count? ∧ the SKIP block is left,
                     each skip carrying second(cache key(kind?, env, dir?))

    ClearCache
      ΔCache
      ---------------------------------------------
      cache' = ∅

    SetCacheScope
      ΞCache
      scope?, scope, scope' : Scope
      ---------------------------------------------
      scope' = scope?

    SetMessages
      texts, texts' : KEY ⇸ seq₁ CHAR
      overrides? : KEY ⇸ seq CHAR
      ---------------------------------------------
      (dom overrides? ⊆ dom DEFAULTS ∧ ⊥ ∉ ran overrides? ∧ ⟨⟩ ∉ ran overrides?)
          ⇒ texts' = texts ⊕ overrides?
      ¬ (...) ⇒ texts' = texts ∧ croak

    AclDenies
      kind? : { read, write, exec }
      path? : PATH
      denied! : Answer
      ---------------------------------------------
      denied! = 1 ⇔ modeAllows(kind?, stat(path?), env) ∧ ¬ access(kind?, path?)

    WithRevoked
      kind? : Kind \ { sticky }
      path? : PATH
      code? : ⊤ → ⊤
      ---------------------------------------------
      mode'(path?) = mode(path?)                   -- restored, even if code? dies
      during code? : mode(path?) = restricted(kind?)
      result! = code?() ∨ code?'s exception, unchanged

    -- Invariant: a probe leaves the target directory as it found it.
    entries'(dir?) = entries(dir?)
```

## License and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
