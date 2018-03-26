package Unicode::BiDiRule;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(check BIDIRULE_RTL BIDIRULE_LTR BIDIRULE_NOTBIDI BIDIRULE_INVALID)]
);

our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

our $VERSION    = '0.04';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;    # see L<perlmodstyle>

require XSLoader;
XSLoader::load('Unicode::BiDiRule', $XS_VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Unicode::BiDiRule - RFC 5893 BiDi Rule

=head1 SYNOPSIS

  use Unicode::BiDiRule qw(check);
  $result = check($string);
  %result = check($string);

=head1 DESCRIPTION

L<Unicode::BiDiRule> performs checking according to BiDi Rule described in
RFC 5893.

Note that the word "UTF-8" in this document is used in its proper meaning.

=head2 Functions

=over

=item check ( $string, [ $strict ] )

Check if a string satisfys BiDi Rule.

Parameters:

=over

=item $string

A string to be checked, Unicode string or bytestring.

Note that bytestring won't be upgraded to Unicode string but will be treated
as UTF-8 sequence.

=item $strict

If C<0> is specified, won't perform following checks if the string does not
contain right-to-left characters and is not BiDi label:

=over

=item *

String does not begin with nonspacing mark.

=item *

String does not contain formatting characters, space characters and
line separators.

=back

=back

Returns:

In scalar context:
One of C<BIDIRULE_RTL>, C<BIDIRULE_LTR> and C<BIDIRULE_NOTBIDI>
(see L</Constants>), or C<undef>.

In array context:
A list of pairs describing detail of result with these keys:

=over

=item C<result>

One of values described in L</Constants>.

=item C<offset>

If the check fails, offset from beginning of string.
If succeeds, length of string.

Offset or length is based on byte for bytestring,
and based on character for Unicode string.

=item C<length>

When the check fails, length of disallowed substring.

Length is based on byte for bytestring,
and based on character for Unicode string.
It is undefined for invalid sequence.

=item C<ord>

Unicode scalar value of the first character of substring,
when C<length> item is set.

=item C<unsafe>

If disallowed substring contains formatting character, true value is set.
Such character can cause problem to display.

=back

=item Unicode::BiDiRule::UnicodeVersion()

Returns the version of the Unicode Character Database.
It should be the same as Unicode::UCD::UnicodeVersion().

=back

=head2 Constants

Possible results of checking.

=over

=item C<BIDIRULE_RTL>

String is RTL label.

=item C<BIDIRULE_LTR>

String is LTR label.

=item C<BIDIRULE_NOTBIDI> (C<0>)

String does not contain right-to-left characters but is not BiDi label,
neither RTL label nor LTR label.

=item C<BIDIRULE_INVALID>

String does not satisfy the rule.

=back

=head2 Exports

None by default.
C<:all> tag exports check() and constants.

=head1 RESTRICTIONS

check() can not check Unicode string on EBCDIC platforms.

=head1 CAVEATS

=over

=item *

The repertoire and property values this module can provide are restricted by
Unicode database of Perl core.
Table below lists implemented Unicode version by each Perl version.

  Perl's version     Implemented Unicode version
  ------------------ ---------------------------------------
  5.8.0              3.2.0
  5.8.1 - 5.8.3      4.0.0
  5.8.4 - 5.8.6      4.0.1
  5.8.7 - 5.8.8      4.1.0
  5.10.0             5.0.0
  5.8.9, 5.10.1      5.1.0
  5.12.x             5.2.0
  5.14.x             6.0.0 with Corrigendum #8
  5.16.x             6.1.0
  5.18.x             6.2.0
  5.20.x             6.3.0
  5.22.x             7.0.0, correcting erratum at 2014-10-21

=item *

The string which is not BiDi label, neither RTL label nor LTR label,
may not always be invalid.  It should be checked by another rule.

=back

=head1 SEE ALSO

RFC 5893
I<Right-to-Left Scripts for Internationalized Domain Names for Applications
(IDNA)>.
L<https://tools.ietf.org/html/rfc5893>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji, E<lt>hatuka@nezumi.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2018 by Hatuka*nezumi - IKEDA Soji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. For more details, see the full text of
the licenses at <http://dev.perl.org/licenses/>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut
