# NAME

Unicode::ICU - [ICU](https://icu.unicode.org/) in Perl

# DESCRIPTION

This library is a binding to ICU, a library for internationalization (i18n),
localization (l10n), Unicode, and all kinds of related stuff.

We currently only expose a subset of ICU’s (quite vast!) functionality.
More can be added as need arises.

Most functionality exists in submodules under this namespace. Their
names correspond roughly with modules or classes in ICU’s C and C++ APIs:

- [Unicode::ICU::MessageFormat](https://metacpan.org/pod/Unicode%3A%3AICU%3A%3AMessageFormat)

    NB: This exposes a lot of
    other ICU functionality like formatting of numbers, dates/times, and plurals.

- [Unicode::ICU::MessagePattern](https://metacpan.org/pod/Unicode%3A%3AICU%3A%3AMessagePattern)
- [Unicode::ICU::ListFormatter](https://metacpan.org/pod/Unicode%3A%3AICU%3A%3AListFormatter)
- [Unicode::ICU::IDN](https://metacpan.org/pod/Unicode%3A%3AICU%3A%3AIDN)
- [Unicode::ICU::Locale](https://metacpan.org/pod/Unicode%3A%3AICU%3A%3ALocale)

The present namespace exposes limited controls of its own,
as described below.

# DOCUMENTATION

Unicode::ICU’s documentation tries to be helpful while avoiding
duplication of ICU’s own documentation. If something is unclear,
consult the corresponding parts of ICU’s documentation to see if that
helps. If confusion persists, file a documentation bug.

# CHARACTER ENCODING

Generally speaking, all strings into and out of this distribution’s
interfaces are _character_ strings, not byte strings. If you get a
wide-character warning or corrupted output, you may have neglected either
a decode prior to calling ICU or an encode afterward. CPAN’s
[Encode::Simple](https://metacpan.org/pod/Encode%3A%3ASimple) provides a nice, fail-early-fail-often interface for
these operations.

# COMPATIBILITY

This module is tested with ICU versions as far back as 4.2.1 (the version
that ships with CloudLinux 6). Some of this module’s functionality, though,
is unavailable in certain ICU versions.

# ERRORS

Errors from ICU are [Unicode::ICU::X::ICU](https://metacpan.org/pod/Unicode%3A%3AICU%3A%3AX%3A%3AICU) instances. Most others are
plain strings; other errors are thrown as documented.

# CONSTANTS

- `ICU_VERSION` - a text string (e.g., `67.1`)
- `ICU_MAJOR_VERSION` - an unsigned integer (e.g., `67`)
- `ICU_MINOR_VERSION` - an unsigned integer (e.g., `1`)

# FUNCTIONS

## $errname = get\_error\_name()

A wrapper around ICU’s `u_errorName()`, which gives a human-readable
name (e.g., `U_BUFFER_OVERFLOW_ERROR`) for an error code.

# SEE ALSO

Some other ICU bindings exist on CPAN that do different things from
this module:

- [Sort::Naturally::ICU](https://metacpan.org/pod/Sort%3A%3ANaturally%3A%3AICU)
- [Unicode::ICU::Collator](https://metacpan.org/pod/Unicode%3A%3AICU%3A%3ACollator)
