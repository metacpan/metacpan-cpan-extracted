use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More 'tests' => 53;
use Test::Fatal;
use Test::Deep;
use File::Basename qw{dirname};

use TestRail::Utils;
use TestRail::Utils::Lock;
use Test::LWP::UserAgent::TestRailMock;
use File::Basename qw{basename};

#FindRuns tests

my $opts = {
    'project'    => 'TestProject'
};

my ($apiurl,$login,$pw) = ('http://testrail.local','bogus','bogus');

my $tr = new TestRail::API($apiurl,$login,$pw,undef,1);

#Mock if necesary
$tr->{'debug'} = 0;
$tr->{'browser'} = $Test::LWP::UserAgent::TestRailMock::mockObject;

my $runs = TestRail::Utils::Find::findRuns($opts,$tr);
is(ref $runs, 'ARRAY', "FindRuns returns ARRAYREF");
is(scalar(@$runs),5,"All runs for project found when no other options are passed");
@$runs = map {$_->{'name'}} @$runs;
my @expected = qw{OtherOtherSuite TestingSuite FinalRun lockRun ClosedRun};
cmp_deeply($runs,\@expected,"Tests ordered FIFO by creation date correctly");

$opts->{'lifo'} = 1;
$runs = TestRail::Utils::Find::findRuns($opts,$tr);
@$runs = map {$_->{'name'}} @$runs;
@expected = qw{lockRun ClosedRun TestingSuite FinalRun OtherOtherSuite};
cmp_deeply($runs,\@expected,"Tests ordered LIFO by creation date correctly");

$opts->{'milesort'} = 1;
$runs = TestRail::Utils::Find::findRuns($opts,$tr);
@$runs = map {$_->{'name'}} @$runs;
@expected = qw{OtherOtherSuite TestingSuite FinalRun lockRun ClosedRun};
cmp_deeply($runs,\@expected,"Tests ordered LIFO by milestone date correctly");

delete $opts->{'lifo'};
$runs = TestRail::Utils::Find::findRuns($opts,$tr);
@$runs = map {$_->{'name'}} @$runs;
@expected = qw{TestingSuite FinalRun lockRun ClosedRun OtherOtherSuite};
cmp_deeply($runs,\@expected,"Tests ordered LIFO by milestone date correctly");

delete $opts->{'milesort'};

$opts->{'configs'} = ['eee', 'testConfig'];
$runs = TestRail::Utils::Find::findRuns($opts,$tr);
@$runs = map {$_->{'name'}} @$runs;
is(scalar(@$runs),0,"Filtering runs by configurations works");

$opts->{'configs'} = ['testConfig'];
$runs = TestRail::Utils::Find::findRuns($opts,$tr);
@$runs = map {$_->{'name'}} @$runs;
is(scalar(@$runs),3,"Filtering runs by configurations works");

delete $opts->{'configs'};
$opts->{'statuses'} = ['passed'];
$runs = TestRail::Utils::Find::findRuns($opts,$tr);
is(scalar(@$runs),0,"No passing runs can be found in projects without them");

$opts->{'statuses'} = ['retest'];
$runs = TestRail::Utils::Find::findRuns($opts,$tr);
is(scalar(@$runs),2,"Failed runs can be found in projects with them");

#Test testrail-tests

$opts = {
    'project'    => 'TestProject',
    'plan'       => 'GosPlan',
    'run'        => 'Executing the great plan',
    'match'      => $FindBin::Bin,
    'configs'    => ['testConfig'],
    'no-recurse' => 1,
    'names-only' => 1
};

my ($cases) = TestRail::Utils::Find::getTests($opts,$tr);
my @tests = TestRail::Utils::Find::findTests($opts,@$cases);
@expected = ("$FindBin::Bin/fake.test","$FindBin::Bin/skip.test","$FindBin::Bin/skipall.test");
cmp_deeply(\@tests,\@expected,"findTests: match, no-recurse, plan mode, names-only");

delete $opts->{'names-only'};
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
@tests = map {$_->{'full_title'}} @tests;
cmp_deeply(\@tests,\@expected,"findTests: match, no-recurse, plan mode");

delete $opts->{'match'};
$opts->{'no-match'} = $FindBin::Bin;
$opts->{'names-only'} = 1;
$opts->{'extension'} = '.test';
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
is(scalar(grep {$_ eq 'skipall.test'} @tests),0,"Tests in tree are not returned in no-match mode");
is(scalar(grep {$_ eq 'NOT SO SEARED AFTER ALL'} @tests),0,"Tests not in tree that do exist are not returned in no-match mode");
is(scalar(grep {$_ eq $FindBin::Bin.'/faker.test'} @tests),1,"Orphan Tests in tree ARE returned in no-match mode");
is(scalar(@tests),5,"Correct number of non-existant cases shown (no-match, names-only)");

$opts->{'configs'} = ['testPlatform1'];
isnt(exception { TestRail::Utils::Find::getTests($opts,$tr) } , undef,"Correct number of non-existant cases shown (no-match, names-only)");
$opts->{'configs'} = ['testConfig'];

delete $opts->{'names-only'};
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
my @filtered_tests = grep {defined $_} map {$_->{'full_title'}} @tests;
is(scalar(@filtered_tests),0,"Full titles not returned in no-match mode");
is(scalar(@tests),5,"Correct number of nonexistant cases shown in no-match mode");

delete $opts->{'no-recurse'};
$opts->{'names-only'} = 1;
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
is(scalar(@tests),9,"Correct number of non-existant cases shown (no-match, names-only, recurse)");

#mutual excl
$opts->{'match'} = $FindBin::Bin;
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
isnt(exception {TestRail::Utils::Find::findTests($opts,@$cases)},undef,"match and no-match are mutually exclusive");

delete $opts->{'no-match'};
$opts->{'orphans'} = $FindBin::Bin;
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
isnt(exception {TestRail::Utils::Find::findTests($opts,@$cases)},undef,"match and orphans are mutually exclusive");

delete $opts->{'match'};
$opts->{'no-match'} = $FindBin::Bin;
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
isnt(exception {TestRail::Utils::Find::findTests($opts,@$cases)},undef,"orphans and no-match are mutually exclusive");
delete $opts->{'orphans'};
delete $opts->{'no-match'};
$opts->{'match'} = $FindBin::Bin;

delete $opts->{'plan'};
$opts->{'run'} = 'TestingSuite';
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
is(scalar(@tests),3,"Correct number of non-existant cases shown (match, plain run)");
is(scalar(grep {$_ eq "$FindBin::Bin/skipall.test"} @tests),1,"Tests in tree are returned in match, plain run mode");

#Now that we've made sure configs are ignored...
$opts->{'plan'} = 'GosPlan';
$opts->{'run'} = 'Executing the great plan';
$opts->{'users'} = ['teodesian'];
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
is(scalar(@tests),1,"Correct number of cases shown (match, plan run, assignedto pos)");
is(scalar(grep {$_ eq "$FindBin::Bin/skipall.test"} @tests),1,"Tests in tree are returned filtered by assignee");

$opts->{'users'} = ['billy'];
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
is(scalar(@tests),0,"Correct number of cases shown (match, plan run, assignedto neg)");

delete $opts->{'users'};
$opts->{'statuses'} = ['passed'];
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
is(scalar(@tests),1,"Correct number of cases shown (match, plan run, passed)");

$opts->{'statuses'} = ['failed'];
delete $opts->{'match'};
($cases) = TestRail::Utils::Find::getTests($opts,$tr);
@tests = TestRail::Utils::Find::findTests($opts,@$cases);
is(scalar(@tests),0,"Correct number of cases shown (match, plan run, failed)");

#Test FindTests' finder sub
like(exception { TestRail::Utils::Find::findTests({'match' => '.', 'finder' => sub { return die('got here') } }) }, qr/got here/i, "FindTests callback can fire correctly");

$opts = {
    'project' => 'TestProject',
    'testsuite' => 'HAMBURGER-IZE HUMANITY',
    'directory' => $FindBin::Bin,
    'extension' => '.test'
};

#Test getCases
$cases = TestRail::Utils::Find::getCases($opts,$tr);
is(scalar(@$cases),2,'Case search returns correct number of cases');

#Test findCases
$opts->{'no-missing'} = 1;
my $output = TestRail::Utils::Find::findCases($opts,@$cases);
is($output->{'testsuite_id'},9,'Correct testsuite_id returned by findCases');
is($output->{'missing'},undef,'No missing cases returned');
is($output->{'orphans'},undef,'No orphan cases returned');
is($output->{'update'},undef,'No update cases returned');

delete $opts->{'no-missing'};
$output = TestRail::Utils::Find::findCases($opts,@$cases);
is(scalar(@{$output->{'missing'}}),11,'Correct number of missing cases returned');
is($output->{'orphans'},undef,'No orphan cases returned');
is($output->{'update'},undef,'No update cases returned');

$opts->{'no-missing'} = 1;
$opts->{'orphans'} = 1;
$output = TestRail::Utils::Find::findCases($opts,@$cases);
is($output->{'missing'},undef,'No missing cases returned');
is(scalar(@{$output->{'orphans'}}),1,'1 orphan case returned');
is($output->{'orphans'}->[0]->{'title'},'nothere.test',"Correct orphan case return");
is($output->{'update'},undef,'No update cases returned');

delete $opts->{'orphans'};
$opts->{'update'} = 1;
$output = TestRail::Utils::Find::findCases($opts,@$cases);
is($output->{'missing'},undef,'No missing cases returned');
is($output->{'orphans'},undef,'No orphan cases returned');
is(scalar(@{$output->{'update'}}),1,'1 update case returned');
is($output->{'update'}->[0]->{'title'},'fake.test',"Correct update case return");

delete $opts->{'no-missing'};
$opts->{'orphans'} = 1;
$output = TestRail::Utils::Find::findCases($opts,@$cases);
is(scalar(@{$output->{'missing'}}),11,'Correct number of missing cases returned');
is(scalar(@{$output->{'orphans'}}),1,'1 orphan case returned');
is(scalar(@{$output->{'update'}}),1,'1 update case returned');

delete $opts->{'testsuite_id'};
like(exception {TestRail::Utils::Find::findCases($opts,@$cases)},qr/testsuite_id parameter mandatory/i,"No testsuite_id being passed results in error");
$opts->{'testsuite_id'} = 9;

delete $opts->{'directory'};
like(exception {TestRail::Utils::Find::findCases($opts,@$cases)},qr/Directory parameter mandatory/i,"No directory being passed results in error");
$opts->{'directory'} = 'bogoDir/';
like(exception {TestRail::Utils::Find::findCases($opts,@$cases)},qr/No such directory/i,"Bad directory being passed results in error");

#XXX Deliberately omitting the tests for getResults.  It's adequately covered (for now) by testrail-results unit test

#Test synchronize
