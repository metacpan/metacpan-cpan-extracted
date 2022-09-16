use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More 'tests' => 11;
use Test::Fatal;
use File::Basename qw{dirname};

use TestRail::Utils;
use TestRail::Utils::Lock;
use Test::LWP::UserAgent::TestRailMock;
use Sys::Hostname qw{hostname};
use File::Basename qw{basename};
use Capture::Tiny qw{capture};

my $opts = {
    'project'    => 'TestProject',
    'run'        => 'lockRun',
    'case-types' => ['Automated'],
    'lockname'   => 'locked',
    'match'      => "t",
    'no-recurse' => 1,
    'hostname'   => hostname(),
    'mock'       => 1
};

my ($apiurl,$login,$pw) = ('http://hokum.bogus','bogus','bogus');

my $tr = new TestRail::API($apiurl,$login,$pw,undef,1);
$tr->{'debug'} = 0;
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep0();

my $ret;
capture { $ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr) };
is($ret,0,"Verify that no tests are locked in match mode, as they all are in a subdir, and recurse is off");
delete $opts->{'no-recurse'};

$ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr);
is(basename( $ret->{'path'} ), 'lockmealso.test' , "Verify the highest priority test is chosen first");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep1();

$ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr);
is(basename( $ret->{'path'} ), 'lockme.test'     , "Verify the highest priority test of type automated is chosen");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep2();

$ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr);
is(basename( $ret->{'path'} ), 'lockmetoo.test'  , "Verify that the highest priority test that exists in the tree is chosen");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep3();

capture { $ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr) };
is($ret,0,"Verify that no tests are locked, as they either are of the wrong type or do not exist in the match tree");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep4();

#Simulate lock collision
$tr->{tests_cache} = {};
my ($lockStatusID) = $tr->statusNamesToIds('locked');
my ($project,$plan,$run) = TestRail::Utils::getRunInformation($tr,$opts);
capture {
    $ret = TestRail::Utils::Lock::lockTest(
        $tr->getTestByName($run->{'id'},'lockme.test'),$lockStatusID,'race.bannon',$tr
    )
};
is($ret ,0,"False returned when race condition is simulated");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep5();

#Test with a second set of options, verify that no-match and type filtering works
delete $opts->{'match'};
$opts->{'case-types'} = ['Other'];

$ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr);
is($ret->{'path'},'sortalockme.test',"Test which is here but the other type is locked when ommitting match");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep6();

$ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr);
is($ret->{'path'},'dontlockme_alsonothere.test',"Test which is not here but the other type is locked when omitting match");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep7();

capture { $ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr) };
is($ret,0,"No tests are locked, as they are not the right type");

#Make sure we only grab retest/untested
delete $opts->{'case-types'};
$ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr);
is($ret->{'path'},'dontlockme_nothere.test',"Wrong type test which is not here gets locked after we remove all restrictions");
$tr->{'browser'} = Test::LWP::UserAgent::TestRailMock::lockMockStep8();

capture { $ret = TestRail::Utils::Lock::pickAndLockTest($opts,$tr) };
is($ret,0,"No tests are locked, as none are untested or retest");
