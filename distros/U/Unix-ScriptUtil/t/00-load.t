#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Unix::ScriptUtil') || print "Bail out!\n";
}

diag("Testing Unix::ScriptUtil $Unix::ScriptUtil::VERSION, Perl $], $^X");
