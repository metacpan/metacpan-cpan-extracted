use utf8;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test::More 1.302183;
use Test::Exception 0.41;
use Test::LeakTrace;
use Test::Warnings qw/ warning /;

use_ok "Text::Minify::XS", "minify";

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
    warning {
        my $n = chr(160);
        my $r = eval { minify($n) };
    };
    warning {
        my $n = " " . chr(160) . " ";
        my $r = eval { minify($n) };
    };
};

no_leaks_ok {

    minify(" \0 x");
    minify("\0");
    minify(" \0 ")

};

done_testing;
