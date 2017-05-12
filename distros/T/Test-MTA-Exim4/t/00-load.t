#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Test::MTA::Exim4');
}

diag("Testing Test::MTA::Exim4 $Test::MTA::Exim4::VERSION, Perl $], $^X");
