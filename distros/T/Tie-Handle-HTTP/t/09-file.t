#!/usr/bin/perl
# vim: filetype=perl

use warnings;
use strict;
use Tie::Handle::HTTP;
use Test::More 'no_plan'; # tests => 10;

BEGIN {
    my $flag = $ENV{VERBOSE} || 0;
    eval "sub VERBOSE () { $flag }";
}

ok( open( FOO, '<', 't/test.txt' ) );
ok( !eof( FOO ), "not at end of file yet" ); 

ok( do "t/Common.perl", "Do EXPR: ($!) ($@)" );
