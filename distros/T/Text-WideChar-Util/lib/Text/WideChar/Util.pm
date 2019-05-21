package Text::WideChar::Util;

our $DATE = '2019-05-17'; # DATE
our $VERSION = '0.170'; # VERSION

use 5.010001;
use locale;
use strict;
use utf8;
use warnings;

use Unicode::GCString;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       mbpad
                       pad
                       mbswidth
                       mbswidth_height
                       length_height
                       mbtrunc
                       trunc
                       mbwrap
                       wrap
               );

sub mbswidth {
    Unicode::GCString->new($_[0])->columns;
}

sub mbswidth_height {
    my $text = shift;
    my $num_lines = 0;
    my $len = 0;
    for my $e (split /(\r?\n)/, $text) {
        if ($e =~ /\n/) {
            $num_lines++;
            next;
        }
        $num_lines = 1 if $num_lines == 0;
        my $l = mbswidth($e);
        $len = $l if $len < $l;
    }
    [$len, $num_lines];
}

sub length_height {
    my $text = shift;
    my $num_lines = 0;
    my $len = 0;
    for my $e (split /(\r?\n)/, $text) {
        if ($e =~ /\n/) {
            $num_lines++;
            next;
        }
        $num_lines = 1 if $num_lines == 0;
        my $l = length($e);
        $len = $l if $len < $l;
    }
    [$len, $num_lines];
}

sub _get_indent_width {
    my ($is_mb, $indent, $tab_width) = @_;
    my $w = 0;
    for (split //, $indent) {
        if ($_ eq "\t") {
            # go to the next tab
            $w = $tab_width * (int($w/$tab_width) + 1);
        } else {
            $w += $is_mb ? mbswidth($_) : 1;
        }
    }
    $w;
}

# 3002 = IDEOGRAPHIC FULL STOP
# ff0c = FULLWIDTH COMMA

our $re_cjk = qr/(?:
                     \p{Block=CJK_Compatibility}
                 |   \p{Block=CJK_Compatibility_Forms}
                 |   \p{Block=CJK_Compatibility_Ideographs}
                 |   \p{Block=CJK_Compatibility_Ideographs_Supplement}
                 |   \p{Block=CJK_Radicals_Supplement}
                 |   \p{Block=CJK_Strokes}
                 |   \p{Block=CJK_Symbols_And_Punctuation}
                 |   \p{Block=CJK_Unified_Ideographs}
                 |   \p{Block=CJK_Unified_Ideographs_Extension_A}
                 |   \p{Block=CJK_Unified_Ideographs_Extension_B}
                 |   \p{Hiragana}\p{Katakana}\p{Hangul}\x{30fc}
                #|   \p{Block=CJK_Unified_Ideographs_Extension_C}
                     [\x{3002}\x{ff0c}]
                 )/x;
our $re_cjk_class = qr/[
                           \p{Block=CJK_Compatibility}
                           \p{Block=CJK_Compatibility_Forms}
                           \p{Block=CJK_Compatibility_Ideographs}
                           \p{Block=CJK_Compatibility_Ideographs_Supplement}
                           \p{Block=CJK_Radicals_Supplement}
                           \p{Block=CJK_Strokes}
                           \p{Block=CJK_Symbols_And_Punctuation}
                           \p{Block=CJK_Unified_Ideographs}
                           \p{Block=CJK_Unified_Ideographs_Extension_A}
                           \p{Block=CJK_Unified_Ideographs_Extension_B}
                           \p{Hiragana}\p{Katakana}\p{Hangul}\x{30fc}
                           \x{3002}
                           \x{ff0c}
                      ]/x;
our $re_cjk_negclass = qr/[^
                              \p{Block=CJK_Compatibility}
                              \p{Block=CJK_Compatibility_Forms}
                              \p{Block=CJK_Compatibility_Ideographs}
                              \p{Block=CJK_Compatibility_Ideographs_Supplement}
                              \p{Block=CJK_Radicals_Supplement}
                              \p{Block=CJK_Strokes}
                              \p{Block=CJK_Symbols_And_Punctuation}
                              \p{Block=CJK_Unified_Ideographs}
                              \p{Block=CJK_Unified_Ideographs_Extension_A}
                              \p{Block=CJK_Unified_Ideographs_Extension_B}
                              \p{Hiragana}\p{Katakana}\p{Hangul}\x{30fc}
                              \x{3002}
                              \x{ff0c}
                      ]/x;

sub _wrap {
    my ($is_mb, $text, $width, $opts) = @_;
    $width //= 80;
    $opts  //= {};

    # our algorithm: split into paragraphs, then process each paragraph. at the
    # start of paragraph, determine indents (either from %opts, or deduced from
    # text, like in Emacs) then push first-line indent. proceed to push words,
    # while adding subsequent-line indent at the start of each line.

    my $tw = $opts->{tab_width} // 8;
    die "Please specify a positive tab width" unless $tw > 0;
    my $optfli  = $opts->{flindent};
    my $optfliw = defined $optfli ? _get_indent_width($is_mb, $optfli, $tw) : undef;
    my $optsli  = $opts->{slindent};
    my $optsliw = defined $optsli ? _get_indent_width($is_mb, $optsli, $tw) : undef;
    my $optkts  = $opts->{keep_trailing_space} // 0;
    my @res;

    my @para = split /(\n(?:[ \t]*\n)+)/, $text;
    #say "D:para=[",join(", ", @para),"]";

    my ($maxww, $minww);

  PARA:
    while (my ($ptext, $pbreak) = splice @para, 0, 2) {
        my $x = 0;
        my $y = 0;
        my $line_has_word = 0;

        # determine indents
        my ($fli, $sli, $fliw, $sliw);
        if (defined $optfli) {
            $fli  = $optfli;
            $fliw = $optfliw;
        } else {
            # XXX emacs can also treat ' #' as indent, e.g. when wrapping
            # multi-line perl comment.
            ($fli) = $ptext =~ /\A([ \t]*)\S/;
            if (defined $fli) {
                $fliw = _get_indent_width($is_mb, $fli, $tw);
            } else {
                $fli  = "";
                $fliw = 0;
            }
        }
        if (defined $optsli) {
            $sli  = $optsli;
            $sliw = $optsliw;
        } else {
            ($sli) = $ptext =~ /\A[^\n]*\S[\n]([ \t+]*)\S/;
            if (defined $sli) {
                $sliw = _get_indent_width($is_mb, $sli, $tw);
            } else {
                $sli  = "";
                $sliw = 0;
            }
        }
        die "Subsequent indent must be less than width" if $sliw >= $width;

        push @res, $fli;
        $x += $fliw;

        my @words0; # (WORD1, WORD1_IS_CJK?, WS_AFTER?, WORD2, WORD2_IS_CJK?, WS_AFTER?, ...)
        # we differentiate/split between CJK "word" (cluster of CJK letters,
        # really) and non-CJK word, e.g. "我很爱你my可爱的and beautiful,
        # beautiful wife" is split to ["我很爱你", "my", "可爱的", "and",
        # "beautiful,", "beautiful", "wife"]. we do this because CJK word can be
        # line-broken on a per-letter basis, as they don't separate words with
        # whitespaces.
        while ($ptext =~ /(?: ($re_cjk+)|(\S+) ) (\s*)/gox) {
            my $ws_after = $3 ? 1:0;
            if ($1) {
                push @words0, $1, 1, $ws_after;
            } else {
                my $ptext2 = $2;
                while ($ptext2 =~ /($re_cjk_class+)|
                                   ($re_cjk_negclass+)/gox) {
                    if ($1) {
                        push @words0, $1, 1, 0;
                    } else {
                        push @words0, $2, 0, 0;
                    }
                }
                $words0[-1] = $ws_after;
            }
        }

        # process each word
        my $prev_ws_after;
        while (@words0) {
            my ($word0, $is_cjk, $ws_after) = splice @words0, 0, 3;
            my @words;
            my @wordsw;
            while (1) {
                my $wordw = $is_mb ? mbswidth($word0) : length($word0);

                # long cjk word is not truncated here because it will be
                # line-broken later when wrapping.
                if ($wordw <= $width-$sliw || $is_cjk) {
                    push @words , $word0;
                    push @wordsw, $wordw;
                    last;
                }
                # truncate long word
                if ($is_mb) {
                    my $res = mbtrunc($word0, $width-$sliw, 1);
                    push @words , $res->[0];
                    push @wordsw, $res->[1];
                    $word0 = substr($word0, length($res->[0]));
                    #say "D:truncated long word (mb): $text -> $res->[0] & $res->[1], word0=$word0";
                } else {
                    my $w2 = substr($word0, 0, $width-$sliw);
                    push @words , $w2;
                    push @wordsw, $width-$sliw;
                    $word0 = substr($word0, $width-$sliw);
                    #say "D:truncated long word: $w2, ".($width-$sliw).", word0=$word0";
                }
            }

            for my $word (@words) {
                my $wordw = shift @wordsw;
                #say "D:x=$x word=$word is_cjk=$is_cjk ws_after=$ws_after wordw=$wordw line_has_word=$line_has_word width=$width";

                $maxww = $wordw if !defined($maxww) || $maxww < $wordw;
                $minww = $wordw if !defined($minww) || $minww > $wordw;

                my $x_after_word = $x + ($line_has_word ? 1:0) + $wordw;
                if ($x_after_word <= $width) {
                    # the addition of word hasn't exceeded column width
                    if ($line_has_word) {
                        if ($prev_ws_after) {
                            push @res, " ";
                            $x++;
                        }
                    }
                    push @res, $word;
                    $x += $wordw;
                } else {
                    while (1) {
                        if ($is_cjk) {
                            # CJK word can be broken
                            my $res;
                            if ($prev_ws_after) {
                                $res = mbtrunc($word, $width - $x - 1, 1);
                                push @res, " ", $res->[0];
                            } else {
                                $res = mbtrunc($word, $width - $x, 1);
                                push @res, $res->[0];
                            }
                            my $word2 = substr($word, length($res->[0]));
                            #say "D:truncated CJK word: $word -> $res->[0] & $res->[1], remaining=$word2";
                            $prev_ws_after = 0;
                            $word = $word2;
                            $wordw = mbswidth($word);
                        }

                        # move the word to the next line
                        push @res, " " if $prev_ws_after && $optkts;
                        push @res, "\n", $sli;
                        $y++;

                        if ($sliw + $wordw <= $width) {
                            push @res, $word;
                            $x = $sliw + $wordw;
                            last;
                        } else {
                            # still too long, truncate again
                            $x = $sliw;
                        }
                    }
                }
                $line_has_word++;
            }
            $prev_ws_after = $ws_after;
        }

        if (defined $pbreak) {
            push @res, $pbreak;
        } else {
            push @res, "\n" if $ptext =~ /\n[ \t]*\z/;
        }
    }

    if ($opts->{return_stats}) {
        return [join("", @res), {
            max_word_width => $maxww,
            min_word_width => $minww,
        }];
    } else {
        return join("", @res);
    }
}

sub mbwrap {
    _wrap(1, @_);
}

sub wrap {
    _wrap(0, @_);
}

sub _pad {
    my ($is_mb, $text, $width, $which, $padchar, $is_trunc) = @_;
    if ($which) {
        $which = substr($which, 0, 1);
    } else {
        $which = "r";
    }
    $padchar //= " ";

    my $w = $is_mb ? mbswidth($text) : length($text);
    if ($is_trunc && $w > $width) {
        my $res = mbtrunc($text, $width, 1);
        $text = $res->[0] . ($padchar x ($width-$res->[1]));
    } else {
        if ($which eq 'l') {
            $text = ($padchar x ($width-$w)) . $text;
        } elsif ($which eq 'c') {
            my $n = int(($width-$w)/2);
            $text = ($padchar x $n) . $text . ($padchar x ($width-$w-$n));
        } else {
            $text .= ($padchar x ($width-$w));
        }
    }
    $text;
}

sub mbpad {
    _pad(1, @_);
}

sub pad {
    _pad(0, @_);
}

sub _trunc {
    my ($is_mb, $text, $width, $return_width) = @_;

    # return_width (undocumented): if set to 1, will return [truncated_text,
    # visual width, length(chars) up to truncation point]

    my $w = $is_mb ? mbswidth($text) : length($text);
    die "Invalid argument, width must not be negative" unless $width >= 0;
    if ($w <= $width) {
        return $return_width ? [$text, $w, length($text)] : $text;
    }

    my $c = 0;

    # perform binary cutting
    my @res;
    my $wres = 0; # total width of text in @res
    my $l = int($w/2); $l = 1 if $l == 0;
    my $end = 0;
    while (1) {
        my $left  = substr($text, 0, $l);
        my $right = $l > length($text) ? "" : substr($text, $l);
        my $wl = $is_mb ? mbswidth($left) : length($left);
        #say "D:left=$left, right=$right, wl=$wl";
        if ($wres + $wl > $width) {
            $text = $left;
        } else {
            push @res, $left;
            $wres += $wl;
            $c += length($left);
            $text = $right;
        }
        $l = int(($l+1)/2);
        #say "D:l=$l";
        last if $l==1 && $end>1;
        $end++ if $l==1;
    }
    if ($return_width) {
        return [join("", @res), $wres, $c];
    } else {
        return join("", @res);
    }
}

sub mbtrunc {
    _trunc(1, @_);
}

sub trunc {
    _trunc(0, @_);
}

1;
# ABSTRACT: Routines for text containing wide characters

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::WideChar::Util - Routines for text containing wide characters

=head1 VERSION

This document describes version 0.170 of Text::WideChar::Util (from Perl distribution Text-WideChar-Util), released on 2019-05-17.

=head1 SYNOPSIS

 use Text::WideChar::Util qw(
     mbpad pad mbswidth mbswidth_height mbtrunc trunc mbwrap wrap);

 # get width as well as number of lines
 say mbswidth_height("red\n红色"); # => [4, 2]

 # wrap text to a certain column width
 say mbwrap("....", 40);

 # pad (left, right, center) text to specified column width, handle multilines
 say mbpad("foo", 10);                          # => "foo       "
 say mbpad("红色", 10, "left");                 # => "      红色"
 say mbpad("foo\nbarbaz\n", 10, "center", "."); # => "...foo....\n..barbaz..\n"

 # truncate text to a certain column width
 say mbtrunc("红色",  2); # => "红"
 say mbtrunc("红色",  3); # => "红"
 say mbtrunc("红red", 3); # => "红r"

=head1 DESCRIPTION

This module provides routines for dealing with text containing wide characters
(wide meaning occupying more than 1 column width in terminal).

=head1 INTERNAL NOTES

Should we wrap at hyphens? Probably not. Both Emacs as well as Text::Wrap do
not.

=head1 FUNCTIONS

=head2 mbswidth($text) => INT

Like L<Text::CharWidth>'s mbswidth(), except implemented using L<<
Unicode::GCString->new($text)->columns >>.

=head2 mbswidth_height($text) => [INT, INT]

Like mbswidth(), but also gives height (number of lines). For example, C<<
mbswidth_height("foobar\nb\n") >> gives [6, 3].

=head2 length_height($text) => [INT, INT]

This is the non-wide version of mbswidth_height() and can be used if your text
only contains printable ASCII characters and newlines.

=head2 mbwrap($text, $width, \%opts) => STR

Wrap C<$text> to C<$width> columns. Replaces multiple whitespaces with a single
space.

It uses mbswidth() instead of Perl's length() which works on a per-character
basis. Has some support for wrapping Kanji/CJK (Chinese/Japanese/Korean) text
which do not have whitespace between words.

Options:

=over

=item * tab_width => INT (default: 8)

Set tab width.

Note that tab will only have effect on the indent. Tab between text will be
replaced with a single space.

=item * flindent => STR

First line indent. If unspecified, will be deduced from the first line of text.

=item * slindent => STD

Subsequent line indent. If unspecified, will be deduced from the second line of
text, or if unavailable, will default to empty string (C<"">).

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

Performance: ~450/s on my Core i5 1.7GHz laptop for a 1KB of text.

=head2 wrap($text, $width, \%opts) => STR

Like mbwrap(), but uses character-based length() instead of column width-wise
mbswidth(). Provided as an alternative to the venerable L<Text::Wrap>'s wrap()
but with a different behaviour. This module's wrap() can reflow newline and its
behavior is more akin to Emacs (try reflowing a paragraph in Emacs using
C<M-q>).

Performance: ~2000/s on my Core i5 1.7GHz laptop for a ~1KB of text.
Text::Wrap::wrap() on the other hand is ~2500/s.

=head2 mbpad($text, $width[, $which[, $padchar[, $truncate]]]) => STR

Return C<$text> padded with C<$padchar> to C<$width> columns. C<$which> is
either "r" or "right" for padding on the right (the default if not specified),
"l" or "left" for padding on the right, or "c" or "center" or "centre" for
left+right padding to center the text.

C<$padchar> is whitespace if not specified. It should be string having the width
of 1 column.

=head2 pad($text, $width[, $which[, $padchar[, $truncate]]]) => STR

The non-wide version of mbpad(), just like in mbwrap() vs wrap().

=head2 mbtrunc($text, $width) => STR

Truncate C<$text> to C<$width> columns. It uses mbswidth() instead of Perl's
length(), so it can handle wide characters.

Does *not* handle multiple lines.

=head2 trunc($text, $width) => STR

The non-wide version of mbtrunc(), just like in mbwrap() vs wrap(). This is
actually not much more than Perl's C<< substr($text, 0, $width) >>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-WideChar-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-WideChar-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-WideChar-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Unicode::GCString> which is consulted for visual width of characters.
L<Text::CharWidth> is about 2.5x faster but it gives weird results (-1 for
characters like "\n" and "\t") and my Strawberry Perl installation fails to
build it.

L<Text::ANSI::Util> which can also handle text containing wide characters as
well ANSI escape codes.

L<Text::WrapI18N> which provides an alternative to wrap()/mbwrap() with
comparable speed, though wrapping result might differ slightly. And the module
currently uses Text::CharWidth.

L<Text::NonWideChar::Util> contains non-wide version of some of the
abovementioned routines (the non-wide version of the routines will eventually be
moved here).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
