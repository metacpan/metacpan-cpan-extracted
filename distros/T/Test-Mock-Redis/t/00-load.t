#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('Test::Mock::Redis') || print "Bail out!";
}

use_ok('Test::Mock::Redis', num_databases => 42);

my $r = Test::Mock::Redis->new(server => 'foobar');

is($r->{_num_dbs}, 42, "num_databases import argument was respected");


diag("Testing Test::Mock::Redis $Test::Mock::Redis::VERSION, Perl $], $^X");
