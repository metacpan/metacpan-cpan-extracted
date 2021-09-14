package Text::ANSI::WideUtil;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-14'; # DATE
our $DIST = 'Text-ANSI-WideUtil'; # DIST
our $VERSION = '0.232'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Text::WideChar::Util qw(mbswidth mbtrunc);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       ta_mbpad
                       ta_mbsubstr
                       ta_mbswidth
                       ta_mbswidth_height
                       ta_mbtrunc
                       ta_mbwrap
                       ta_trunc
               );

use Text::ANSI::BaseUtil ();

our $re = $Text::ANSI::BaseUtil::re;
*{$_} = \&{"Text::ANSI::BaseUtil::$_"} for @EXPORT_OK;

1;
# ABSTRACT: Routines for text containing ANSI color codes (wide-character functions only)

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSI::WideUtil - Routines for text containing ANSI color codes (wide-character functions only)

=head1 VERSION

This document describes version 0.232 of Text::ANSI::WideUtil (from Perl distribution Text-ANSI-WideUtil), released on 2021-04-14.

=head1 SYNOPSIS

 use Text::ANSI::WideUtil qw(
                           ta_mbpad
                           ta_mbsubstr
                           ta_mbswidth
                           ta_mbswidth_height
                           ta_mbtrunc
                           ta_mbwrap
                          );

 # calculate visual width of text if printed on terminal (can handle Unicode
 # wide characters and exclude the ANSI color codes)
 say ta_mbswidth("\e[31mred");  # => 3
 say ta_mbswidth("\e[31m红色"); # => 4

 # ditto, but also return the number of lines
 say ta_mbswidth_height("\e[31mred\n红色"); # => [4, 2]

 # wrap text to a certain column width, handle ANSI color codes
 say ta_mbwrap(...);

 # pad (left, right, center) text to a certain width
 say ta_mbpad(...);

 # truncate text to a certain width while still passing ANSI color codes
 say ta_mbtrunc(...);

 # get substring, like ta_substr()
 my $substr = ta_mbsubstr("...", $pos, $len);

 # return text but with substring replaced with replacement
 say ta_mbsubstr("...", $pos, $len, $replacement);

=head1 DESCRIPTION

This module contains the wide-character variant (C<ta_mb*()>) for some functions
in L<Text::ANSI::Util>. It is split so only this module requires
L<Text::WideChar::Util> and Text::ANSI::Util can be kept slim.

=for Pod::Coverage ^(ta_trunc)$

=head1 FUNCTIONS

=head2 ta_mbpad($text, $width[, $which[, $padchar[, $truncate]]]) => STR

Pad <$text> to C<$width>. Like C<ta_pad()> but it uses C<ta_mbswidth()> to
determine visual width instead of C<ta_length()>. See documentation for
C<ta_pad()> for more details on the other arguments.

=head2 ta_mbtrunc($text, $width) => STR

Truncate C<$text> to C<$width>. Like C<ta_trunc()> but it uses C<ta_mbswidth()>
to determine visual width instead of C<ta_length()>.

=head2 ta_mbswidth($text) => INT

Return visual width of C<$text> (in number of columns) if printed on terminal.
Equivalent to C<< Text::WideChar::Util::mbswidth(ta_strip($text)) >>. This
function can be used e.g. in making sure that your text aligns vertically when
output to the terminal in tabular/table format.

Note that C<ta_mbswidth()> handles multiline text correctly, e.g.: C<<
ta_mbswidth("foo\nbarbaz") >> gives 6 instead of 3-1+8 = 8. It splits the input
text first with C<< /\r?\n/ >> as separator.

=head2 ta_mbswidth_height($text) => [INT, INT]

Like C<ta_mbswidth()>, but also gives height (number of lines). For example, C<<
ta_mbswidth_height("西爪哇\nb\n") >> gives C<[6, 3]>.

=head2 ta_mbwrap($text, $width, \%opts) => STR

Like C<ta_wrap()>, but it uses C<ta_mbswidth()> to determine visual width
instead of C<ta_length()>.

Performance: ~300/s on my Core i5 1.7GHz laptop for a ~1KB of text (with zero to
moderate amount of color codes). As a comparison, Text::WideChar::Util's
mbwrap() can do about 650/s.

=head2 ta_mbsubstr($text, $pos, $len[ , $replacement ]) => STR

Like C<ta_substr()>, but handles wide characters. C<$pos> is counted in visual
width, not number of characters.

=head1 FAQ

=head2 Why split functionalities of wide character and color support into multiple modules/distributions?

Performance (see numbers in the function description), dependency
(L<Unicode::GCString> is used for wide character support), and overhead (loading
Unicode::GCString).

=head2 How do I truncate string based on number of characters instead of columns?

You can simply use C<ta_trunc()> even on text containing wide characters.
ta_trunc() uses Perl's length() which works on a per-character basis.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSI-WideUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-ANSI-WideUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-ANSI-WideUtil/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::ANSI::Util>, L<Text::WideChar::Util>, L<Text::NonWideChar::Util>,
L<Text::Wrap>, L<String::Pad>

L<http://en.wikipedia.org/wiki/ANSI_escape_code>

CLI's that use functions from this module include: L<dux> from L<App::dux>
(C<dux wrap>, C<dux lpad>, C<dux rpad>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
