package Text::UnicodeStyle;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our $VERSION = '0.01';
our @EXPORT_OK = qw( styles stylize );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my %STYLE_MODS = (
    bold                    => 'Text::UnicodeStyle::Bold',
    bold_fraktur            => 'Text::UnicodeStyle::BoldFraktur',
    bold_italic             => 'Text::UnicodeStyle::BoldItalic',
    bold_script             => 'Text::UnicodeStyle::BoldScript',
    circled                 => 'Text::UnicodeStyle::Circled',
    doublestruck            => 'Text::UnicodeStyle::Doublestruck',
    fraktur                 => 'Text::UnicodeStyle::Fraktur',
    fullwidth               => 'Text::UnicodeStyle::Fullwidth',
    italic                  => 'Text::UnicodeStyle::Italic',
    monospace               => 'Text::UnicodeStyle::Monospace',
    negative_circled        => 'Text::UnicodeStyle::NegativeCircled',
    negative_squared        => 'Text::UnicodeStyle::NegativeSquared',
    parenthesized           => 'Text::UnicodeStyle::Parenthesized',
    sans_serif              => 'Text::UnicodeStyle::SansSerif',
    sans_serif_bold         => 'Text::UnicodeStyle::SansSerifBold',
    sans_serif_bold_italic  => 'Text::UnicodeStyle::SansSerifBoldItalic',
    sans_serif_italic       => 'Text::UnicodeStyle::SansSerifItalic',
    script                  => 'Text::UnicodeStyle::Script',
    squared                 => 'Text::UnicodeStyle::Squared',
);

my %TABLES;

sub _module_for {
    my ($style) = @_;
    return $STYLE_MODS{$style};
}

sub _table {
    my ($style) = @_;
    my $mod = _module_for($style)
        or die "Unknown style '$style'. Available: " . join(', ', styles()) . "\n";
    $TABLES{$style} //= do {
        eval "require $mod" or die $@;
        $mod->table;
    };
    return $TABLES{$style};
}

sub styles {
    return sort keys %STYLE_MODS;
}

sub stylize {
    my ($s, $style) = @_;
    my $t = _table($style);

    my $out = $s;
    $out =~ s{
        ([!-~])
    }{
        my $c = $1;
        if ($t->{fix} && exists $t->{fix}{$c}) {
            chr $t->{fix}{$c};
        }
        elsif ($c ge 'A' && $c le 'Z' && $t->{upper}) {
            chr($t->{upper} + ord($c) - ord('A'));
        }
        elsif ($c ge 'a' && $c le 'z' && $t->{lower}) {
            chr($t->{lower} + ord($c) - ord('a'));
        }
        elsif ($c ge '0' && $c le '9' && $t->{digit}) {
            chr($t->{digit} + ord($c) - ord('0'));
        }
        elsif ($t->{punct} && $c ge '!' && $c le '~') {
            chr(ord($c) + $t->{punct});
        }
        else {
            $c;
        }
    }gex;

    return $out;
}

1;

__END__

=head1 NAME

=encoding utf8

Text::UnicodeStyle - replace Latin letters with lookalike characters
from other Unicode ranges (mathematical alphanumeric symbols, etc.)

=head1 SYNOPSIS

    use Text::UnicodeStyle qw( stylize styles );

    say stylize('route_id', 'monospace');   # 𝐫𝐨𝐮𝐭𝐞_𝐢𝐝
    say join ', ', styles();                # doublestruck, fraktur, ...

=head1 DESCRIPTION

C<stylize> returns a copy of the input string where every ASCII letter
C<A-Z> and C<a-z> is replaced by the corresponding character of the
requested style. In styles that define digit mappings (C<bold>,
C<circled>, C<doublestruck>, C<fullwidth>, C<monospace>,
C<parenthesized>, C<sans_serif>, C<sans_serif_bold>) digits C<0-9>
are replaced as well; elsewhere they are left unchanged. In the
C<fullwidth> style all printable ASCII punctuation C<!-~> is mapped
to its fullwidth form as well (including C<_>); in all other styles
punctuation is left unchanged. Spaces and already non-ASCII text are
always left untouched.

Each style is defined by a base code point for uppercase and lowercase
letters (either may be absent — e.g. C<squared>, C<negative_circled>
and C<negative_squared> only cover uppercase) plus an optional C<fix>
table of exceptions (characters whose Unicode position does not follow
the contiguous range). Some styles also define a C<digit> base code
point, which enables substitution of digits 0-9 — currently
C<bold>, C<circled>, C<doublestruck>, C<fullwidth>, C<monospace>,
C<parenthesized>, C<sans_serif> and C<sans_serif_bold>. The
C<fullwidth> style additionally defines C<punct>, an additive offset
applied to printable ASCII characters not covered by the other keys.
In all other styles digits and punctuation are left unchanged. Note
that C<parenthesized> has no glyph for digit 0, so it stays unchanged
there. Style tables live in L<Text::UnicodeStyle::*> modules and are
loaded lazily.

=head1 FUNCTIONS

=head2 stylize($string, $style)

Returns a new string with letters substituted. Dies on unknown style.
The input string is not modified.

=head2 styles()

Returns the sorted list of available style names.

=head1 STYLES

=over

=item bold, bold_fraktur, bold_italic, bold_script

=item circled, doublestruck, fraktur, fullwidth

=item italic, monospace

=item negative_circled, negative_squared (uppercase only)

=item parenthesized

=item sans_serif, sans_serif_bold, sans_serif_bold_italic, sans_serif_italic

=item script

=item squared (uppercase only)

=back

=head1 SEE ALSO

L<example.pl> in the project repository for a runnable demo.

Project repository: L<https://github.com/shoorick/substitute-letters>

Bug reports and other issues: L<https://github.com/shoorick/substitute-letters/issues>

=head1 VERSION

This library version is 0.01.

=head1 LICENSE

L<https://opensource.org/licenses/MIT|MIT>

=cut
