#!perl
use 5.14.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Test::UnixCmdWrap') || print "Bail out!\n";
}

diag("Testing Test::UnixCmdWrap $Test::UnixCmdWrap::VERSION, Perl $], $^X");
