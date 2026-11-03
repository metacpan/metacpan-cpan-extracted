use strict;
use warnings;
use utf8;
use Test::More;
use Unicode::UCD ();

use Text::VisualWidth::PP 'vwidth';

# Characters added after Unicode 12.0, the version of the table in
# Unicode::EastAsianWidth, have their width from the Unicode version
# of the perl in use.

plan skip_all => 'the table is used before perl 5.30' if $^V lt v5.30;

my $unicode = Unicode::UCD::UnicodeVersion();
my($major, $minor) = split /\./, $unicode;

for my $case (
    [ "\N{U+32FF}",  '12.1', 'SQUARE ERA NAME REIWA' ],
    [ "\N{U+1F6D7}", '13.0', 'ELEVATOR' ],
    [ "\N{U+1FAAA}", '14.0', 'IDENTIFICATION CARD' ],
) {
    my($char, $since, $name) = @$case;
    my($need_major, $need_minor) = split /\./, $since;
    SKIP: {
	skip "$name needs Unicode $since, perl has $unicode", 2
	    if $major < $need_major
	    or $major == $need_major && $minor < $need_minor;
	is(vwidth($char), 2, "$name (Unicode $since)");
	is(vwidth("a${char}b"), 4, "$name between ASCII");
    }
}

done_testing;
