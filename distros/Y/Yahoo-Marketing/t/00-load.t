#!perl -T
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use Test::More tests => 3;

BEGIN {
	use_ok( 'Yahoo::Marketing' );   # should probably fail  (or the new should, really)
	use_ok( 'Yahoo::Marketing::AdGroupService' );
	use_ok( 'Yahoo::Marketing::CampaignService' );
}

diag( "Testing Yahoo::Marketing $Yahoo::Marketing::VERSION, Perl $], $^X" );
