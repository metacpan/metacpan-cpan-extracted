#!perl -T
use strict;
use warnings qw(all);

use Test::More tests => 2;

BEGIN {
    use_ok(q(Test::Builder));
    use_ok(q(Test::Mojibake));
}

diag(qq(Testing Test::Mojibake v$Test::Mojibake::VERSION, Perl $], $^X));
diag(qq(Using Test::Builder v$Test::Builder::VERSION));
