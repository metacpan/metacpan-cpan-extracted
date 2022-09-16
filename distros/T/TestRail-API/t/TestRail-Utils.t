=head1 POD TEST

Bogus bogus

=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More 'tests' => 27;
use Test::Fatal;

use TestRail::API;
use TestRail::Utils;
use Test::LWP::UserAgent::TestRailMock;
use Capture::Tiny qw{capture_merged};

use File::Basename qw{dirname};

my ($apiurl,$user,$password);

#check help output
my ($out,($code)) = capture_merged { TestRail::Utils::help() };
is($code,0,"Help works OK");
like($out,qr/bogus bogus/i,"Displays POD OK");

#check the binary output mode
is(exception {capture_merged { ($apiurl,$password,$user) = TestRail::Utils::parseConfig(dirname(__FILE__),1) }}, undef, "No exceptions thrown by parseConfig in array mode");
is($apiurl,'http://hokum.bogus',"APIURL parse OK");
is($user,'zippy',"USER parse OK");
is($password, 'happy', 'PASSWORD parse OK');

is(exception {capture_merged { $out = TestRail::Utils::parseConfig(dirname(__FILE__))}}, undef, "No exceptions thrown by parseConfig default mode");
is($out->{apiurl},'http://hokum.bogus',"APIURL parse OK");
is($out->{user},'zippy',"USER parse OK");
is($out->{password}, 'happy', 'PASSWORD parse OK');

#Handle both the case where we do in sequence or in paralell and mash together logs

my @files;
my $fcontents = '';
open(my $fh,'<','t/test_multiple_files.tap') or die("couldn't open our own test files!!!");
while (<$fh>) {
    if (TestRail::Utils::getFilenameFromTapLine($_)) {
        push(@files,$fcontents) if $fcontents;
        $fcontents = '';
    }
    $fcontents .= $_;
}
close($fh);
push(@files,$fcontents);
is(scalar(@files),2,"Detects # of filenames correctly in TAP");

$fcontents = '';
@files = ();
open($fh,'<','t/seq_multiple_files.tap') or die("couldn't open our own test files!!!");
while (<$fh>) {
    if (TestRail::Utils::getFilenameFromTapLine($_)) {
        push(@files,$fcontents) if $fcontents;
        $fcontents = '';
    }
    $fcontents .= $_;
}
close($fh);
push(@files,$fcontents);
is(scalar(@files),7,"Detects # of filenames correctly in TAP");

#Test the actual TAP parsing
@files = TestRail::Utils::TAP2TestFiles('t/test_multiple_files.tap');
is(scalar(@files),2,"TAP correctly parsed into right number of bins");

@files = TestRail::Utils::TAP2TestFiles('t/seq_multiple_files.tap');
is(scalar(@files),7,"TAP correctly parsed into right number of bins");

#Test getRunInformation
my $login_opts = {
    'apiurl'   => 'http://testrail.local',
    'user'     => 'teodesian@cpan.org',
    'password' => 'fake',
    'browser'  => $Test::LWP::UserAgent::TestRailMock::mockObject
};
my $tr = TestRail::Utils::getHandle($login_opts);

#Plan mode, no milestone
my $opts = {
    'run'     => 'TestingSuite',
    'plan'    => 'mah dubz plan',
    'configs' => ['testConfig'],
    'project' => 'TestProject'
};
my ($project, $plan, $run, $milestone) = TestRail::Utils::getRunInformation($tr,$opts);
is($project->{'id'}, 10, "getRunInformation gets project correctly");
is($plan->{'id'},    24, "getRunInformation gets plan correctly");
is($run->{'id'},     1, "getRunInformation gets run correctly");
is($milestone,   undef, "getRunInformation returns undef when no milestone set for plan");

#Plan mode, no such run
$opts->{'run'} = 'hoo hoo I do not exist';
like(exception { TestRail::Utils::getRunInformation($tr,$opts) }, qr/no such run/i, "Attempt to find nonexistant run in plan is fatal");

#Plan mode, no such plan
$opts->{'plan'} = 'hoo hoo I do not exist';
like(exception { TestRail::Utils::getRunInformation($tr,$opts) }, qr/no such plan/i, "Attempt to find nonexistant plan is fatal");

#No such project
$opts->{'project'} = 'hoo hoo I do not exist';
like(exception { TestRail::Utils::getRunInformation($tr,$opts) }, qr/no such project/i, "Attempt to find nonexistant project is fatal");

#Run mode, no milestone
$opts->{'run'} = 'TestingSuite';
$opts->{'configs'} = undef;
$opts->{'plan'} = undef;
$opts->{'project'} = 'TestProject';

($project, $plan, $run, $milestone) = TestRail::Utils::getRunInformation($tr,$opts);
is($project->{'id'}, 10, "getRunInformation gets project correctly [run mode]");
is($plan->{'id'}, undef, "getRunInformation gets plan correctly [run mode]");
is($run->{'id'},      1, "getRunInformation gets run correctly [run mode]");
is($milestone,    undef, "getRunInformation returns undef when no milestone set for run");

#Run mode, milestone
$opts->{'run'} = 'OtherOtherSuite';
($project, $plan, $run, $milestone) = TestRail::Utils::getRunInformation($tr,$opts);
is($milestone->{'id'},8,"Milestone acquired correctly in run mode");

#plan mode, milestone
$opts->{'project'} = "TestProject";
$opts->{'plan'} = 'GosPlan';
$opts->{'run'} = "Executing the great plan";
$opts->{'configs'} = ["testConfig"];

($project, $plan, $run, $milestone) = TestRail::Utils::getRunInformation($tr,$opts);
is($milestone->{'id'},8,"Milestone acquired correctly in plan mode");

#Regrettably, I have yet to find a way to print to stdin without eval, so userInput will remain untested.
