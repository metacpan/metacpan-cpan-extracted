#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
    use_ok('WebService::Amazon::Route53::Caching') || print "Bail out!
";
}

diag(
    "Testing WebService::Amazon::Route53::Caching $WebService::Amazon::Route53::Caching::VERSION, Perl $], $^X"
);
