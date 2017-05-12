#-*- perl -*-
#-*- coding: utf-8 -*-

package Unicode::Precis::Utils;

use 5.008;
use strict;
use warnings;

use base qw(Exporter);
our %EXPORT_TAGS =
    ('all' => [qw(compareExactly decomposeWidth foldCase mapSpace)]);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

our $VERSION    = '0.01';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;    # see L<perlmodstyle>

require XSLoader;
XSLoader::load(__PACKAGE__, $XS_VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Unicode::Precis::Utils - Utility functions for PRECIS enforcement

=head1 DESCRIPTION

This module provides some utility functions used by enforcement and comparison
of PRECIS Framework.

Note that the word "UTF-8" in this document is used in its proper meaning.

=head2 Functions

=over

=item compareExactly ( $stringA, $stringB )

Checks if $stringA and $stringB are an exact octet-for-octet match,
and returns C<1> or C<0>.
Unicode strings are considered to be the same as corresponding
UTF-8 bytestrings.
If any of $stringA and $stringB are not defined, returns C<undef>.

=back

Functions below maps characters in Unicode string or UTF-8 bytestring.
Malformed sequences in the string are skipped and kept intact.
If mapping succeeded, modifys string argument if possible, and returns it.
Otherwise, returns C<undef>.

=over

=item foldCase ( $string )

Applys Unicode Default Case Folding to $string.

=item mapSpace ( $string )

Maps non-ASCII spaces (those in general category Zs) to SPACE (U+0020).

=item decomposeWidth ( $string )

Maps fullwidth and halfwidth characters in $string to their decomposition
mappings.

=back

=head2 Exports

None are exported by default.
All functions above may be exported by C<:all> tag.

=head1 RESTRICTIONS

This module can not handle Unicode string on EBCDIC platforms.

=head1 CAVEATS

=over

=item *

The mappings this module can provide are restricted by
Unicode database of Perl core.

=back

=head1 SEE ALSO

L<Unicode::Precis>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji, E<lt>hatuka@nezumi.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Hatuka*nezumi - IKEDA Soji

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text of
the licenses at <http://dev.perl.org/licenses/>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut
