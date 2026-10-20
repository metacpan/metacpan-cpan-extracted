#! perl

use strict;
use warnings;

use HTTP::Tiny;
use Test::More;

plan skip_all => "set RUN_STOP_PAGE_INTEGRATION=1 with FitNesse and the Perl SLiM server running"
  unless $ENV{RUN_STOP_PAGE_INTEGRATION};

my $base = $ENV{TEST_SLIM_FITNESSE_URL} || "http://127.0.0.1:8080";
my $client = HTTP::Tiny->new(timeout => 120);
my $suite_root = "FitNesse.SuiteAcceptanceTests.SuiteSlimTests.";

sub clear_generated_suite {
  my $response = $client->post_form("$base/MySuite?deletePage", {
    confirmed => "yes",
  });
  ok($response->{success},
    "deleted generated MySuite pages before the next isolated run");
}

sub run_page {
  my($page) = @_;
  my $response = $client->get("$base/$suite_root$page?test&format=xml");
  is($response->{status}, 200, "$page completed through FitNesse");
  like($response->{content}, qr{fitnesse\.slim\.SlimService},
    "$page used the configured SLiM service");

  my($right,$wrong,$ignored,$exceptions) =
    $response->{content} =~ m{
      <result>\s*<counts>\s*
      <right>(\d+)</right>\s*
      <wrong>(\d+)</wrong>\s*
      <ignores>(\d+)</ignores>\s*
      <exceptions>(\d+)</exceptions>
    }xs;
  ok(defined $right, "$page returned primary FitNesse assertion counts")
    or return;
  my @failed;
  while ($response->{content} =~ m{
    <instructionResult>\s*<instruction>((?:(?!</instructionResult>).)*?)</instruction>\s*
    <slimResult>fail\(\)</slimResult>\s*
    <expectation>\s*<status>fail</status>
  }sgx) {
    push @failed, $1;
  }
  return {counts => [$right,$wrong,$ignored,$exceptions], failures => \@failed};
}

sub assert_page_counts {
  my($page,$expected) = @_;
  my $counts = run_page($page);
  is_deeply($counts->{counts}, $expected, "$page has stable isolated results") if $counts;
}

# The setup page writes MySuite.SuiteSetUp. FitNesse keeps that generated wiki
# page after the outer test finishes, so an unisolated later run inherits it.
clear_generated_suite();
my $setup = run_page("StopTestInSuiteSetUp");
ok($setup, "StopTestInSuiteSetUp ran and created its generated suite setup");
my $contaminated_test = run_page("StopTest");
is_deeply($contaminated_test->{counts}, [4,2,0,0],
  "the stale suite setup reproduces StopTest's two teardown assertion failures");
is_deeply($contaminated_test->{failures}, [
  q|{id='scriptTable_42_6', instruction='call', instanceName='scriptTableActor', methodName='contentContains', args=[&lt;span class="pass"&gt;tear down after &lt;a href="MySuite.TestPageA"&gt;TestPageA&lt;/a&gt;&lt;/span&gt;]}|,
  q|{id='scriptTable_42_8', instruction='call', instanceName='scriptTableActor', methodName='contentContains', args=[&lt;span class="pass"&gt;tear down after &lt;a href="MySuite.TestPageB"&gt;TestPageB&lt;/a&gt;&lt;/span&gt;]}|,
], "StopTest failures are its exact TestPageA and TestPageB teardown assertions");
my $contaminated_suite = run_page("StopSuite");
is_deeply($contaminated_suite->{counts}, [5,1,0,0],
  "the stale suite setup reproduces StopSuite's teardown assertion failure");
is_deeply($contaminated_suite->{failures}, [
  q|{id='scriptTable_42_6', instruction='call', instanceName='scriptTableActor', methodName='contentContains', args=[&lt;span class="pass"&gt;tear down after &lt;a href="MySuite.TestPageA"&gt;TestPageA&lt;/a&gt;&lt;/span&gt;]}|,
], "StopSuite failure is its exact TestPageA teardown assertion");

# Isolate each run as the acceptance baseline runner must do. Reverse order and
# repeated execution should not change the page's expected six passing checks.
for my $page (qw(StopSuite StopTest StopTest StopTestInSuiteSetUp)) {
  clear_generated_suite();
  assert_page_counts($page,
    $page eq "StopTestInSuiteSetUp" ? [7,0,0,0] : [6,0,0,0]);
}

clear_generated_suite();
assert_page_counts("StopSuite", [6,0,0,0]);
assert_page_counts("StopTest", [6,0,0,0]);

clear_generated_suite();
done_testing();
