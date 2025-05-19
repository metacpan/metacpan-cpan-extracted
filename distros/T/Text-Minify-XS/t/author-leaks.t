use utf8;

use v5.14;
use warnings;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test2::V0;
use Test2::Tools::Warnings qw( warning );
use Test::LeakTrace;

use Text::Minify::XS qw( minify );

no_leaks_ok {
    minify("");
};

no_leaks_ok {
    minify("                 \n    ");
};

no_leaks_ok {
    minify("\n\n  simple\r\n test\n\r  ")
};

no_leaks_ok {
    minify("\r\n\r\n\t0\r\n\t\t1\r\n");
};

no_leaks_ok {
    minify(" £ simple");
};

no_leaks_ok {
    my $w1 = warning {
        my $n = chr(160);
        my $r = eval { minify($n) };
    };
    like $w1, qr/^Malformed UTF-8 character/;
    my $w2 = warning {
        my $n = " " . chr(160) . " ";
        my $r = eval { minify($n) };
    };
    like $w2, qr/^Malformed UTF-8 character/;
};

no_leaks_ok {

    minify(" \0 x");
    minify("\0");
    minify(" \0 ")

};

done_testing;
