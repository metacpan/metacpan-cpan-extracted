#!perl

use strict;
use warnings;
use Test::More 0.98;

use Text::Wrap::NoStrip qw(wrap);

subtest "wrap" => sub {
    local $Text::Wrap::NoStrip::columns = 12;
    is_deeply(
        wrap("", "x", "longword1longword2longword3 word1  word2  word3"),
        "longword1lon\nxgword2longw\nxord3 word1\nx  word2  \nxword3",
    );
};

DONE_TESTING:
done_testing();
