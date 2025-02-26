package Text::VisualWidth::PP;
use strict;
use warnings;
use 5.008001;
use parent qw(Exporter);
our $VERSION = '0.08';
use Unicode::EastAsianWidth;

our @EXPORT_OK = qw(vwidth vtrim);

our $EastAsian = $Unicode::EastAsianWidth::EastAsian;

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
    InEastAsianFullwidth() . InEastAsianWide() . InEastAsianAmbiguous()
}
sub InVWPP0Fullwidth() {
    Spacing
    InEastAsianFullwidth() . InEastAsianWide()
}
sub InVWPP1Halfwidth() {
    Spacing
    InEastAsianHalfwidth().
    InEastAsianNarrow().
    InEastAsianNeutral()
}
sub InVWPP0Halfwidth() {
    Spacing
    InEastAsianHalfwidth().
    InEastAsianNarrow().
    InEastAsianNeutral().
    InEastAsianAmbiguous()
}

sub vwidth { width(@_) }
sub vtrim  {  trim(@_) }

# E_Modifier not following E_Base has full-width visual representation
my $EM = $^V ge v5.28 ? '(?>(?<!\p{Line_Break=E_Base})\p{Line_Break=E_Modifier})'
                      : '(?!)' ;
$EM = qr/$EM/; # to avoid error on v5.24

sub width {
    my $str = shift;

    my $ret = 0;
    if ($EastAsian) {
        while ($str =~ /((?:$EM|(?<!\N{U+200D})\p{InVWPP1Fullwidth})+)
                       |((?:    (?<!\N{U+200D})\p{InVWPP1Halfwidth})+)/xg) {
            $ret += $1 ? length($1) * 2 : length($2)
        }
    } else {
        while ($str =~ /((?:$EM|(?<!\N{U+200D})\p{InVWPP0Fullwidth})+)
                       |((?:    (?<!\N{U+200D})\p{InVWPP0Halfwidth})+)/xg) {
            $ret += $1 ? length($1) * 2 : length($2)
        }
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

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Text::VisualWidth>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
