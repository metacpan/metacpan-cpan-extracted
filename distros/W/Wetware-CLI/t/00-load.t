#!perl -T
#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
	use_ok( 'Wetware::CLI' );
}

#TODO: should I use this or the compile?
##diag( "Testing Wetware::CLI $Wetware::CLI::VERSION, Perl $], $^X" );
