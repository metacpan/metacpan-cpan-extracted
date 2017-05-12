#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most;

BEGIN {
	use_ok( 'URI::redis' );
	use_ok( 'URI::redis_Punix' );
}

diag( "Testing URI::redis $URI::redis::VERSION, Perl $], $^X" );

done_testing;
