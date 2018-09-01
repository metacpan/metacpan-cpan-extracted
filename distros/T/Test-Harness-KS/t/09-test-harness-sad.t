#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl;

use Test::More tests => 1;

use Cwd;
use IPC::Cmd;
use File::Temp;

use Test::Harness::KS;

use Log::Log4perl ':easy';
Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority( 'WARN' ) );


my $testResultsDir = File::Temp::tempdir( CLEANUP => 1 );
DEBUG "Gathering test results into '$testResultsDir'";



subtest "Scenario: Running tests fails because no such user-defined test exists.", sub {
  plan tests => 2;
  my $nonExistentTestFile = 'non/existant/01-test.t';


  my $cmd = "/usr/bin/env perl bin/test-harness-ks -f $nonExistentTestFile --junit --results-dir $testResultsDir";
  my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
          IPC::Cmd::run( command => $cmd, verbose => 0 );
  TRACE "CMD: $cmd\nERROR MESSAGE: $error_message\nSTDOUT:\n@$stdout_buf\nSTDERR:\n@$stderr_buf\nCWD:".Cwd::getcwd();


  ok(!$success, "Script failed as expected");
  if ($success) {
    FATAL "Program output:\nERROR MESSAGE: $error_message\nSTDOUT:\n@$stdout_buf\nSTDERR:\n@$stderr_buf\nCWD:".Cwd::getcwd();
    BAIL_OUT("Script execution succeeded? It must fail!");
  }

  like(join("\n",@$stderr_buf), qr!$nonExistentTestFile is not readable!, "Failed because the given test file is missing");
};



done_testing;
