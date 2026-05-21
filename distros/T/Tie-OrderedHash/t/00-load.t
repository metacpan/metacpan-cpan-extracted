#!perl
use 5.010;
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Tie::OrderedHash') || BAIL_OUT("can't load Tie::OrderedHash");
}

ok(defined &Tie::OrderedHash::TIEHASH, 'TIEHASH XSUB present');
ok(defined &Tie::OrderedHash::FETCH,   'FETCH XSUB present');
ok(defined &Tie::OrderedHash::STORE,   'STORE XSUB present');

diag("Testing Tie::OrderedHash $Tie::OrderedHash::VERSION, Perl $], $^X");
