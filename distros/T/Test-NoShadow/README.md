## Name

Test::NoShadow - Fail CI when two distributions provide the same Perl package, or when t/ exercises a copy other than the one under test

## Version

Version 0.001.0

## Synopsis

```perl
# In your CI, over a directory of checkouts:
use Test::More;
use Test::NoShadow qw(shadowed_ok lib_ok find_shadows);

shadowed_ok('/home/njh');    # fails if any Perl package is provided by two checkouts

# In a distribution's own t/, after using its modules:
use My::Module;
lib_ok('My::Module');        # fails if My::Module came from anywhere but this distribution

# Or inspect the data yourself:
my $shadows = find_shadows('/home/njh');
foreach my $package (sort keys %$shadows) {
    diag("$package: @{ $shadows->{$package} }");
}
```

## Description

`Test::NoShadow` fails your test suite when two distributions provide the same
Perl package, and when a distribution's tests exercise a copy other than the
one under test (an older installed copy, or a vendored copy in `t/`).

It was written to police a workspace of many checkouts: pairs such as
`Schema::Validator` in both `schema-validator` and `Schema-Validator`,
or a vendored `VWF::*` inside another distribution, ship identical package
names, so `use` can silently load the wrong code.

No other CPAN module checks for the multi-checkout variant; the closest
relative, [Test::CleanNamespaces](https://metacpan.org/pod/Test%3A%3ACleanNamespaces), works on installed distributions only.

Two checks are provided:

- ["shadowed\_ok"](#shadowed_ok) - a directory of checkouts (or the installed `@INC`)
must not contain a Perl package in more than one place
- ["lib\_ok"](#lib_ok) - each named module must have been loaded from the
distribution's own `lib/` or `blib/lib`

## Functions/Methods

### Shadowed\_Ok \[@Dirs, \[ \\%Options \]\]

Scans each directory (recursively) for `.pm` files and extracts the package
names they declare. Passes if no Perl package is declared in more than one
file; otherwise fails, with a diagnostic naming both providers.

With no directories given, `@INC` is scanned - for example:

```
prove -Ilib t/shadow.t
```

The following options are recognised in the optional hash reference:

- `ignore` - array reference of regexps. Each is matched against
both the `"provider/package"` pair and the file's path; if either matches,
the file is excluded, e.g. `{ ignore => [qr{^WWW-Scrape-BillionGraves/}, qr{/t/lib/}] }`.
The file's path is also matched with backslashes converted to forward
slashes, so patterns such as `qr{/t/lib/}` work on Windows as well

Each top-level directory beneath the scanned directory is treated as a
"provider" (in this workspace, a checkout); files directly beneath the
scanned directory are labelled with their own file name. To check a single
checkout for vendored copies, pass the checkout itself: its top-level
directory (usually `lib`) becomes the provider, and copies under `t/` are
reported alongside copies under `lib`.

Returns true on success, false on failure.

### Lib\_Ok @Modules, \[ \\%Options \]

For use in the distribution's own tests, after the modules have been
`use`d. Passes if each named module was loaded from this distribution's
`lib` or `blib/lib`; fails if a module was loaded from anywhere else
(a shadowing copy installed in `@INC`), or was not loaded at all.

One test is run per module.

The following options are recognised:

- `dir` - the root of the distribution, default `.`
- `lib` - array reference of library directories beneath `dir`
that count as "the copy under test", default `[qw(lib blib/lib)]`

Returns true if all modules passed.

### Find\_Shadows $Dir, \[ \\%Options \]

The non-TAP interface: returns a hash reference mapping each shadowed
package name to a sorted array reference of the files that declare it.
Accepts the same options as ["shadowed\_ok"](#shadowed_ok).

## Diagnostics

- `No shadowed Perl packages`

    All packages were found in exactly one file.

- `Foo::Bar is provided by 2 files:`

    Each provider is listed on its own line, indented, as `provider: file`.

- `Foo::Bar was loaded from /path/to/Foo/Bar.pm, not from ... - is a shadowing copy installed?`

    The module was loaded from outside this distribution's `lib` or `blib/lib`.
    An older copy installed in `@INC`, or a vendored copy in `t/`, will be
    loaded by the test suite instead of the code being tested.

- `Foo::Bar has not been loaded; use it before calling lib_ok`

    `lib_ok` can only check modules that are already in `%INC`.

- `Test::NoShadow: $root is not a directory`

    The directory passed to ["shadowed\_ok"](#shadowed_ok) or ["find\_shadows"](#find_shadows) does not
    exist.

## Limitations

- Package detection is a line-based heuristic: `package Foo::Bar;`,
`package Foo::Bar 1.23;` and `package Foo::Bar {` are recognised, but a
declaration split across lines, or the string `package Foo::Bar;` inside a
here-document or data section, will confuse it.
- Packages provided only by an XS boot file, without a `.pm`, are not
seen.
- Files under `t/` that intentionally duplicate a `lib/` package
(test fixtures) are reported as shadows. Use the `ignore` option to exclude
them.
- Scanning a large `@INC` reads every `.pm` file in it and can take
a few seconds.

## See Also

[Test::Which](https://metacpan.org/pod/Test%3A%3AWhich) - skip tests if external programs are missing from PATH

[Test::CleanNamespaces](https://metacpan.org/pod/Test%3A%3ACleanNamespaces) - check for leftover subroutines in installed distributions

[Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder) - the test framework this module is built on

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
