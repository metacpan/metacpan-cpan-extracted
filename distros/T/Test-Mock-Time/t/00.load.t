use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Test::Mock::Time' ) or BAIL_OUT('unable to load module') }

diag( "Testing Test::Mock::Time $Test::Mock::Time::VERSION, Perl $], $^X" );
