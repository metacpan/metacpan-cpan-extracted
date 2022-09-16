#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use lib '.';

use Test::More 'tests' => 9;
use Test::Fatal;
use Capture::Tiny qw{capture};
use App::Prove;
use App::Prove::Plugin::TestRail;

#I'm the secret squirrel
$ENV{'TESTRAIL_MOCKED'} = 1;

#Test the same sort of data as would come from the Test::Rail::Parser case
my $prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,run=TestingSuite,version=0.014",'t/fake.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser case via plugin functions");

#Check that plan, configs and version also make it through
$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,run=Executing the great plan,version=0.014,plan=GosPlan,configs=testConfig",'t/fake.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser case via plugin functions works with configs/plans");

#Check that spawn options make it through

$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,run=TestingSuite2,version=0.014,testsuite_id=9",'t/skipall.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser case via plugin functions works with configs/plans");

$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,plan=bogoPlan,run=bogoRun,version=0.014,testsuite=HAMBURGER-IZE HUMANITY",'t/skipall.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser spawns both runs and plans");

$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,run=bogoRun,version=0.014,testsuite_id=9,sections=fake.test:CARBON LIQUEFACTION",'t/fake.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser can discriminate by sections correctly");

$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,plan=FinalPlan,run=FinalRun,configs=testConfig,version=0.014,autoclose=1",'t/fake.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser with autoclose works correctly");

$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,plan=FinalPlan,run=FinalRun,configs=testConfig,version=0.014,test_bad_status=blocked,config_group=Operating Systems",'t/fake.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser with test_bad_status & config_group throws no exceptions/warnings");


#Test multi-job upload shizz
#Note that I don't care if it even uploads, just that it *would have* done so correctly.
$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,plan=FinalPlan,run=FinalRun,configs=testConfig,step_results=step_results", '-j2', 't/fake.test', 't/skipall.test');

is (exception { capture { $prove->run() } },undef,"Running TR parser -j2 works");

my $tres = $prove->state_manager->results->{'tests'};
subtest "Both step_result tracking and raw_output is correct (tests share parser internally)" => sub {
    foreach my $test (keys %$tres) {
        my $step_results = $tres->{$test}->{'parser'}->{'tr_opts'}->{'result_custom_options'}->{'step_results'};
        my $toutput = $tres->{$test}->{'parser'}->{'raw_output'};
        note $test;
        if ($test eq 't/skipall.test') {
            unlike($toutput,qr/STORAGE TANKS SEARED/i,"Test steps in full test output");
            isnt(ref $step_results, 'ARRAY', "step_results isnt ARRAY ref");
        } else {
            like($toutput,qr/STORAGE TANKS SEARED/i,"Test steps in full test output");
            unlike($toutput,qr/SKIP/i,"Skip all info in full test output");
            if (is(ref $step_results, 'ARRAY', "step_results is ARRAY ref")) {
                is(scalar(@$step_results),2,"2 steps to upload for normal test");
            }
        }
    }
};
