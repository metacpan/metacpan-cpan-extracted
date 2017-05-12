use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More 'tests' => 1;
use Test::Fatal;

use TestRail::API;
use TestRail::Utils::Results;
use Test::LWP::UserAgent::TestRailMock;

my $opts = {
    'project'       => 'CRUSH ALL HUMANS',
    'run'           => 'SEND T-1000 INFILTRATION UNITS BACK IN TIME',
    'set_status_to' => 'blocked',
    'reason'        => 'Build was bad.'
};

my ($apiurl,$login,$pw) = ('http://testrail.local','bogus','bogus');

my $tr = new TestRail::API($apiurl,$login,$pw,undef,1);
$tr->{'debug'} = 0;
$tr->{'browser'} = $Test::LWP::UserAgent::TestRailMock::mockObject;

my $results = TestRail::Utils::Results::bulkMarkResults($opts,$tr);
is(scalar(@$results),1,"Correctly marks outstanding tests in run");
