#!/usr/bin/perl

use strict;

use Test::Builder::Tester tests => 4;

use Test::Fatal qw( dies_ok lives_ok );

test_out( "ok 1 - died" );
dies_ok { die "FAIL" } 'died';
test_test( "die dies" );

test_out( "not ok 1 - returned" );
test_fail( +2 );
test_err( "# expected an exception but none was raised" );
dies_ok { return 1 } 'returned';
test_test( "return doesn't die" );

test_out( "ok 1 - returned" );
lives_ok { return 1 } 'returned';
test_test( "return lived" );

test_out( "not ok 1 - died" );
test_fail( +2 );
test_err( "# expected return but an exception was raised" );
lives_ok { die "FAIL" } 'died';
test_test( "die doesn't live" );
