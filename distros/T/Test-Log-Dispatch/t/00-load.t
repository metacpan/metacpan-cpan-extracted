#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Test::Log::Dispatch');
}

diag("Testing Test::Log::Dispatch $Test::Log::Dispatch::VERSION, Perl $], $^X");
