use strict;
use warnings;
use Text::Phonetic::VideoGame;
use Test::More;
use List::MoreUtils qw( uniq );
use Data::Dumper;

my @tests = (
    [
        q{Pandora Tomorrow},
        q{Dora: Tomorrow},
    ],
    [
        q{Nintendo 3DS},
        q{Nintendo DS},
    ],
    [
        q{Playstation 3 system 40GB},
        q{Playstation 3 system 80GB},
    ]
);

plan tests => scalar @tests;
my $phonetic = Text::Phonetic::VideoGame->new;
for my $test (@tests) {
    my $msg = $test->[0];
    my @encodings = $phonetic->encode(@$test);
    my @unique = uniq @encodings;
    if ( @unique == 1 ) {
        my ( %got, %expected );
        @got{ @$test } = @encodings;
        diag( Dumper(\%got) );
        ok( 0, $msg );
        next;
    }

    # if the hashes don't match, produce more helpful output
    ok( 1, $msg );
}
