use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;

use Test::More tests => 91;
use Test::Fatal;
use Test::Deep;
use Scalar::Util ();
use Capture::Tiny qw{capture};

my $apiurl = $ENV{'TESTRAIL_API_URL'};
my $login  = $ENV{'TESTRAIL_USER'};
my $pw     = $ENV{'TESTRAIL_PASSWORD'};

#Mock if nothing is provided
my $is_mock = (!$apiurl && !$login && !$pw);

like(exception {TestRail::API->new('trash','bogus','bogus');}, qr/invalid uri/i, "Non-URIs bounce constructor");

#XXX for some insane reason 'hokum.bogus' seems to be popular with cpantesters
my $bogoError = exception { capture { TestRail::API->new('http://hokum.bogus','lies','moreLies',undef,0); } };
SKIP: {
    skip("Some CPANTesters like to randomly redirect all DNS misses to some other host, apparently", 1) if ($bogoError =~ m/404|302/);
    skip("Occasionally upon first run of tests, LWP mocking will just not work.",1) if ($bogoError =~ m/Unknown error occurred/i);
    like($bogoError, qr/Could not communicate with TestRail Server/i,"Bogus Testrail URI rejected");
}

SKIP: {
    skip("Testing authentication not supported with mock",2) if ($is_mock);

    like(exception {TestRail::API->new($apiurl,'lies','moreLies',undef,0,0); }, qr/Bad user credentials/i,"Bogus Testrail User rejected");
    like(exception {TestRail::API->new($apiurl,$login,'m043L13s                      ',undef,0); }, qr/Bad user credentials/i,"Bogus Testrail Password rejected");
}

($apiurl,$login,$pw) = ('http://testrail.local','teodesian@cpan.org','fake') if $is_mock;

my $tr = new TestRail::API($apiurl,$login,$pw,undef,1);

#Mock if necesary
$tr->{'debug'} = 0;
$tr->{'browser'} = $Test::LWP::UserAgent::TestRailMock::mockObject if $is_mock;

my $res;
capture { $res = $tr->_doRequest('noSuchMethod') };
is($res,-404,'Requesting bad URI returns 404');

#Test USER methods
my $userlist = $tr->getUsers();
ok(@$userlist,"Get Users returns list");
my $myuser = $tr->getUserByEmail($login);
is($myuser->{'email'},$login,"Can get user by email");
is($tr->getUserByID($myuser->{'id'})->{'id'},$myuser->{'id'},"Can get user by ID");
is($tr->getUserByName($myuser->{'name'})->{'name'},$myuser->{'name'},"Can get user by Name");

my @user_names = map {$_->{'name'}} @$userlist;
my @user_ids = map {$_->{'id'}} @$userlist;
my @cuser_ids = $tr->userNamesToIds(@user_names);
cmp_deeply(\@cuser_ids,\@user_ids,"userNamesToIds functions correctly");
isnt(exception {$tr->userNamesToIds(@user_names,'potzrebie'); }, undef, "Passing invalid user name throws exception");

#Test CASE TYPE method
my $caseTypes = $tr->getCaseTypes();
is(ref($caseTypes),'ARRAY',"getCaseTypes returns ARRAY of case types");
my @type_names = map {$_->{'name'}} @$caseTypes;
my @type_ids = map {$_->{'id'}} @$caseTypes;
is($tr->getCaseTypeByName($type_names[0])->{'id'},$type_ids[0],"Can get case type by name correctly");
my @computed_type_ids = $tr->typeNamesToIds(@type_names);
cmp_deeply(\@computed_type_ids,\@type_ids,"typeNamesToIds returns the correct type IDs in the correct order");

#Test PROJECT methods
my $project_name = 'CRUSH ALL HUMANS';

my $new_project = $tr->createProject($project_name,'Robo-Signed Soviet 5 Year Project');
is($new_project->{'name'},$project_name,"Can create new project");

ok($tr->getProjects(),"Get Projects returns list");
is($tr->getProjectByName($project_name)->{'name'},$project_name,"Can get project by name");
my $pjid = $tr->getProjectByID($new_project->{'id'});
is(Scalar::Util::reftype($pjid) eq 'HASH' ? $pjid->{'id'} : $pjid,$new_project->{'id'},"Can get project by id");

#Test TESTSUITE methods
my $suite_name = 'HAMBURGER-IZE HUMANITY';
my $new_suite = $tr->createTestSuite($new_project->{'id'},$suite_name,"Robo-Signed Patriotic People's TestSuite");
is($new_suite->{'name'},$suite_name,"Can create new testsuite");

ok($tr->getTestSuites($new_project->{'id'}),"Can get listing of testsuites for project");
is($tr->getTestSuiteByName($new_project->{'id'},$new_suite->{'name'})->{'name'},$new_suite->{'name'},"Can get suite by name");
is($tr->getTestSuiteByID($new_suite->{'id'})->{'id'},$new_suite->{'id'},"Can get suite by id");

#Test SECTION methods -- roughly analogous to TESTSUITES in TL
my $section_name = 'CARBON LIQUEFACTION';
my $new_section = $tr->createSection($new_project->{'id'},$new_suite->{'id'},$section_name);
is($new_section->{'name'},$section_name,"Can create new section");

ok($tr->getSections($new_project->{'id'},$new_suite->{'id'}),"Can get section listing");
is($tr->getSectionByName($new_project->{'id'},$new_suite->{'id'},$section_name)->{'name'},$section_name,"Can get section by name");
is($tr->getSectionByID($new_section->{'id'})->{'id'},$new_section->{'id'},"Can get new section by id");

my @cids = $tr->sectionNamesToIds($new_project->{'id'},$new_suite->{'id'},$section_name);
is($cids[0],$new_section->{'id'},"sectionNamesToIds returns correct IDs");
isnt(exception {$tr->sectionNamesToIds($new_project->{'id'},$new_suite->{'id'},"No such Section");},undef,"Passing bogus section to sectionNamesToIds throws exception");

#Test CASE methods
my $case_name = 'STROGGIFY POPULATION CENTERS';
my $new_case = $tr->createCase($new_section->{'id'},$case_name);
is($new_case->{'title'},$case_name,"Can create new test case");

my $updated_case = $tr->updateCase($new_case->{'id'}, {'custom_preconds' => 'do some stuff'});
is($updated_case->{'custom_preconds'},'do some stuff',"updateCase works");

my $case_filters = {
    'section_id' => $new_section->{'id'}
};

ok($tr->getCases($new_project->{'id'},$new_suite->{'id'},$case_filters),"Can get case listing");
is($tr->getCaseByName($new_project->{'id'}, $new_suite->{'id'},  $case_name, $case_filters)->{'title'},$case_name,"Can get case by name");
is($tr->getCaseByID($new_case->{'id'})->{'id'},$new_case->{'id'},"Can get case by ID");

#Negative case
$case_filters->{'hokum'} = 'bogus';
isnt(exception {$tr->getCases($new_project->{'id'},$new_suite->{'id'},$case_filters)},undef,"Passing bogus filter croaks");

#Test RUN methods
my $run_name = 'SEND T-1000 INFILTRATION UNITS BACK IN TIME';
my $new_run = $tr->createRun($new_project->{'id'},$new_suite->{'id'},$run_name,"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE");
is($new_run->{'name'},$run_name,"Can create new run");

ok($tr->getRuns($new_project->{'id'}),"Can get list of runs");
is($tr->getRunByName($new_project->{'id'},$run_name)->{'name'},$run_name,"Can get run by name");
is($tr->getRunByID($new_run->{'id'})->{'id'},$new_run->{'id'},"Can get run by ID");

#Test MILESTONE methods
my $milestone_name = "Humanity Exterminated";
my $new_milestone = $tr->createMilestone($new_project->{'id'},$milestone_name,"Kill quota reached if not achieved in 5 years",time()+157788000); #It IS a soviet 5-year plan after all :)
is($new_milestone->{'name'},$milestone_name,"Can create new milestone");

ok($tr->getMilestones($new_project->{'id'}),"Can get list of milestones");
is($tr->getMilestoneByName($new_project->{'id'},$milestone_name)->{'name'},$milestone_name,"Can get milestone by name");
is($tr->getMilestoneByID($new_milestone->{'id'})->{'id'},$new_milestone->{'id'},"Can get milestone by ID");

#Test PLAN methods
my $plan_name = "GosPlan";
my $new_plan = $tr->createPlan($new_project->{'id'},$plan_name,"Soviet 5-year agriculture plan to liquidate Kulaks",$new_milestone->{'id'},[{ suite_id => $new_suite->{'id'}, name => "Executing the great plan"}]);
is($new_plan->{'name'},$plan_name,"Can create new plan");

ok($tr->getPlans($new_project->{'id'}),"Can get list of plans");
ok($tr->getPlans($new_project->{'id'},{ is_completed => 1, milestone_id => 3}),"Can get list of plans, filtered by milestone ID & completion status");
my $namePlan = $tr->getPlanByName($new_project->{'id'},$plan_name);
is($namePlan->{'name'},$plan_name,"Can get plan by name");
is($tr->getPlanByID($new_plan->{'id'})->{'id'},$new_plan->{'id'},"Can get plan by ID");

#Get runs per plan, create runs in plan
my $prun = $new_plan->{'entries'}->[0]->{'runs'}->[0];
is($tr->getRunByID($prun->{'id'})->{'name'},"Executing the great plan","Can get child run of plan by ID");
is($tr->getChildRunByName($new_plan,"Executing the great plan", [], 9)->{'id'},$prun->{'id'},"Can find child run of plan by name filtering by testsuite");
is($tr->getChildRunByName($new_plan,"Executing the great plan", [], 8),0,"Can't find child run of plan by name filtering by (bad) testsuite");

SKIP: {
    skip("Cannot create configurations programattically in the API like in mocks",2) if !$is_mock;
    isnt($tr->getChildRunByName($namePlan,"Executing the great plan",['testConfig']),0,"Getting run by name returns child runs");
    is($tr->getChildRunByName($namePlan,"Executing the great plan"),0,"Getting run by name without sufficient configuration data returns child runs");
}

#Test createRunInPlan
my $updatedPlan = $tr->createRunInPlan($new_plan->{'id'},$new_suite->{'id'},'Dynamic Plan Run');
$prun = $updatedPlan->{'runs'}->[0];
is($tr->getRunByID($prun->{'id'})->{'name'},"Dynamic Plan Run","Can get newly created child run of plan by ID");

#Test TEST/RESULT methods
my $tests = $tr->getTests($new_run->{'id'});
ok($tests,"Can get tests");
is($tr->getTestByName($new_run->{'id'},$tests->[0]->{'title'})->{'title'},$tests->[0]->{'title'},"Can get test by name");
is($tr->getTestByID($tests->[0]->{'id'})->{'id'},$tests->[0]->{'id'},"Can get test by ID");

my $resTypes = $tr->getTestResultFields();
my $statusTypes = $tr->getPossibleTestStatuses();
ok($resTypes,"Can get test result fields");
ok($statusTypes,"Can get possible test statuses");

my @status_names = map {$_->{'name'}} @$statusTypes;
my @status_ids = map {$_->{'id'}} @$statusTypes;
my @status_labels = map {$_->{'label'}} @$statusTypes;
my @computed_ids = $tr->statusNamesToIds(@status_names);
my @computed_labels = $tr->statusNamesToLabels(@status_names);
cmp_deeply(\@computed_ids,\@status_ids,"statusNamesToIds functions correctly");
cmp_deeply(\@computed_labels,\@status_labels,"statusNamesToLabels functions correctly");
isnt(exception {$tr->statusNamesToIds(@status_names,'potzrebie'); }, undef, "Passing invalid status name throws exception in statusNamesToIds");
isnt(exception {$tr->statusNamesToLabels(@status_names,'potzrebie'); }, undef, "Passing invalid status name throws exception in statusNamesToLabels");

#TODO make more thorough tests for options, custom options
my $result = $tr->createTestResults($tests->[0]->{'id'},$statusTypes->[0]->{'id'},"REAPER FORCES INBOUND");
ok(defined($result->{'id'}),"Can add test results");
my $results = $tr->getTestResults($tests->[0]->{'id'});
is($results->[0]->{'id'},$result->{'id'},"Can get results for test");

#Bulk add results
$results = $tr->bulkAddResults($new_run->{'id'}, [{ 'test_id' => $tests->[0]->{'id'},'status_id' => $statusTypes->[0]->{'id'}, "comment" => "REAPER FORCES INBOUND" }]);
ok(defined($results->[0]->{'id'}),"Can bulk add test results");

#Test status and assignedto filtering
my $filteredTests = $tr->getTests($new_run->{'id'},[$status_ids[0]]);
is(scalar(@$filteredTests),1,"Test Filtering works: status id positive");
$filteredTests = $tr->getTests($new_run->{'id'},[$status_ids[1]]);
is(scalar(@$filteredTests),0,"Test Filtering works: status id negative");
$filteredTests = $tr->getTests($new_run->{'id'},[$status_ids[0]],[$userlist->[0]->{'id'}]);
is(scalar(@$filteredTests),0,"Test Filtering works: status id positive, user id negative");
$filteredTests = $tr->getTests($new_run->{'id'},undef,[$userlist->[0]->{'id'}]);
is(scalar(@$filteredTests),0,"Test Filtering works: status id undef, user id negative");
#XXX there is no way to programmatically assign things :( so this will remain somewhat uncovered

#Get run summary
my $runs = $tr->getRuns($new_project->{'id'});
my ($summary) = $tr->getRunSummary(@$runs); #I only care about the first one
isnt($summary->{'run_status'},undef,"Can get run statuses correctly");
is($summary->{'run_status'}->{'Passed'},int(!$is_mock),"Gets # of passed cases correctly");
is($summary->{'run_status'}->{'Untested'},int($is_mock),"Gets # of untested cases correctly");

#Get run results
my $run_results = $tr->getRunResults($new_run->{'id'});
is(scalar(@$run_results),3,"Correct # of results returned by getRunResults");

#Test configuration methods
my $configs = $tr->getConfigurations($new_project->{'id'});
my $is_arr = is(Scalar::Util::reftype($configs),'ARRAY',"Can get configurations for a project");
my (@config_names,@config_ids);
if ($is_arr) {
    @config_names = map {$_->{'name'}} @$configs;
    @config_ids = map {$_->{'id'}} @$configs;
}
my @t_config_ids = $tr->translateConfigNamesToIds($new_project->{'id'},@config_names);
is_deeply(\@config_ids,\@t_config_ids, "Can correctly translate Project names to IDs, and they are correctly sorted");

my $grp = $tr->addConfigurationGroup($new_project->{'id'},"zippy");
is($grp->{'name'},'zippy',"Can add configuration group successfully");

my $fetchedgrp = $tr->getConfigurationGroupByName($new_project->{'id'},'zippy');
is($fetchedgrp->{'id'},$grp->{'id'},"Can get configuration group by name");

my $newgrp = $tr->editConfigurationGroup($grp->{'id'},"doodah");
is($newgrp->{'name'},'doodah',"Can edit configuration group successfully");

my $config = $tr->addConfiguration($grp->{'id'},"potzrebie");
is($config->{'name'},"potzrebie","Can add configuration successfully");

my $newconfig = $tr->editConfiguration($config->{'id'},"poyiut");
is($newconfig->{'name'},"poyiut","Can edit configuration successfully");

ok($tr->deleteConfiguration($config->{'id'}),"Can delete configuration successfully");
ok($tr->deleteConfigurationGroup($grp->{'id'}),"Can delete group successfully");

############################################################
# TestRail arbitrarily limits many calls to 250 result sets.
# Let's make sure our getters actually get everything.
############################################################
SKIP: {
    skip("Skipping slow tests...", 2) if $ENV{'TESTRAIL_SLOW_TESTS'};
    #Check get_plans
    foreach my $i (0..$tr->{'global_limit'}) {
        $tr->createPlan($new_project->{'id'},$plan_name,"PETE & RE-PIOTR");
    }
    is(scalar(@{$tr->getPlans($new_project->{'id'})}),($tr->{'global_limit'} + 2),"Can get list of plans beyond ".$tr->{'global_limit'});


    #Check get_runs
    foreach my $i (0..$tr->{'global_limit'}) {
        $tr->createRun($new_project->{'id'},$new_suite->{'id'},$run_name,"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE");
    }
    is(scalar(@{$tr->getRuns($new_project->{'id'})}),($tr->{'global_limit'} + 2),"Can get list of runs beyond ".$tr->{'global_limit'});
}
##########
# Clean up
##########

#Delete a plan
ok($tr->deletePlan($new_plan->{'id'}),"Can delete plan");

#Delete a milestone
ok($tr->deleteMilestone($new_milestone->{'id'}),"Can delete milestone");

#Delete a run
ok($tr->deleteRun($new_run->{'id'}),"Can delete run");

#Delete a case
ok($tr->deleteCase($new_case->{'id'}),"Can delete Case");

#Delete a section
ok($tr->deleteSection($new_section->{'id'}),"Can delete Section");

#Delete a testsuite
ok($tr->deleteTestSuite($new_suite->{'id'}),"Can delete TestSuite");

#Delete project now that we are done with it
ok($tr->deleteProject($new_project->{'id'}),"Can delete project");

1;
