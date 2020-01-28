#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
	use_ok ('WebService::AbuseIPDB') or print "Bail out!\n";
	use_ok ('WebService::AbuseIPDB::Category');
	use_ok ('WebService::AbuseIPDB::Response');
	use_ok ('WebService::AbuseIPDB::CheckResponse');
	use_ok ('WebService::AbuseIPDB::ReportResponse');
}

diag (
	"Testing WebService::AbuseIPDB $WebService::AbuseIPDB::VERSION, " .
	"Perl $], $^X"
);
