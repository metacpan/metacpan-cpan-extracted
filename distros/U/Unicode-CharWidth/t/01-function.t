#!perl
use strict; use warnings;

use Test::More tests => 7;

use Unicode::CharWidth;

my %ascii = (
    InZerowidth => "\0",
    InSinglewidth => 'x',
    # no double width in ascii
    InNowidth => "\t",
);

for my $name ( sort keys %ascii ) {
    my $ch = $ascii{$name};
    ok $ch =~ /\p{$name}/, "$name ascii";
}

use charnames qw(:full);
my %non_ascii = (
    InNowidth => "\N{BREAK PERMITTED HERE}",
    InZerowidth => "\N{COMBINING GRAVE ACCENT}",
    InSinglewidth => "\N{LATIN CAPITAL LETTER A WITH MACRON}",
    InDoublewidth => "\N{HANGUL CHOSEONG KIYEOK}",
);

for my $name ( sort keys %non_ascii ) {
    my $ch = $non_ascii{$name};
    ok $ch =~ /\p{$name}/, "$name non-ascii";
}

