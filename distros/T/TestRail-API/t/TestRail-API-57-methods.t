use strict;
use warnings;

use Test::More tests => 2;
use Test::MockModule;

use TestRail::API;

my $mock = Test::MockModule->new('TestRail::API');
$mock->redefine('_doRequest', sub { shift; return shift; } );

my $obj = bless ({},'TestRail::API');

like($obj->getReports(666),qr{get_reports/666$}, "Correct endpoint called for getReports");
like($obj->runReport(22), qr{run_report/22$}, "Correct endpoitn called for runReport");
