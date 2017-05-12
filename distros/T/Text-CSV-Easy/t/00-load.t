#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Text::CSV::Easy') || print "Bail out!\n";
}

diag("Testing Text::CSV::Easy $Text::CSV::Easy::VERSION, Perl $], $^X");
