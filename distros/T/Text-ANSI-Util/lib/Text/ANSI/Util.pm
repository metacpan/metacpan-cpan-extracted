package Text::ANSI::Util;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-27'; # DATE
our $DIST = 'Text-ANSI-Util'; # DIST
our $VERSION = '0.234'; # VERSION

our @EXPORT_OK = qw(
                       ta_add_color_resets
                       ta_detect
                       ta_extract_codes
                       ta_highlight
                       ta_highlight_all
                       ta_length
                       ta_length_height
                       ta_pad
                       ta_split_codes
                       ta_split_codes_single
                       ta_strip
                       ta_substr
                       ta_trunc
                       ta_wrap
               );

use Text::ANSI::BaseUtil ();

our $re = $Text::ANSI::BaseUtil::re;
*{$_} = \&{"Text::ANSI::BaseUtil::$_"} for @EXPORT_OK;

1;
# ABSTRACT: Routines for text containing ANSI color codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSI::Util - Routines for text containing ANSI color codes

=head1 VERSION

This document describes version 0.234 of Text::ANSI::Util (from Perl distribution Text-ANSI-Util), released on 2023-02-27.

=head1 SYNOPSIS

 use Text::ANSI::Util qw(
                       ta_add_color_resets
                       ta_detect
                       ta_extract_codes
                       ta_highlight
                       ta_highlight_all
                       ta_length
                       ta_length_height
                       ta_pad
                       ta_split_codes
                       ta_split_codes_single
                       ta_strip
                       ta_substr
                       ta_trunc
                       ta_wrap
                      );

 # detect whether text has ANSI color codes?
 say ta_detect("red");       # => false
 say ta_detect("\e[31mred"); # => true

 # calculate length of text (excluding the ANSI color codes)
 say ta_length("red");       # => 3
 say ta_length("\e[31mred"); # => 3

 # strip ANSI color codes
 say ta_strip("\e[31mred"); # => "red"

 # split codes (ANSI color codes are always on the even positions)
 my @parts = ta_split_codes("\e[31mred"); # => ("", "\e[31m", "red")

 # wrap text to a certain column width, handle ANSI color codes
 say ta_wrap("....", 40);

 # pad (left, right, center) text to a certain width
 say ta_pad("foo", 10);                          # => "foo       "
 say ta_pad("foo", 10, "left");                  # => "       foo"
 say ta_pad("foo\nbarbaz\n", 10, "center", "."); # => "...foo....\n..barbaz..\n"

 # truncate text to a certain width while still passing ANSI color codes
 use Term::ANSIColor;
 my $text = color("red")."red text".color("reset"); # => "\e[31mred text\e[0m"
 say ta_trunc($text, 5);                            # => "\e[31mred t\e[0m"

 # highlight the first occurrence of some string within text
 say ta_highlight("some text", "ome", "\e[7m\e[31m");

 # ditto, but highlight all occurrences
 say ta_highlight_all(...);

 # get substring
 my $substr = ta_substr("...", $pos, $len);

 # return text but with substring replaced with replacement
 say ta_substr("...", $pos, $len, $replacement);

=head1 DESCRIPTION

This module provides routines for dealing with text that contains ANSI color
codes, e.g. for determining its length/width (excluding the color codes),
stripping the color codes, extracting the color codes, and so on.

For functions that support wide characters, see L<Text::ANSI::WideUtil>.

Current caveats:

=over

=item * Other ANSI codes (non-color codes) are ignored

These are codes like for altering cursor positions, etc.

=item * Single-character CSI (control sequence introducer) currently ignored

Only C<ESC+[> (two-character CSI) is currently parsed.

BTW, in ASCII terminals, single-character CSI is C<0x9b>. In UTF-8 terminals, it
is C<0xc2, 0x9b> (2 bytes).

=item * Private-mode- and trailing-intermediate character currently not parsed

=item * Only color reset code \e[0m is recognized

For simplicity, currently multiple SGR parameters inside a single ANSI color
code is not parsed. This means that color reset code like C<\e[1;0m> or
C<\e[31;47;0m> is not recognized, only C<\e[0m> is. I believe this should not be
a problem with most real-world text out there.

=back

=head1 FUNCTIONS

=head2 ta_add_color_resets(@text) => LIST

Make sure that a color reset command (add C<\e[0m>) to the end of each element
and a replay of all the color codes from the previous element, from the last
color reset) to the start of the next element, and so on. Return the new list.

This makes each element safe to be combined with other array of text into a
single line, e.g. in a multicolumn/tabular layout. An example:

Without color resets:

 my @col1 = split /\n/, "\e[31mred\nmerah\e[0m";
 my @col2 = split /\n/, "\e[32mgreen\e[1m\nhijau tebal\e[0m";

 printf "%s | %s\n", $col1[0], $col2[0];
 printf "%s | %s\n", $col1[1], $col2[1];

the printed output:

 \e[31mred | \e[32mgreen
 merah\e[0m | \e[1mhijau tebal\e[0m

The C<merah> text on the second line will become green because of the effect of
the last color command printed (C<\e[32m>). However, with ta_add_color_resets():

 my @col1 = ta_add_color_resets(split /\n/, "\e[31mred\nmerah\e[0m");
 my @col2 = ta_add_color_resets(split /\n/, "\e[32mgreen\e[1m\nhijau tebal\e[0m");

 printf "%s | %s\n", $col1[0], $col2[0];
 printf "%s | %s\n", $col1[1], $col2[1];

the printed output (C<< <...> >>) marks the code added by ta_add_color_resets():

 \e[31mred<\e[0m> | \e[32mgreen\e[1m<\e[0m>
 <\e[31m>merah\e[0m | <\e[32m\e[1m>hijau tebal\e[0m

All the cells are printed with the intended colors.

=head2 ta_detect($text) => BOOL

Return true if C<$text> contains ANSI color codes, false otherwise.

=head2 ta_extract_codes($text) => STR

This is the opposite of C<ta_strip()>, return only the ANSI codes in C<$text>.

=head2 ta_highlight($text, $needle, $color) => STR

Highlight the first occurrence of C<$needle> in C<$text> with <$color>, taking
care not to mess up existing colors.

C<$needle> can be a string or a Regexp object.

Implementation note: to not mess up colors, we save up all color codes from the
last reset (C<\e[0m>) before inserting the highlight color + highlight text.
Then we issue C<\e[0m> and the saved up color code to return back to the color
state before the highlight is inserted. This is the same technique as described
in C<ta_add_color_resets()>.

=head2 ta_highlight_all($text, $needle, $color) => STR

Like C<ta_highlight()>, but highlight all occurrences instead of only the first.

=head2 ta_length($text) => INT

Count the number of characters in $text, while ignoring ANSI color codes.
Equivalent to C<< length(ta_strip($text)) >>. See also: C<ta_mbswidth()> in
L<Text::ANSI::WideUtil>.

=head2 ta_length_height($text) => [INT, INT]

Like C<ta_length()>, but also gives height (number of lines). For example, C<<
ta_length_height("foobar\nb\n") >> gives C<[6, 3]>.

See also: C<ta_mbswidth_height()> in L<Text::ANSI::WideUtil>.

=head2 ta_pad($text, $width[, $which[, $padchar[, $truncate]]]) => STR

Return C<$text> padded with C<$padchar> to C<$width> columns. C<$which> is
either "r" or "right" for padding on the right (the default if not specified),
"l" or "left" for padding on the right, or "c" or "center" or "centre" for
left+right padding to center the text.

C<$padchar> is whitespace if not specified. It should be string having the width
of 1 column.

Does *not* handle multiline text; you can split text by C</\r?\n/> yourself.

See also: C<ta_mbpad()> in L<Text::ANSI::WideUtil>.

=head2 ta_split_codes($text) => LIST

Split C<$text> to a list containing alternating ANSI color codes and text. ANSI
color codes are always on the second element, fourth, and so on. Example:

 ta_split_codes("");              # => ()
 ta_split_codes("a");             # => ("a")
 ta_split_codes("a\e[31m");       # => ("a", "\e[31m")
 ta_split_codes("\e[31ma");       # => ("", "\e[31m", "a")
 ta_split_codes("\e[31ma\e[0m");  # => ("", "\e[31m", "a", "\e[0m")
 ta_split_codes("\e[31ma\e[0mb"); # => ("", "\e[31m", "a", "\e[0m", "b")
 ta_split_codes("\e[31m\e[0mb");  # => ("", "\e[31m\e[0m", "b")

so you can do something like:

 my @parts = ta_split_codes($text);
 while (my ($text, $ansicode) = splice(@parts, 0, 2)) {
     ...
 }

=head2 ta_split_codes_single($text) => LIST

Like C<ta_split_codes()> but each ANSI color code is split separately, instead
of grouped together. This routine is currently used internally e.g. for
C<ta_wrap()> and C<ta_highlight()> to trace color reset/replay codes.

=head2 ta_strip($text) => STR

Strip ANSI color codes from C<$text>, returning the stripped text.

=head2 ta_substr($text, $pos, $len[ , $replacement ]) => STR

A bit like Perl's C<substr()>. If C<$replacement> is not specified, will return
the substring. If C<$replacement> is specified, will return $text with the
substring replaced by C<$replacement>.

See also: C<ta_mbsubstr()> in L<Text::ANSI::WideUtil>.

=head2 ta_trunc($text, $width) => STR

Truncate C<$text> to C<$width> columns while still including all the ANSI color
codes. This ensures that truncated text still reset colors, etc.

Does *not* handle multiline text; you can split text by C</\r?\n/> yourself.

See also: C<ta_mbtrunc()> in L<Text::ANSI::WideUtil>.

=head2 ta_wrap($text, $width, \%opts) => STR

Like L<Text::WideChar::Util>'s C<wrap()> except handles ANSI color codes.
Perform color reset at the end of each line and a color replay at the start of
subsequent line so the text is safe for combining in a multicolumn/tabular
layout.

Options:

=over

=item * flindent => STR

First line indent. Currently must not contain ANSI color codes or wide
characters.

=item * slindent => STR

Subsequent line indent. Currently must not contain ANSI color codes or wide
characters.

=item * tab_width => INT (default: 8)

=item * pad => BOOL (default: 0)

If set to true, will pad each line to C<$width>. This is convenient if you need
the lines padded, saves calls to ta_pad().

=item * return_stats => BOOL (default: 0)

If set to true, then instead of returning the wrapped string, function will
return C<< [$wrapped, $stats] >> where C<$stats> is a hash containing some
information like C<max_word_width>, C<min_word_width>.

=item * keep_trailing_space => BOOL (default: 0)

If set to true, then trailing space that separates words will be kept at the end
of wrapped lines. This option is useful if you want to rejoin the lines later.
Without this option set to true, wrapping this line at width=4 (quotes shown):

 "some long   line"

will result in:

 "some"
 "long"
 "line"

While if this option is set to true, the result will be:

 "some "
 "long "
 "line"

=back

Performance: ~500/s on my Core i5 1.7GHz laptop for a ~1KB of text (with zero to
moderate amount of color codes).

See also: C<ta_mbwrap()> in L<Text::ANSI::WideUtil>.

=head1 FAQ

=over 11

=back BEGIN_BLOCK: why_split

=head2 Why split functionalities of wide character and color support into multiple modules/distributions?

Performance (see numbers in the function description), dependency
(L<Unicode::GCString> is used for wide character support), and overhead (loading
Unicode::GCString).

=over 11

=back END_BLOCK: why_split

=head2 How do I highlight a string case-insensitively?

You can currently use a regex for the C<$needle> and use the C<i> modifier.
Example:

 use Term::ANSIColor;
 ta_highlight($text, qr/\b(foo)\b/i, color("bold red"));

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSI-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-ANSI-Util>.

=head1 SEE ALSO

L<String::Pad> provides padding function for strings that do not contain ASCII
escape codes nor wide characters.

L<Text::NonWideChar::Util> provides some other functions for strings that do not
contain ASCII escape codes nor wide characters.

L<Text::WideChar::Util> provides utilities for strings that do not contain ANSI
escape codes I<but> contain wide characters.

L<Text::ANSI::WideUtil> provides utilities for strings that contain ANSI escape
codes I<and> wide characters.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSI-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
