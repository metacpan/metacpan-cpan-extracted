package Unicode::Homoglyph;

our $DATE = '2015-10-25'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

our @Homoglyphs = (

    {
        "\x{0020}" => "", #   # SPACE
        "\x{00A0}" => "", # NO-BREAK SPACE
        "\x{2000}" => "", # EN QUAD
        "\x{2001}" => "", # EM QUAD
        "\x{2002}" => "", # EN SPACE
        "\x{2003}" => "", # EM SPACE
        "\x{2004}" => "", # THREE-PER-EM SPACE
        "\x{2005}" => "", # FOUR-PER-EM SPACE
        "\x{2006}" => "", # SIX-PER-EM SPACE
        "\x{2007}" => "", # FIGURE SPACE
        "\x{2008}" => "", # PUNCTUATION SPACE
        "\x{2009}" => "", # THIN SPACE
        "\x{200A}" => "", # HAIR SPACE
        "\x{202F}" => "", # NARROW NO-BREAK SPACE
        "\x{205F}" => "", # MEDIUM MATHEMATICAL SPACE
    },

    {
        "\x{0021}" => "", # ! # EXCLAMATION MARK
        "\x{01C3}" => "", # LATIN LETTER RETROFLEX CLICK
        "\x{2D51}" => "", # TIFINAGH LETTER TUAREG YANG
        "\x{FE15}" => "", # PRESENTATION FORM FOR VERTICAL EXCLAMATION MARK
        "\x{FE57}" => "", # SMALL EXCLAMATION MARK
        "\x{FF01}" => "", # FULLWIDTH EXCLAMATION MARK
    },

    {
        "\x{0022}" => "", # " # QUOTATION MARK
        "\x{FF02}" => "", # FULLWIDTH QUOTATION MARK
    },

    {
        "\x{0023}" => "", # # # NUMBER SIGN
        "\x{FE5F}" => "", # SMALL NUMBER SIGN
        "\x{FF03}" => "", # FULLWIDTH NUMBER SIGN
    },

    {
        "\x{0024}" => "", # $ # DOLLAR SIGN
        "\x{FE69}" => "", # SMALL DOLLAR SIGN
        "\x{FF04}" => "", # FULLWIDTH DOLLAR SIGN
    },

    {
        "\x{0025}" => "", # % # PERCENT SIGN
        "\x{066A}" => "", # ARABIC PERCENT SIGN
        "\x{2052}" => "", # COMMERCIAL MINUS SIGN
        "\x{FE6A}" => "", # SMALL PERCENT SIGN
        "\x{FF05}" => "", # FULLWIDTH PERCENT SIGN
    },

    {
        "\x{0026}" => "", # & # AMPERSAND
        "\x{FE60}" => "", # SMALL AMPERSAND
        "\x{FF06}" => "", # FULLWIDTH AMPERSAND
    },

    {
        "\x{0027}" => "", # ' # APOSTROPHE
        "\x{02B9}" => "", # MODIFIER LETTER PRIME
        "\x{0374}" => "", # GREEK NUMERAL SIGN
        "\x{FF07}" => "", # FULLWIDTH APOSTROPHE
    },

    {
        "\x{0028}" => "", # ( # LEFT PARENTHESIS
        "\x{FE59}" => "", # SMALL LEFT PARENTHESIS
        "\x{FF08}" => "", # FULLWIDTH LEFT PARENTHESIS
    },

    {
        "\x{0029}" => "", # ) # RIGHT PARENTHESIS
        "\x{FF09}" => "", # FULLWIDTH RIGHT PARENTHESIS
        "\x{FE5A}" => "", # SMALL RIGHT PARENTHESIS
    },

    {
        "\x{002A}" => "", # * # ASTERISK
        "\x{22C6}" => "", # STAR OPERATOR
        "\x{FE61}" => "", # SMALL ASTERISK
        "\x{FF0A}" => "", # FULLWIDTH ASTERISK
    },

    {
        "\x{002B}" => "", # + # PLUS SIGN
        "\x{16ED}" => "", # RUNIC CROSS PUNCTUATION
        "\x{FE62}" => "", # SMALL PLUS SIGN
        "\x{FF0B}" => "", # FULLWIDTH PLUS SIGN
    },

    {
        "\x{002C}" => "", # , # COMMA
        "\x{02CF}" => "", # MODIFIER LETTER LOW ACUTE ACCENT
        "\x{16E7}" => "", # RUNIC LETTER SHORT-TWIG-YR
        "\x{201A}" => "", # SINGLE LOW-9 QUOTATION MARK
        "\x{FF0C}" => "", # FULLWIDTH COMMA
    },

    {
        "\x{002D}" => "", # - # HYPHEN-MINUS
        "\x{02D7}" => "", # MODIFIER LETTER MINUS SIGN
        "\x{2212}" => "", # MINUS SIGN
        "\x{23BC}" => "", # HORIZONTAL SCAN LINE-7
        "\x{2574}" => "", # BOX DRAWINGS LIGHT LEFT
        "\x{FE63}" => "", # SMALL HYPHEN-MINUS
        "\x{FF0D}" => "", # FULLWIDTH HYPHEN-MINUS
    },

    {
        "\x{002E}" => "", # . # FULL STOP
        "\x{2024}" => "", # ONE DOT LEADER
        "\x{FF0E}" => "", # FULLWIDTH FULL STOP
    },

    {
        "\x{002F}" => "", # / # SOLIDUS
        "\x{FF0F}" => "", # FULLWIDTH SOLIDUS
        "\x{1735}" => "", # PHILIPPINE SINGLE PUNCTUATION
        "\x{2044}" => "", # FRACTION SLASH
        "\x{2215}" => "", # DIVISION SLASH
        "\x{29F8}" => "", # BIG SOLIDUS
    },

    {
        "\x{0032}" => "", # 2 # DIGIT TWO
        "\x{14BF}" => "", # CANADIAN SYLLABICS SAYISI M
    },

    {
        "\x{0033}" => "", # 3 # DIGIT THREE
        "\x{01B7}" => "", # LATIN CAPITAL LETTER EZH
        "\x{2128}" => "", # BLACK-LETTER CAPITAL Z
    },

    {
        "\x{0034}" => "", # 4 # DIGIT FOUR
        "\x{13CE}" => "", # CHEROKEE LETTER SE
    },

    {
        "\x{0036}" => "", # 6 # DIGIT SIX
        "\x{13EE}" => "", # CHEROKEE LETTER WV
    },

    {
        "\x{0039}" => "", # 9 # DIGIT NINE
        "\x{13ED}" => "", # CHEROKEE LETTER WU
    },

    {
        "\x{003A}" => "", # : # COLON
        "\x{02D0}" => "", # MODIFIER LETTER TRIANGULAR COLON
        "\x{02F8}" => "", # MODIFIER LETTER RAISED COLON
        "\x{0589}" => "", # ARMENIAN FULL STOP
        "\x{1361}" => "", # ETHIOPIC WORDSPACE
        "\x{16EC}" => "", # RUNIC MULTIPLE PUNCTUATION
        "\x{205A}" => "", # TWO DOT PUNCTUATION
        "\x{2236}" => "", # RATIO
        "\x{2806}" => "", # BRAILLE PATTERN DOTS-23
        "\x{FE13}" => "", # PRESENTATION FORM FOR VERTICAL COLON
        "\x{FE55}" => "", # SMALL COLON
        "\x{FF1A}" => "", # FULLWIDTH COLON
    },

    {
        "\x{003B}" => "", # ; # SEMICOLON
        "\x{037E}" => "", # GREEK QUESTION MARK
        "\x{FE14}" => "", # PRESENTATION FORM FOR VERTICAL SEMICOLON
        "\x{FE54}" => "", # SMALL SEMICOLON
        "\x{FF1B}" => "", # FULLWIDTH SEMICOLON
    },

    {
        "\x{003C}" => "", # < # LESS-THAN SIGN
        "\x{02C2}" => "", # MODIFIER LETTER LEFT ARROWHEAD
        "\x{2039}" => "", # SINGLE LEFT-POINTING ANGLE QUOTATION MARK
        "\x{227A}" => "", # PRECEDES
        "\x{276E}" => "", # HEAVY LEFT-POINTING ANGLE QUOTATION MARK ORNAMENT
        "\x{2D66}" => "", # TIFINAGH LETTER YE
        "\x{FE64}" => "", # SMALL LESS-THAN SIGN
        "\x{FF1C}" => "", # FULLWIDTH LESS-THAN SIGN
    },

    {
        "\x{003D}" => "", # = # EQUALS SIGN
        "\x{2550}" => "", # BOX DRAWINGS DOUBLE HORIZONTAL
        "\x{268C}" => "", # DIGRAM FOR GREATER YANG
        "\x{FE66}" => "", # SMALL EQUALS SIGN
        "\x{FF1D}" => "", # FULLWIDTH EQUALS SIGN
    },

    {
        "\x{003E}" => "", # > # GREATER-THAN SIGN
        "\x{02C3}" => "", # MODIFIER LETTER RIGHT ARROWHEAD
        "\x{203A}" => "", # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
        "\x{227B}" => "", # SUCCEEDS
        "\x{276F}" => "", # HEAVY RIGHT-POINTING ANGLE QUOTATION MARK ORNAMENT
        "\x{FE65}" => "", # SMALL GREATER-THAN SIGN
        "\x{FF1E}" => "", # FULLWIDTH GREATER-THAN SIGN
    },

    {
        "\x{003F}" => "", # ? # QUESTION MARK
        "\x{FE16}" => "", # PRESENTATION FORM FOR VERTICAL QUESTION MARK
        "\x{FE56}" => "", # SMALL QUESTION MARK
        "\x{FF1F}" => "", # FULLWIDTH QUESTION MARK
    },

    {
        "\x{0040}" => "", # @ # COMMERCIAL AT
        "\x{FE6B}" => "", # SMALL COMMERCIAL AT
        "\x{FF20}" => "", # FULLWIDTH COMMERCIAL AT
    },

    {
        "\x{0041}" => "", # A # LATIN CAPITAL LETTER A
        "\x{0391}" => "", # GREEK CAPITAL LETTER ALPHA
        "\x{0410}" => "", # CYRILLIC CAPITAL LETTER A
        "\x{13AA}" => "", # CHEROKEE LETTER GO
    },

    {
        "\x{0042}" => "", # B # LATIN CAPITAL LETTER B
        "\x{0392}" => "", # GREEK CAPITAL LETTER BETA
        "\x{0412}" => "", # CYRILLIC CAPITAL LETTER VE
        "\x{13F4}" => "", # CHEROKEE LETTER YV
        "\x{15F7}" => "", # CANADIAN SYLLABICS CARRIER KHE
        "\x{2C82}" => "", # COPTIC CAPITAL LETTER VIDA
    },

    {
        "\x{0043}" => "", # C # LATIN CAPITAL LETTER C
        "\x{03F9}" => "", # GREEK CAPITAL LUNATE SIGMA SYMBOL
        "\x{0421}" => "", # CYRILLIC CAPITAL LETTER ES
        "\x{13DF}" => "", # CHEROKEE LETTER TLI
        "\x{216D}" => "", # ROMAN NUMERAL ONE HUNDRED
        "\x{2CA4}" => "", # COPTIC CAPITAL LETTER SIMA
    },

    {
        "\x{0044}" => "", # D # LATIN CAPITAL LETTER D
        "\x{13A0}" => "", # CHEROKEE LETTER A
        "\x{15EA}" => "", # CANADIAN SYLLABICS CARRIER PE
        "\x{216E}" => "", # ROMAN NUMERAL FIVE HUNDRED
    },

    {
        "\x{0045}" => "", # E # LATIN CAPITAL LETTER E
        "\x{0395}" => "", # GREEK CAPITAL LETTER EPSILON
        "\x{0415}" => "", # CYRILLIC CAPITAL LETTER IE
        "\x{13AC}" => "", # CHEROKEE LETTER GV
    },

    {
        "\x{0046}" => "", # F # LATIN CAPITAL LETTER F
        "\x{15B4}" => "", # CANADIAN SYLLABICS BLACKFOOT WE
    },

    {
        "\x{0047}" => "", # G # LATIN CAPITAL LETTER G
        "\x{050C}" => "", # CYRILLIC CAPITAL LETTER KOMI SJE
        "\x{13C0}" => "", # CHEROKEE LETTER NAH
    },

    {
        "\x{0048}" => "", # H # LATIN CAPITAL LETTER H
        "\x{0397}" => "", # GREEK CAPITAL LETTER ETA
        "\x{041D}" => "", # CYRILLIC CAPITAL LETTER EN
        "\x{12D8}" => "", # ETHIOPIC SYLLABLE ZA
        "\x{13BB}" => "", # CHEROKEE LETTER MI
        "\x{157C}" => "", # CANADIAN SYLLABICS NUNAVUT H
        "\x{2C8E}" => "", # COPTIC CAPITAL LETTER HATE
    },

    {
        "\x{0049}" => "", # I # LATIN CAPITAL LETTER I
        "\x{0399}" => "", # GREEK CAPITAL LETTER IOTA
        "\x{0406}" => "", # CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I
        "\x{2160}" => "", # ROMAN NUMERAL ONE
    },

    {
        "\x{004A}" => "", # J # LATIN CAPITAL LETTER J
        "\x{0408}" => "", # CYRILLIC CAPITAL LETTER JE
        "\x{13AB}" => "", # CHEROKEE LETTER GU
        "\x{148D}" => "", # CANADIAN SYLLABICS CO
    },

    {
        "\x{004B}" => "", # K # LATIN CAPITAL LETTER K
        "\x{039A}" => "", # GREEK CAPITAL LETTER KAPPA
        "\x{13E6}" => "", # CHEROKEE LETTER TSO
        "\x{16D5}" => "", # RUNIC LETTER OPEN-P
        "\x{212A}" => "", # KELVIN SIGN
        "\x{2C94}" => "", # COPTIC CAPITAL LETTER KAPA
    },

    {
        "\x{004C}" => "", # L # LATIN CAPITAL LETTER L
        "\x{13DE}" => "", # CHEROKEE LETTER TLE
        "\x{14AA}" => "", # CANADIAN SYLLABICS MA
        "\x{216C}" => "", # ROMAN NUMERAL FIFTY
    },

    {
        "\x{004D}" => "", # M # LATIN CAPITAL LETTER M
        "\x{039C}" => "", # GREEK CAPITAL LETTER MU
        "\x{03FA}" => "", # GREEK CAPITAL LETTER SAN
        "\x{041C}" => "", # CYRILLIC CAPITAL LETTER EM
        "\x{13B7}" => "", # CHEROKEE LETTER LU
        "\x{216F}" => "", # ROMAN NUMERAL ONE THOUSAND
    },

    {
        "\x{004E}" => "", # N # LATIN CAPITAL LETTER N
        "\x{039D}" => "", # GREEK CAPITAL LETTER NU
        "\x{2C9A}" => "", # COPTIC CAPITAL LETTER NI
    },

    {
        "\x{004F}" => "", # O # LATIN CAPITAL LETTER O
        "\x{039F}" => "", # GREEK CAPITAL LETTER OMICRON
        "\x{041E}" => "", # CYRILLIC CAPITAL LETTER O
        "\x{2C9E}" => "", # COPTIC CAPITAL LETTER O
    },

    {
        "\x{0050}" => "", # P # LATIN CAPITAL LETTER P
        "\x{03A1}" => "", # GREEK CAPITAL LETTER RHO
        "\x{0420}" => "", # CYRILLIC CAPITAL LETTER ER
        "\x{13E2}" => "", # CHEROKEE LETTER TLV
        "\x{2CA2}" => "", # COPTIC CAPITAL LETTER RO
    },

    {
        "\x{0051}" => "", # Q # LATIN CAPITAL LETTER Q
        "\x{051A}" => "", # CYRILLIC CAPITAL LETTER QA
        "\x{2D55}" => "", # TIFINAGH LETTER YARR
    },

    {
        "\x{0052}" => "", # R # LATIN CAPITAL LETTER R
        "\x{13A1}" => "", # CHEROKEE LETTER E
        "\x{13D2}" => "", # CHEROKEE LETTER SV
        "\x{1587}" => "", # CANADIAN SYLLABICS TLHI
    },

    {
        "\x{0053}" => "", # S # LATIN CAPITAL LETTER S
        "\x{0405}" => "", # CYRILLIC CAPITAL LETTER DZE
        "\x{13DA}" => "", # CHEROKEE LETTER DU
    },

    {
        "\x{0054}" => "", # T # LATIN CAPITAL LETTER T
        "\x{03A4}" => "", # GREEK CAPITAL LETTER TAU
        "\x{0422}" => "", # CYRILLIC CAPITAL LETTER TE
        "\x{13A2}" => "", # CHEROKEE LETTER I
    },

    {
        "\x{0056}" => "", # V # LATIN CAPITAL LETTER V
        "\x{13D9}" => "", # CHEROKEE LETTER DO
        "\x{2164}" => "", # ROMAN NUMERAL FIVE
    },

    {
        "\x{0057}" => "", # W # LATIN CAPITAL LETTER W
        "\x{13B3}" => "", # CHEROKEE LETTER LA
        "\x{13D4}" => "", # CHEROKEE LETTER TA
    },

    {
        "\x{0058}" => "", # X # LATIN CAPITAL LETTER X
        "\x{03A7}" => "", # GREEK CAPITAL LETTER CHI
        "\x{0425}" => "", # CYRILLIC CAPITAL LETTER HA
        "\x{2169}" => "", # ROMAN NUMERAL TEN
        "\x{2CAC}" => "", # COPTIC CAPITAL LETTER KHI
    },

    {
        "\x{0059}" => "", # Y # LATIN CAPITAL LETTER Y
        "\x{03A5}" => "", # GREEK CAPITAL LETTER UPSILON
        "\x{2CA8}" => "", # COPTIC CAPITAL LETTER UA
    },

    {
        "\x{005A}" => "", # Z # LATIN CAPITAL LETTER Z
        "\x{0396}" => "", # GREEK CAPITAL LETTER ZETA
        "\x{13C3}" => "", # CHEROKEE LETTER NO
    },

    {
        "\x{005B}" => "", # [ # LEFT SQUARE BRACKET
        "\x{FF3B}" => "", # FULLWIDTH LEFT SQUARE BRACKET
    },

    {
        "\x{005C}" => "", # \ # REVERSE SOLIDUS
        "\x{2216}" => "", # SET MINUS
        "\x{29F5}" => "", # REVERSE SOLIDUS OPERATOR
        "\x{29F9}" => "", # BIG REVERSE SOLIDUS
        "\x{FE68}" => "", # SMALL REVERSE SOLIDUS
        "\x{FF3C}" => "", # FULLWIDTH REVERSE SOLIDUS
    },

    {
        "\x{005D}" => "", # ] # RIGHT SQUARE BRACKET
        "\x{FF3D}" => "", # FULLWIDTH RIGHT SQUARE BRACKET
    },

    {
        "\x{005E}" => "", # ^ # CIRCUMFLEX ACCENT
        "\x{02C4}" => "", # MODIFIER LETTER UP ARROWHEAD
        "\x{02C6}" => "", # MODIFIER LETTER CIRCUMFLEX ACCENT
        "\x{1DBA}" => "", # MODIFIER LETTER SMALL TURNED V
        "\x{2303}" => "", # UP ARROWHEAD
        "\x{FF3E}" => "", # FULLWIDTH CIRCUMFLEX ACCENT
    },

    {
        "\x{005F}" => "", # _ # LOW LINE
        "\x{02CD}" => "", # MODIFIER LETTER LOW MACRON
        "\x{268A}" => "", # MONOGRAM FOR YANG
        "\x{FF3F}" => "", # FULLWIDTH LOW LINE
    },

    {
        "\x{0060}" => "", # ` # GRAVE ACCENT
        "\x{02CB}" => "", # MODIFIER LETTER GRAVE ACCENT
        "\x{1FEF}" => "", # GREEK VARIA
        "\x{2035}" => "", # REVERSED PRIME
        "\x{FF40}" => "", # FULLWIDTH GRAVE ACCENT
    },

    {
        "\x{0061}" => "", # a # LATIN SMALL LETTER A
        "\x{0251}" => "", # LATIN SMALL LETTER ALPHA
        "\x{0430}" => "", # CYRILLIC SMALL LETTER A
    },

    {
        "\x{0063}" => "", # c # LATIN SMALL LETTER C
        "\x{03F2}" => "", # GREEK LUNATE SIGMA SYMBOL
        "\x{0441}" => "", # CYRILLIC SMALL LETTER ES
        "\x{217D}" => "", # SMALL ROMAN NUMERAL ONE HUNDRED
    },

    {
        "\x{0064}" => "", # d # LATIN SMALL LETTER D
        "\x{0501}" => "", # CYRILLIC SMALL LETTER KOMI DE
        "\x{217E}" => "", # SMALL ROMAN NUMERAL FIVE HUNDRED
    },

    {
        "\x{0065}" => "", # e # LATIN SMALL LETTER E
        "\x{0435}" => "", # CYRILLIC SMALL LETTER IE
        "\x{1971}" => "", # TAI LE LETTER TONE-3
    },

    {
        "\x{0067}" => "", # g # LATIN SMALL LETTER G
        "\x{0261}" => "", # LATIN SMALL LETTER SCRIPT G
    },

    {
        "\x{0068}" => "", # h # LATIN SMALL LETTER H
        "\x{04BB}" => "", # CYRILLIC SMALL LETTER SHHA
    },

    {
        "\x{0069}" => "", # i # LATIN SMALL LETTER I
        "\x{0456}" => "", # CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
        "\x{2170}" => "", # SMALL ROMAN NUMERAL ONE
    },

    {
        "\x{006A}" => "", # j # LATIN SMALL LETTER J
        "\x{03F3}" => "", # GREEK LETTER YOT
        "\x{0458}" => "", # CYRILLIC SMALL LETTER JE
    },

    {
        "\x{006C}" => "", # l # LATIN SMALL LETTER L
        "\x{217C}" => "", # SMALL ROMAN NUMERAL FIFTY
    },

    {
        "\x{006D}" => "", # m # LATIN SMALL LETTER M
        "\x{217F}" => "", # SMALL ROMAN NUMERAL ONE THOUSAND
    },

    {
        "\x{006E}" => "", # n # LATIN SMALL LETTER N
        "\x{1952}" => "", # TAI LE LETTER NGA
    },

    {
        "\x{006F}" => "", # o # LATIN SMALL LETTER O
        "\x{03BF}" => "", # GREEK SMALL LETTER OMICRON
        "\x{043E}" => "", # CYRILLIC SMALL LETTER O
        "\x{0D20}" => "", # MALAYALAM LETTER TTHA
        "\x{2C9F}" => "", # COPTIC SMALL LETTER O
    },

    {
        "\x{0070}" => "", # p # LATIN SMALL LETTER P
        "\x{0440}" => "", # CYRILLIC SMALL LETTER ER
        "\x{2CA3}" => "", # COPTIC SMALL LETTER RO
    },

    {
        "\x{0073}" => "", # s # LATIN SMALL LETTER S
        "\x{0455}" => "", # CYRILLIC SMALL LETTER DZE
    },

    {
        "\x{0075}" => "", # u # LATIN SMALL LETTER U
        "\x{1959}" => "", # TAI LE LETTER PA
        "\x{222A}" => "", # UNION
    },

    {
        "\x{0076}" => "", # v # LATIN SMALL LETTER V
        "\x{1D20}" => "", # LATIN LETTER SMALL CAPITAL V
        "\x{2174}" => "", # SMALL ROMAN NUMERAL FIVE
        "\x{2228}" => "", # LOGICAL OR
        "\x{22C1}" => "", # N-ARY LOGICAL OR
    },

    {
        "\x{0077}" => "", # w # LATIN SMALL LETTER W
        "\x{1D21}" => "", # LATIN LETTER SMALL CAPITAL W
    },

    {
        "\x{0078}" => "", # x # LATIN SMALL LETTER X
        "\x{0445}" => "", # CYRILLIC SMALL LETTER HA
        "\x{2179}" => "", # SMALL ROMAN NUMERAL TEN
        "\x{2CAD}" => "", # COPTIC SMALL LETTER KHI
    },

    {
        "\x{0079}" => "", # y # LATIN SMALL LETTER Y
        "\x{0443}" => "", # CYRILLIC SMALL LETTER U
        "\x{1EFF}" => "", # LATIN SMALL LETTER Y WITH LOOP
    },

    {
        "\x{007A}" => "", # z # LATIN SMALL LETTER Z
        "\x{1D22}" => "", # LATIN LETTER SMALL CAPITAL Z
    },

    {
        "\x{007B}" => "", # { # LEFT CURLY BRACKET
        "\x{FE5B}" => "", # SMALL LEFT CURLY BRACKET
        "\x{FF5B}" => "", # FULLWIDTH LEFT CURLY BRACKET
    },

    {
        "\x{007C}" => "", # | # VERTICAL LINE
        "\x{01C0}" => "", # LATIN LETTER DENTAL CLICK
        "\x{16C1}" => "", # RUNIC LETTER ISAZ IS ISS I
        "\x{239C}" => "", # LEFT PARENTHESIS EXTENSION
        "\x{239F}" => "", # RIGHT PARENTHESIS EXTENSION
        "\x{23A2}" => "", # LEFT SQUARE BRACKET EXTENSION
        "\x{23A5}" => "", # RIGHT SQUARE BRACKET EXTENSION
        "\x{23AA}" => "", # CURLY BRACKET EXTENSION
        "\x{23AE}" => "", # INTEGRAL EXTENSION
        "\x{FF5C}" => "", # FULLWIDTH VERTICAL LINE
        "\x{FFE8}" => "", # HALFWIDTH FORMS LIGHT VERTICAL
    },

    {
        "\x{007D}" => "", # } # RIGHT CURLY BRACKET
        "\x{FE5C}" => "", # SMALL RIGHT CURLY BRACKET
        "\x{FF5D}" => "", # FULLWIDTH RIGHT CURLY BRACKET
    },

    {
        "\x{007E}" => "", # ~ # TILDE
        "\x{02DC}" => "", # SMALL TILDE
        "\x{2053}" => "", # SWUNG DASH
        "\x{223C}" => "", # TILDE OPERATOR
        "\x{FF5E}" => "", # FULLWIDTH TILDE
    },

);

1;
# ABSTRACT: List of Unicode homoglyphs

__END__

=pod

=encoding UTF-8

=head1 NAME

Unicode::Homoglyph - List of Unicode homoglyphs

=head1 VERSION

This document describes version 0.01 of Unicode::Homoglyph (from Perl distribution Unicode-Homoglyph), released on 2015-10-25.

=head1 SYNOPSIS

 use Unicode::Homoglyph;

See the C<@Unicode::Homoglyph::Homoglyphs> variable.

=head1 DESCRIPTION

=head1 SEE ALSO

mimic, L<https://github.com/reinderien/mimic/> the project where the list was
originally stolen from.

L<http://www.irongeek.com/homoglyph-attack-generator.php>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Unicode-Homoglyph>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Unicode-Homoglyph>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Unicode-Homoglyph>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
