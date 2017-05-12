use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

#Test things we can only mock, because the API doesn't support them.

use Test::More 'tests' => 14;
use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;
use Scalar::Util qw{reftype};
use Capture::Tiny qw{capture};

my $browser = $Test::LWP::UserAgent::TestRailMock::mockObject;
my $tr = TestRail::API->new('http://hokum.bogus','fake','fake',undef,1);
$tr->{'browser'} = $browser;
$tr->{'debug'} = 0;

#Have to mock anything requiring configs
my $project = $tr->getProjectByName('TestProject');
my $plan    = $tr->getPlanByName($project->{'id'},'HooHaaPlan');
my $runs = $tr->getChildRuns($plan);
is(reftype($runs),'ARRAY',"getChildRuns returns array");
is(scalar(@$runs),4,"getChildRuns with multi-configs in the same group returns correct # of runs");

my $summary = $tr->getPlanSummary($plan->{'id'});
is($summary->{'plan'},1094,"Plan ID makes it through in summary method");
is($summary->{'totals'}->{'Untested'},4,"Gets total number of tests correctly");
is($summary->{'percentages'}->{'Untested'},'100.00%',"Gets total percentages correctly");

#Also have to mock anything requiring test result fields (all are custom)
my $projResType = $tr->getTestResultFieldByName('step_results');
is($projResType->{'id'},6,"Can get result field by name");
$projResType = $tr->getTestResultFieldByName('step_results',$project->{'id'});
is($projResType->{'id'},6,"Can get result field by name, AND filter by project ID");
$projResType = $tr->getTestResultFieldByName('moo_results');
is($projResType,0,"Bad name returns no result field");
$projResType = $tr->getTestResultFieldByName('step_results',66669);
is($projResType,-3,"Bad project returns no result field");

# I can't delete closed plans, so...test closePlan et cetera
is(reftype($tr->closeRun(666)),'HASH',"Can close run that exists");
my $res;
capture { $res = $tr->closeRun(90210) };
is($res,-404,"Can't close run that doesn't exist");
is(reftype($tr->closePlan(23)),'HASH',"Can close plan that exists");
capture { $res = $tr->closePlan(75020) };
is($res,-404,"Can't close plan that doesn't exist");

# Test case type method
my $ct = $tr->getCaseTypeByName("Automated");
is($ct->{'id'},1,"Can get case type by name");
