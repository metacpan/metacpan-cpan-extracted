#!perl -w

use strict;
use lib '..';
use Test::More::Behaviours 'no_plan';

use constant TRUE 	=> 1;
use constant FALSE 	=> 0;

my $is_setup = FALSE;

BEGIN {
	test 'should not mind if set_up or tear_down exists' => sub {
		is ($is_setup , undef , 'Should not be setup');
	} ;
}

*main::set_up = sub { $is_setup = TRUE } ;
*main::tear_down = sub { $is_setup = FALSE } ;

test 'setup test' => sub {
		ok( $is_setup, 'should have been setup' );
} ;

is( $is_setup, FALSE , 'Should have been torn down');

test 'Should be able to do more than one test' => sub {
		ok( $is_setup, 'should have been setup' );
} ;

is( $is_setup, FALSE , 'Should have been torn down');

#TODO: Verify TAP compatible output format

