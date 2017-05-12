use strict;
use warnings;

use Test::More tests => 66;
use Test::Fatal;
use TestLink::API;

use Prompt::Timeout;
use MIME::Base64;
use Class::Inspector;

sub generate_uid {
  my ($size) = @_;
  $size ||= 7;
  open(my $fh,'<','/dev/urandom');
  my ($uid,$char,$count) = ('','',0);
  while($count < $size) {
    read($fh,$char,1);
    if($char =~ /[a-zA-Z0-9]/) {
      $uid .= $char;
      $count++;
    }
  }
  return $uid;
}

my $tl = TestLink::API->new('http://not.here','not_valid');
#Test input validation

#Call instance methods as class and vice versa
like( exception {$tl->new();}, qr/.*must be called statically.*/, "Calling constructor on instance dies");

my @methods = Class::Inspector->methods('TestLink::API');
my @excludeModules = qw{Scalar::Util Carp Clone Data::Validate::URI};
my @tmp = ();
my @excludedMethods = ();
foreach my $module (@excludeModules) {
    @tmp = Class::Inspector->methods($module);
    push(@excludedMethods,@{$tmp[0]});
}

foreach my $method (@{$methods[0]}) {
    next if $method eq 'new';
    next if grep {$_ eq $method} @excludedMethods;
    like( exception {TestLink::API->$method}, qr/.*called by an instance.*/ , "Calling $method requires an instance");
}

#Conditional tests - no way I'm writing a mock for this garbage
note("WARNING! Do not run the following tests against production testlink databases unless you have direct DB access!");
note("TestLink's API cannot delete any test data, so you will have to do this yourself!");
note("You will now be asked for credentials to point this test at some TestLink Installation.");
note("If you provide no values within 45 seconds, the tests will be skipped."); #TODO use a mock rather than skipping if we don't provide this info
my $apiurl = $ENV{'TESTLINK_SERVER_ADDR'};
note "Please type your TestLink API URL - you have 15 seconds:" unless $apiurl;
$apiurl = prompt("",undef,15) unless $apiurl;
print"\n" unless $apiurl;
my $apikey = $ENV{'TESTLINK_API_KEY'};
note "Please type your TestLink API Key - you have 15 seconds:" unless $apikey;
prompt("",undef,15) unless $apikey;
print"\n" unless $apikey;
note "Please type your TestLink username - you have 15 seconds:";
my $author_name = prompt("",undef,15);
print"\n";

SKIP: {
    skip("User did not provide API endpoint & user to test.",34) if (!$apiurl || !$apikey || !$author_name);
    $tl = TestLink::API->new($apiurl,$apikey);

    my $test_project_name = generate_uid();
    my $test_project_id = $tl->createTestProject($test_project_name,$test_project_name);
    isnt($test_project_id, 0, "Create test project returns project ID (gave $test_project_id)");

    #1a-b. Get test project by name
    ok(scalar(@{$tl->getProjects()}),"Can get project listing");
    cmp_ok($tl->getProjectByName($test_project_name)->{'name'},'eq',$test_project_name,"Can get project by name");

    #2. Create test testsuite
    my $test_suite_name = generate_uid();
    my $test_suite_id = $tl->createTestSuite($test_project_id,$test_suite_name);
    isnt($test_suite_id, 0, "Create test suite in test project $test_project_id ($test_project_name) returns test suite ID (gave $test_suite_id)");

    my $child_test_suite_name = generate_uid();
    my $child_test_suite_id = $tl->createTestSuite($test_project_id,$child_test_suite_name,'child test',$test_suite_id);
    isnt($child_test_suite_id, 0, "Create test suite in test project $test_project_id ($test_project_name) as child of test suite $test_suite_name ($test_suite_id) returns test suite ID (gave $test_suite_id)");

    #2a. Get testsuite by hierarchy
    ok(scalar(@{$tl->getTLDTestSuitesForProject($test_project_id)}), "Can get TLD testsuite listing for project $test_project_name ($test_project_id).");
    ok(scalar(@{$tl->getTestSuitesForTestSuite($test_suite_id)}), "Can get testsuite listing for testsuite $test_suite_name ($test_suite_id).");
    TODO: {
        local $TODO = "Can't get child testsuites sometimes for reasons that escape explanation";
        ok(scalar(@{$tl->getTestSuitesForTestSuite($child_test_suite_id)}), "Can get testsuite listing for child testsuite $child_test_suite_name ($child_test_suite_id).");
    }

    #2b. Get testsuite by ID
    is($tl->getTestSuiteByID($test_suite_id)->{'id'},$test_suite_id,"Can get testsuite by ID");
    cmp_ok($tl->getTestSuitesByName($test_project_id, $test_suite_name)->[0]->{'name'}, 'eq', $test_suite_name, "Can get testsuite by name");

    #3. Create test test
    my $test_name = generate_uid();
    my $test_info = $tl->createTestCase($test_name,$test_suite_id,$test_project_id,$author_name,'robo-signed test',"1. Potzrebie\n2.???\n3.Profit");
    my $test_id = $test_info->{'id'};
    my $test_ext_id = $test_info->{'additionalInfo'}->{'external_id'};
    isnt($test_id, 0, "Create test in test suite $test_suite_id ($test_suite_name) returns test ID (gave $test_id)");

    #3a. Get test by ids, name
    cmp_ok($tl->getTestCaseById($test_id)->{'testcase_id'}, '==', $test_id, "Can get test  $test_name ($test_id) by internal ID.");
    cmp_ok($tl->getTestCaseByExternalId("$test_project_name-$test_ext_id")->{'tc_external_id'}, '==', $test_ext_id, "Can get test  $test_name ($test_project_name-$test_ext_id) by external ID.");
    ok(!$tl->getTestCaseById(-1), "Looking for Nonexistant test ID returns false result.");
    ok(!$tl->getTestCaseByExternalId("hokum-666"),"Looking for Nonexistant test Name returns false result.");

    #3b. Get test by name
    is(int $tl->getTestCaseByName($test_name,$test_suite_name,$test_project_name)->{'id'}, int $test_id,"Can get Test By Name");

    #3c. Get tests for test suite
    ok(scalar(@{$tl->getTestCasesForTestSuite($test_suite_id,1,1)}),"List of testcases for test suite $test_suite_name ($test_suite_id) can be retrieved.");

    #4. Create test test plan
    my $test_plan_name = generate_uid();
    my $test_plan_id =  $tl->createTestPlan($test_plan_name, $test_project_name, 'robo-signed soviet 5 year plan');
    isnt($test_plan_id, 0, "Create Test Plan in test project $test_project_id ($test_project_name) returns test plan ID (gave $test_plan_id)");

    #4a. Get test plan by name
    cmp_ok($tl->getTestPlanByName($test_plan_name,$test_project_name)->{'id'},'==',$test_plan_id,"Verify that we can get the created plan $test_plan_name ($test_plan_id).");

    #5. Assign created test to plan
    ok($tl->addTestCaseToTestPlan($test_plan_id, "$test_project_name-$test_ext_id", $test_project_id, 1), "Added test $test_id to test plan $test_plan_id ($test_plan_name).");

    #5a. Get tests assigned to plan
    ok(scalar(keys(%{$tl->getTestCasesForTestPlan($test_plan_id)})),"List of testcases and testsuites for test plan $test_plan_name ($test_plan_id) can be retrieved.");

    #5b. Get testsuites for project
    ok(scalar(@{$tl->getTestPlansForProject($test_project_id)}),"Can get listing of test plans for project $test_project_name ($test_project_id)");

    #6. Create test build based on created plan
    my $test_build_name = generate_uid();
    my $test_build_id = $tl->createBuild($test_plan_id,$test_build_name);
    isnt($test_build_id, 0, "Create Test Build (run) using test plan $test_plan_id ($test_plan_name) returns test build ID (gave $test_build_id)");

    #6a.  Get buids for plan
    ok(scalar(@{$tl->getBuildsForTestPlan($test_plan_id)}),"Verify we can get a listing of the builds for $test_plan_name ($test_plan_id)");
    cmp_ok($tl->getBuildByName($test_build_name,$test_project_id)->{'id'}, '==', $test_build_id, "Verify we can get build $test_build_name ($test_build_id) by name");

    #6b. Get most recent build for plan
    cmp_ok($tl->getLatestBuildForTestPlan($test_plan_id)->{'id'},'==',$test_build_id,"Verify that we can get the latest build $test_build_name ($test_build_id) for test plan $test_plan_name ($test_plan_id)");

    #7. Set results of created test in created plan
    my $res = $tl->reportTCResult($test_id,$test_plan_id,$test_build_id, 'p');
    ok($res->{'status'}, "Can set results of created test $test_id ($test_name) in test build $test_build_id ($test_build_name).");
    my $execution_id = $res->{'id'};

    #7a. Set execution attachment
    ok($tl->uploadExecutionAttachment($execution_id,'test.txt','text/plain',encode_base64('MOO MOO MOOOOOO'),'bovine emissions','whee'),"Can upload attachment to execution");

    TODO: {
        local $TODO = "The underlying XMLRPC methods for these appear not to work as documented, so this fails";
        #7b. Set/Get test attachments
        ok($tl->uploadTestCaseAttachment($test_id,"MOO.TXT",'text/plain',encode_base64('MOO MOO MOOOOOO'),'bovine emissions','whee'),"Can upload attachment to test case");
        ok($tl->getTestCaseAttachments("$test_project_name-$test_ext_id"),"Can get attachments for test case");
    }

    #7b. Get result summary for build
    cmp_ok($tl->getTotalsForTestPlan($test_plan_id)->{'with_tester'}->[0]->{'p'}->{'exec_qty'},'==',1,"Can get execution total for test plan (for what that's worth, you really want it for build");

    #9-14?. Clean up auto-generated poo?  NOPE, no delete methods, YOLO

    #8. Test dumper
    my $projdump = $tl->dump($test_project_name);
    ok($projdump->{'testsuites'}->[0]->{'name'} eq $test_suite_name,"Dump gets TS correctly");
    ok($projdump->{'testsuites'}->[0]->{'tests'}->[0]->{'name'} eq $test_name,"Dump gets tests correctly");
    ok($projdump->{'testsuites'}->[0]->{'testsuites'}->[0]->{'name'} eq $child_test_suite_name,"Dump gets child TS correctly");

}

1;
