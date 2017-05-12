use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;

use Test::More tests => 2;
use Test::Fatal;
use Test::Deep;
use Scalar::Util ();
use Capture::Tiny qw{capture};

my $apiurl = $ENV{'TESTRAIL_API_URL'};
my $login  = $ENV{'TESTRAIL_USER'};
my $pw     = $ENV{'TESTRAIL_PASSWORD'};

#Mock if nothing is provided
my $is_mock = (!$apiurl && !$login && !$pw);
($apiurl,$login,$pw) = ('http://testrail.local','teodesian@cpan.org','fake') if $is_mock;

my $tr = new TestRail::API($apiurl,$login,$pw,undef,1);

#Mock if necesary
$tr->{'debug'} = 0;
$tr->{'browser'} = $Test::LWP::UserAgent::TestRailMock::mockObject if $is_mock;

#This is a mock-only test.
my $project = $tr->getProjectByName('zippy');
my $suite   = $tr->getTestSuiteByName($project->{'id'},'Master');
my $section = $tr->getSectionByName($project->{'id'},$suite->{'id'},'Recursing section');

my $children = $tr->getChildSections($project->{'id'},$section);

my @expected = qw{child grandchild great-grandchild};
my @actual   = map {$_->{'name'} } @$children;
cmp_bag(\@actual,\@expected,"Got child suites recursively");
cmp_bag($tr->getChildSections($project->{'id'},{ 'suite_id' => 999999999999999, 'id' => 9999999999999999 }),[],"Nothing returned when bogus section passed");

1;
