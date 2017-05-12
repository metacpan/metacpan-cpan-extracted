#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::ClinicalTrialsdotGov' );
}

diag( "Testing WebService::ClinicalTrialsdotGov $WebService::ClinicalTrialsdotGov::VERSION, Perl $], $^X" );
