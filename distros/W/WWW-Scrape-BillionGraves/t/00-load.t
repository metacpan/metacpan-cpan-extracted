#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	if(-e 't/online.enabled') {
		use_ok('WWW::Scrape::BillionGraves') || print 'Bail out!';
	} else {
		SKIP: {
			diag 'You must be on-line to test WWW::Scrape::BillionGraves';
			skip 'You must be on-line to test WWW::Scrape::BillionGraves', 1;
			print 'Bail out!';
		}
	}
}

require_ok('WWW::Scrape::BillionGraves') || print 'Bail out!';

diag( "Testing WWW::Scrape::BillionGraves $WWW::Scrape::BillionGraves::VERSION, Perl $], $^X" );
