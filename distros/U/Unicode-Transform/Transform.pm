package Unicode::Transform;

require 5.006001;

use strict;
no warnings 'utf8';

require Exporter;
require DynaLoader;

our $VERSION = '0.51';

our @ISA = qw(Exporter DynaLoader);

our @UTF_names = qw(utf16le utf16be utf32le utf32be utf8 utf8mod utfcp1047);
our @Codenames = ("unicode", @UTF_names);

our %EXPORT_TAGS = (
    'from' => [ map('unicode_to_'.$_, @UTF_names) ],
    'to'   => [ map($_.'_to_unicode', @UTF_names) ],
    'chr'  => [ map('chr_'.$_,        @Codenames) ],
    'ord'  => [ map('ord_'.$_,        @Codenames) ],
);

for my $a (@Codenames) {
    for my $b (@Codenames) {
	push @{ $EXPORT_TAGS{'conv'} }, "${a}_to_${b}";
    }
}

our @EXPORT    = (map @$_, @EXPORT_TAGS{qw(from to)});
our @EXPORT_OK = (map @$_, @EXPORT_TAGS{qw(conv chr ord)});
$EXPORT_TAGS{'all'} = \ @EXPORT_OK;

bootstrap Unicode::Transform $VERSION;

1;
__END__

=head1 NAME

Unicode::Transform - conversion among Unicode Transformation Formats

=head1 SYNOPSIS

    use Unicode::Transform ':all';

    $unicode_string = utf16be_to_unicode($utf16be_string);
    $utf16le_string = unicode_to_utf16le($unicode_string);
    $utf8_string    = utf32be_to_utf8   ($utf32be_string);

    $utf8_string    = utf32be_to_utf8(\&chr_utf8, $utf32be_string);
         # ill-formed octet sequences are allowed.

=head1 DESCRIPTION

This module provides some functions to convert a string
among some Unicode Transformation Formats (UTF).

=head2 Conversion Between UTF

(Exporting: C<use Unicode::Transform ':conv';>)

=over 4

=item C<E<lt>SRC_UTF_NAMEE<gt>_to_E<lt>DST_UTF_NAMEE<gt>([CALLBACK,] STRING)>

=back

Returns a string in DST_UTF_NAME corresponding to STRING in SRC_UTF_NAME.

B<Function names>

A function name consists of SRC_UTF_NAME, a string '_to_',
and DST_UTF_NAME. SRC_UTF_NAME and DST_UTF_NAME must be one
in the list of hyphen-removed and lowercased names following:

    unicode    (for Perl internal Unicode encoding; see perlunicode)
    utf16le    (for UTF-16LE)
    utf16be    (for UTF-16BE)
    utf32le    (for UTF-32LE)
    utf32be    (for UTF-32BE)
    utf8       (for UTF-8)
    utf8mod    (for UTF-8-Mod)
    utfcp1047  (for CP1047-oriented UTF-EBCDIC).

In all, 64 (i.e. 8 times 8) functions are available. Available function names
include C<utf16be_to_utf32le()> and C<utf8_to_unicode()>.
DST_UTF_NAME may be same as SRC_UTF_NAME like C<utf8_to_utf8()>.

Conversions where both SRC_UTF_NAME and DST_UTF_NAME begin at 'utf' are
defined well and stably. In contrast to these UTF, the Perl internal Unicode
encoding is influenced by the platform-dependent features (e.g. 32bit/64bit,
ASCII/EBCDIC).

B<Parameters>

If the first parameter is a reference, that is regarded as  the CALLBACK.
Any reference will not allowed as STRING. If CALLBACK is given,
the second parameter is STRING; otherwise the first is.
Currently, only code references are allowed as CALLBACK.

If CALLBACK is omitted, only Unicode scalar values (C<0x0000..0xD7FF>
and C<0xE000..0x10FFFF>) are allowed. Ill-formed octet sequences
(corresponding to a code point outside the range of Unicode scalar values)
and partial octets (which does not correspond to any code point) are deleted,
as if a code reference constantly returning an empty string,
C<sub {''}>, was used as CALLBACK.

Examples of partial octets: the first octet without following octets in UTF-8
like C<"\xC2">; the last octet in UTF-16BE,LE with odd number of octets.

If CALLBACK is specified, the appearance of an ill-formed octet sequences
or a partial octet calls the code reference. The first parameter for CALLBACK
is the unsigned integer value of its code point;
if the value is lesser than 256, that is a partial octet.

The return value from CALLBACK will be inserted there.
You may use C<chr_E<lt>DST_UTF_NAMEE<gt>()> as CALLBACK (see below).
Return value from CALLBACK should be in UTF of DST_UTF_NAME.

You can call C<die> or C<croak> in CALLBACK when you want to stop
the operation if the whole STRING would not be well-formed.

=head2 Conversion from Code Point to String

(Exporting: C<use Unicode::Transform ':chr';>)

=over 4

=item chr_C<E<lt>DST_UTF_NAMEE<gt>(CODEPOINT)>

=back

Returns a string in DST_UTF_NAME corresponding to CODEPOINT.
CODEPOINT should be an unsigned integer. If CODEPOINT is outside
the range of Unicode scalar values, a corresponding ill-formed
octet sequence will be returned.

If CODEPOINT is greater than the maximum value, returns C<undef>.
The maximum value of CODEPOINT is:

    0x0010_FFFF for chr_utf16le() and chr_utf16be()
    0x7FFF_FFFF for chr_utf8(), chr_utf8mod(), chr_utfcp1047()
    0xFFFF_FFFF for chr_utf32le(), chr_utf32be()

The maximum value of CODEPOINT for C<chr_unicode()> depends
on the platform features (e.g. 32bit/64bit, ASCII/EBCDIC).

B<Function names>

The full list of functions provided:

=over 4

=item C<chr_unicode(CODEPOINT)>

=item C<chr_utf16le(CODEPOINT)>

=item C<chr_utf16be(CODEPOINT)>

=item C<chr_utf32le(CODEPOINT)>

=item C<chr_utf32be(CODEPOINT)>

=item C<chr_utf8(CODEPOINT)>

=item C<chr_utf8mod(CODEPOINT)>

=item C<chr_utfcp1047(CODEPOINT)>

=back

=head2 Numeric Value of the First Character

(Exporting: C<use Unicode::Transform ':ord';>)

=over 4

=item ord_C<E<lt>SRC_UTF_NAMEE<gt>(STRING)>

=back

Returns an unsigned integer value of the first character of STRING
in SRC_UTF_NAME. STRING may begin at an ill-formed octet sequence
corresponding to a surrogate code point (C<0xD800..0xDFFF>)
or an out-of-range code point (C<0x110000> and greater). If STRING
is empty or begins at a partial octet, returns C<undef>.

B<Function names>

The full list of functions provided:

=over 4

=item C<ord_unicode(STRING)>

=item C<ord_utf16le(STRING)>

=item C<ord_utf16be(STRING)>

=item C<ord_utf32le(STRING)>

=item C<ord_utf32be(STRING)>

=item C<ord_utf8(STRING)>

=item C<ord_utf8mod(STRING)>

=item C<ord_utfcp1047(STRING)>

=back

=head1 AUTHOR

SADAHIRO Tomoyuki <SADAHIRO@cpan.org>

Copyright(C) 2002-2005, SADAHIRO Tomoyuki. Japan. All rights reserved.

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item http://www.unicode.org/reports/tr16/

UTF-EBCDIC (and UTF-8-Mod)

=back

=cut
