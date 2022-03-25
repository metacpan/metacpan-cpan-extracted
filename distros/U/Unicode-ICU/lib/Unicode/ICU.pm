# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU;

use strict;
use warnings;

use XSLoader;

use Unicode::ICU::X ();

our $VERSION;

BEGIN {
    $VERSION = '0.06';
    XSLoader::load(__PACKAGE__, $VERSION);
}

=encoding utf-8

=head1 NAME

Unicode::ICU - L<ICU|https://icu.unicode.org/> in Perl

=head1 DESCRIPTION

This library is a binding to ICU, a library for internationalization (i18n),
localization (l10n), Unicode, and all kinds of related stuff.

We currently only expose a subset of ICU’s (quite vast!) functionality.
More can be added as need arises.

Most functionality exists in submodules under this namespace. Their
names correspond roughly with modules or classes in ICU’s C and C++ APIs:

=over

=item * L<Unicode::ICU::MessageFormat>

NB: This exposes a lot of
other ICU functionality like formatting of numbers, dates/times, and plurals.

=item * L<Unicode::ICU::MessagePattern>

=item * L<Unicode::ICU::ListFormatter>

=item * L<Unicode::ICU::IDN>

=item * L<Unicode::ICU::Locale>

=back

The present namespace exposes limited controls of its own,
as described below.

=head1 DOCUMENTATION

Unicode::ICU’s documentation tries to be helpful while avoiding
duplication of ICU’s own documentation. If something is unclear,
consult the corresponding parts of ICU’s documentation to see if that
helps. If confusion persists, file a documentation bug.

=head1 CHARACTER ENCODING

Generally speaking, all strings into and out of this distribution’s
interfaces are I<character> strings, not byte strings. If you get a
wide-character warning or corrupted output, you may have neglected either
a decode prior to calling ICU or an encode afterward. CPAN’s
L<Encode::Simple> provides a nice, fail-early-fail-often interface for
these operations.

=head1 COMPATIBILITY

This module is tested with ICU versions as far back as 4.2.1 (the version
that ships with CloudLinux 6). Some of this module’s functionality, though,
is unavailable in certain ICU versions.

=head1 ERRORS

Errors from ICU are L<Unicode::ICU::X::ICU> instances. Most others are
plain strings; other errors are thrown as documented.

=head1 CONSTANTS

=over

=item * C<ICU_VERSION> - a text string (e.g., C<67.1>)

=item * C<ICU_MAJOR_VERSION> - an unsigned integer (e.g., C<67>)

=item * C<ICU_MINOR_VERSION> - an unsigned integer (e.g., C<1>)

=back

=head1 FUNCTIONS

=head2 $errname = get_error_name()

A wrapper around ICU’s C<u_errorName()>, which gives a human-readable
name (e.g., C<U_BUFFER_OVERFLOW_ERROR>) for an error code.

=head1 SEE ALSO

Some other ICU bindings exist on CPAN that do different things from
this module:

=over

=item * L<Sort::Naturally::ICU>

=item * L<Unicode::ICU::Collator>

=back

=cut

1;
