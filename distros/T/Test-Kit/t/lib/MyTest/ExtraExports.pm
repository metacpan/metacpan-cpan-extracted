package MyTest::ExtraExports;

use strict;
use warnings;

use Test::Kit;

use Test::More;
our @EXPORT;

include 'Test::More';

sub ten_passes {
    for my $i (1 .. 10) {
        ok $i, "ok($i)";
    }
    return;
}

@EXPORT = (@EXPORT, 'ten_passes');

1;
