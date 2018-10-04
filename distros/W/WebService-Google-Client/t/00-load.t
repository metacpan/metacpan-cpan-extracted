#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('WebService::Google::Client') || print "Bail out!\n";
}

diag(
"Testing WebService::Google::Client $WebService::Google::Client::VERSION, Perl $], $^X"
);
