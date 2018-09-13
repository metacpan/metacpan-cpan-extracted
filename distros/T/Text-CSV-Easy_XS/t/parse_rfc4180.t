#!perl
use strict;
use warnings FATAL => 'all';
use 5.010;

use Test::Deep;
use Test::More;

use Text::CSV::Easy_XS qw(csv_parse);

test_values(
    q{abc,def,ghi}               => [qw( abc def ghi )],
    q{"abc","def","ghi"}         => [qw( abc def ghi )],
    q{"abc","""def""","ghi"}     => [qw( abc "def" ghi )],
    q{0,1,2,3}                   => [qw( 0 1 2 3 )],
    qq{abc,def\n}                => [qw( abc def )],
    qq{abc,"def"\n}              => [qw( abc def )],
    qq{abc,""\n}                 => [ 'abc', '' ],
    qq{abc,\n}                   => [ 'abc', undef ],
    qq{abc,def\r\n}              => [qw( abc def )],
    qq{abc,"def"\r\n}            => [qw( abc def )],
    qq{abc,""\r\n}               => [ 'abc', '' ],
    qq{abc,\r\n}                 => [ 'abc', undef ],
    q{abc , def , ghi}           => [ 'abc ', ' def ', ' ghi' ],
    q{abc,def,"g, ""h"", and i"} => [ 'abc', 'def', 'g, "h", and i' ],
    q{,""} => [ undef, '' ],
);

done_testing();

sub test_values {
    my @tests = @_;    # array instead of hash to maintain order

    for ( my $i = 0; $i < @tests; $i += 2 ) {
        my ( $csv, $expects ) = @tests[ $i, $i + 1 ];

        my $csv_clean = _clean($csv);
        cmp_deeply( [ csv_parse($csv) ], $expects, "$csv_clean parses" );
    }
}

sub _clean {
    my $str = shift;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    return $str;
}
