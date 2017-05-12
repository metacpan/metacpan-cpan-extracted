package Text::UpsideDown;
use 5.008;
use strict;
use warnings;
use charnames qw(:full);
use Exporter qw(import);
our @EXPORT = qw(upside_down);
# ABSTRACT: Flip text upside-down using Unicode
our $VERSION = '1.22'; # VERSION


# Mapping taken from:
#  - http://www.fileformat.info/convert/text/upside-down-map.htm
#  - http://en.wikipedia.org/wiki/Transformation_of_text
#  - http://www.upsidedowntext.com/unicode
#
# Letters that don't change in upside-down view (like 'H', 'I') aren't given.
our %upside_down_map = (
    'A'            => "\N{FOR ALL}",
    'B'            => "\N{GREEK SMALL LETTER XI}",
    'C'            => "\N{ROMAN NUMERAL REVERSED ONE HUNDRED}",
    'D'            => "\N{LEFT HALF BLACK CIRCLE}",
    'E'            => "\N{LATIN CAPITAL LETTER REVERSED E}",
    'F'            => "\N{TURNED CAPITAL F}",
    'G'            => "\N{TURNED SANS-SERIF CAPITAL G}",
    'J'            => "\N{LATIN SMALL LETTER LONG S}",
    'K'            => "\N{RIGHT NORMAL FACTOR SEMIDIRECT PRODUCT}",
    'L'            => "\N{TURNED SANS-SERIF CAPITAL L}",
    'M'            => 'W',
    'N'            => "\N{LATIN LETTER SMALL CAPITAL REVERSED N}",
    'P'            => "\N{CYRILLIC CAPITAL LETTER KOMI DE}",
    'Q'            => "\N{GREEK CAPITAL LETTER OMICRON WITH TONOS}",
    'R'            => "\N{LATIN LETTER SMALL CAPITAL TURNED R}",
    'T'            => "\N{UP TACK}",
    'U'            => "\N{INTERSECTION}",
    'V'            => "\N{GREEK LETTER SMALL CAPITAL LAMDA}",
    'Y'            => "\N{TURNED SANS-SERIF CAPITAL Y}",
    'a'            => "\N{LATIN SMALL LETTER TURNED A}",
    'b'            => 'q',
    'c'            => "\N{LATIN SMALL LETTER OPEN O}",
    'd'            => 'p',
    'e'            => "\N{LATIN SMALL LETTER TURNED E}",
    'f'            => "\N{LATIN SMALL LETTER DOTLESS J WITH STROKE}",
    'g'            => "\N{LATIN SMALL LETTER B WITH TOPBAR}",
    'h'            => "\N{LATIN SMALL LETTER TURNED H}",
    'i'            => "\N{LATIN SMALL LETTER DOTLESS I}",
    'j'            => "\N{LATIN SMALL LETTER R WITH FISHHOOK}",
    'k'            => "\N{LATIN SMALL LETTER TURNED K}",
    'l'            => "\N{LATIN SMALL LETTER ESH}",
    'm'            => "\N{LATIN SMALL LETTER TURNED M}",
    'n'            => 'u',
    'r'            => "\N{LATIN SMALL LETTER TURNED R}",
    't'            => "\N{LATIN SMALL LETTER TURNED T}",
    'v'            => "\N{LATIN SMALL LETTER TURNED V}",
    'w'            => "\N{LATIN SMALL LETTER TURNED W}",
    'y'            => "\N{LATIN SMALL LETTER TURNED Y}",

    '!' => "\N{INVERTED EXCLAMATION MARK}",
    '"' => "\N{DOUBLE LOW-9 QUOTATION MARK}",
    '&' => "\N{TURNED AMPERSAND}",
    q{'} => ',',
    '.' => "\N{DOT ABOVE}",
    '^' => "\N{LOGICAL OR}",
    '*' => "\N{LOW ASTERISK}",
    '1' => "\N{DOWNWARDS HARPOON WITH BARB RIGHTWARDS}",
    '3' => "\N{LATIN CAPITAL LETTER OPEN E}",
    '6' => '9',
    '7' => "\N{BOPOMOFO LETTER ENG}",
    ';' => "\N{ARABIC SEMICOLON}",
    '?' => "\N{INVERTED QUESTION MARK}",
    '(' => ')',
    '[' => ']',
    '{' => '}',
    '<' => '>',
    '_' => "\N{OVERLINE}",
    "\N{UNDERTIE}"  => "\N{CHARACTER TIE}",
    "\N{LEFT SQUARE BRACKET WITH QUILL}" => "\N{RIGHT SQUARE BRACKET WITH QUILL}",
    "\N{THEREFORE}" => "\N{BECAUSE}",
);
%upside_down_map = (%upside_down_map, reverse %upside_down_map);


my $tr = eval( ## no critic (BuiltinFunctions::ProhibitStringyEval)
    sprintf 'sub { tr/%s/%s/ }',
        map { quotemeta join '', @{ $_ } }
        [ keys %upside_down_map ], [ values %upside_down_map ]
);

sub upside_down {
    my $text = shift;
    $tr->() for $text;
    return scalar reverse $text;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Text::UpsideDown - Flip text upside-down using Unicode

=head1 VERSION

version 1.22

=head1 SYNOPSIS

    use Text::UpsideDown;
    print upside_down("marcel gruenauer");

=head1 DESCRIPTION

This module exports only one function: C<upside_down>.

=head1 FUNCTIONS

=head2 upside_down

Takes a string and returns a string that looks like the characters have been
turned upside-down and reversed so it could be read by turning your head
upside-down. It uses special Unicode characters originally intended for
mathematics and the like.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Text-UpsideDown/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Text::UpsideDown/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Text-UpsideDown>
and may be cloned from L<git://github.com/doherty/Text-UpsideDown.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Text-UpsideDown/issues>.

=head1 AUTHORS

=over 4

=item *

Mike Doherty <doherty@cpan.org>

=item *

Marcel Grünauer <marcel@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Grünauer and Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
