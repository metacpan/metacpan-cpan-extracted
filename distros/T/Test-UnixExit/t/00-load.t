#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Test::UnixExit') || print "Bail out!\n";
}

diag("Testing Test::UnixExit $Test::UnixExit::VERSION, Perl $], $^X");
