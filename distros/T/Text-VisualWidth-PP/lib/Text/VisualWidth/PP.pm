package Text::VisualWidth::PP;
use strict;
use warnings;
use 5.008001;
use parent qw(Exporter);
our $VERSION = '0.09';
our @EXPORT_OK = qw(vwidth vtrim);

# The East_Asian_Width property of perl follows the Unicode version
# of the perl in use, while the table of Unicode::EastAsianWidth is
# Unicode 12.0 and does not know the characters added since (U+1FAAA
# IDENTIFICATION CARD, for example), which it gives no width.  Use
# the property of perl when it is newer than the table: perl 5.30 is
# the first with Unicode 12.1.  Older perls use the table.
use constant BUILTIN_EAW => $^V ge v5.30;

BEGIN {
    unless (BUILTIN_EAW) {
	require Unicode::EastAsianWidth;
	Unicode::EastAsianWidth->import;
    }
}

# for backward compatibility, see the POD
our $EastAsian = do { no warnings 'once'; $Unicode::EastAsianWidth::EastAsian };

# Each class as a user-defined property body: the built-in property,
# or the table of Unicode::EastAsianWidth.
sub EAW {
    my $class = shift;
    if (BUILTIN_EAW) {
	"+utf8::East_Asian_Width=$class\n";
    } else {
	no strict 'refs';
	&{"InEastAsian$class"}();
    }
}

# The Emoji_Modifier property came to perl in 5.32 with Unicode 13.0.
# Spacing refers to it as utf8::Is_Emoji_Modifier: on 5.32 and later
# that is the built-in property, and older perls get this user-defined
# property of the same name, with the code points as of the Unicode
# versions those perls know.
if ($^V lt v5.32) {
    no strict 'refs';
    *{"utf8::Is_Emoji_Modifier"} = sub { "1F3FB\t1F3FF\n" };
};

sub Spacing {
    $_[0] . <<END
-utf8::Nonspacing_Mark
-utf8::Enclosing_Mark
-utf8::Default_Ignorable_Code_Point
-utf8::Is_Emoji_Modifier
END
}

sub InVWPP1Fullwidth() {
    Spacing
    EAW('Fullwidth') . EAW('Wide') . EAW('Ambiguous')
}
sub InVWPP0Fullwidth() {
    Spacing
    EAW('Fullwidth') . EAW('Wide')
}
sub InVWPP1Halfwidth() {
    Spacing
    EAW('Halfwidth') . EAW('Narrow') . EAW('Neutral')
}
sub InVWPP0Halfwidth() {
    Spacing
    EAW('Halfwidth') . EAW('Narrow') . EAW('Neutral') . EAW('Ambiguous')
}

sub vwidth { width(@_) }
sub vtrim  {  trim(@_) }

# E_Modifier not following E_Base has full-width visual representation
my $EM = $^V ge v5.28 ? '(?>(?<!\p{Line_Break=E_Base})\p{Line_Break=E_Modifier})'
                      : '(?!)' ;
$EM = qr/$EM/; # to avoid error on v5.24

# Each character counts by its class, full or half width, except one
# after ZERO WIDTH JOINER (U+200D): it joins the one before it in an
# emoji sequence and adds no width.
#
# Compiled once.  With $EM interpolated next to \N{U+200D}, perl parses
# the pattern on every match before it finds that it has not changed,
# which for a short string takes several times longer than the match.
my @WIDTH_RE = map {
    qr/((?:$EM|(?<!\N{U+200D})\p{InVWPP${_}Fullwidth})+)
      |((?:    (?<!\N{U+200D})\p{InVWPP${_}Halfwidth})+)/x
} 0, 1;

sub width {
    my $str = shift;
    my $re = $WIDTH_RE[$EastAsian ? 1 : 0];
    my $ret = 0;
    while ($str =~ /$re/g) {
        $ret += $1 ? length($1) * 2 : length($2)
    }
    $ret;
}

sub trim {
    my ($str, $limit) = @_;

    my $cnt = 0;
    my $ret = '';
    my $fullwidth = $EastAsian ? qr/\p{InVWPP1Fullwidth}/ : qr/\p{InVWPP0Fullwidth}/;
    while ($str =~ /\G(\X)/g) {
        my $ch = $1;
        my $w = do {
            if ($ch =~ /\A$fullwidth\z/) {
                2;
            } elsif (length($ch) == 1) {
                1;
            } else {
                width($ch);
            }
        };
        if ($cnt+$w <= $limit) {
            $ret .= $ch;
            $cnt += $w;
        } else {
            last;
        }
    }
    $ret;
}

1;
__END__

=for stopwords ambw

=encoding utf8

=head1 NAME

Text::VisualWidth::PP - trimming text by the number of the columns of terminals and mobile phones.

=head1 SYNOPSIS

    use utf8;
    use Text::VisualWidth::PP;

    Text::VisualWidth::PP::width("あいうえおaiu"); # => 13
    Text::VisualWidth::PP::trim("あいうえおaiu", 7); # => "あいう"

    # with exporter
    use Text::VisualWidth::PP qw(vwidth vtrim);
    vwidth("あいうえおaiu"); # => 13
    vtrim("あいうえおaiu", 7); # => "あいう"

=head1 DESCRIPTION

This module provides functions to treat half-width and full-width characters and display correct size of text in one line on terminals and mobile phones. You can know the visual width of any text and truncate text by the visual width. Now this module support flagged UTF-8 and tested only with Japanese.

This module is pure perl version of L<Text::VisualWidth>. This is bit slow, but it's not require compiler.

=head1 Ambiguous Characters

This module treats ambiguous characters are half width by default.

And you can specify the behavior by the C<$Text::VisualWidth::PP::EastAsian> flag expressly.

Note: If C<$Unicode::EastAsianWidth::EastAsian> is true on compilation time, this module set C<$Text::VisualWidth::PP::EastAsian> as true for backward compatibility.


If you want to detect the ambw parameter from users' environment, please look L<Unicode::EastAsianWidth::Detect>.

=head1 Unicode Version

On perl 5.30 and later, the width classes come from the
C<East_Asian_Width> property of perl itself, so they follow the
Unicode version of the perl in use (see L<perluniprops>).  On older
Perl versions, the table of L<Unicode::EastAsianWidth> (Unicode 12.0)
is used, which is newer than the Unicode version of those Perl versions.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Text::VisualWidth>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
