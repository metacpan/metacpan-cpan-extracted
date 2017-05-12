#!/usr/bin/env perl
use strict;
use warnings;

use Test::Deep;
use Test::More;

use Text::CSV::Easy_PP;
my $ok = eval { require Text::CSV::Easy_XS };

SKIP: {
    skip "Install Text::CSV::Easy_XS to test", 1 unless $ok;

    my $str = q{1,0,"one",,"","quote ""goes"" here"};
    cmp_deeply( [ Text::CSV::Easy_PP::csv_parse($str) ], [ Text::CSV::Easy_XS::csv_parse($str) ], 'parse is equivalent' );

    my @fields = ( 1, 'one', undef, '', 'quote "goes" here' );
    is( Text::CSV::Easy_PP::csv_build(@fields), Text::CSV::Easy_XS::csv_build(@fields), 'build is equivalent' );
}

done_testing();

