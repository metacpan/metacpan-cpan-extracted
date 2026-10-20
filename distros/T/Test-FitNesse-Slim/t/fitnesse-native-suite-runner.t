use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Compress::Zip qw($ZipError);
use Test::More;
use lib 't/lib';
use Test::FitNesse::Slim::FitNesseAcceptance qw(probe_slim);
use Test::FitNesse::Slim::FitNesseSuiteAcceptance qw(
  compare_suite_results
  configure_pipe_wiki
  extract_wiki_from_jar
  parse_suite_result
  pipe_query
  verify_perl_trace
  verify_suite_execution_logs
);

my $suite = 'FitNesse.SuiteAcceptanceTests.SuiteSlimTests';
my @labels = (
  'slim:fitnesse.slim.SlimService',
  'SLIM:fitnesse.slim.SlimService',
  'SLIM:remote_debug:fitnesse.slim.SlimService',
);
sub response_xml {
  my(%args) = @_;
  my $rows = $args{rows} // <<'XML';
  <result><counts><right>2</right><wrong>0</wrong><ignores>1</ignores><exceptions>0</exceptions></counts><relativePageName>One</relativePageName><pageHistoryLink>FitNesse.SuiteAcceptanceTests.SuiteSlimTests.One?pageHistory</pageHistoryLink></result>
  <result><counts><right>0</right><wrong>1</wrong><ignores>0</ignores><exceptions>2</exceptions></counts><relativePageName>Two</relativePageName><pageHistoryLink>FitNesse.SuiteAcceptanceTests.SuiteSlimTests.Nested.Two?pageHistory</pageHistoryLink></result>
XML
  my $logs = $args{logs} // <<'XML';
  <executionLog><testSystem>slim:fitnesse.slim.SlimService</testSystem><command>Connection to running SlimService: 127.0.0.1:19099</command><exitCode>0</exitCode></executionLog>
XML
  return qq{<?xml version="1.0"?>\n<testResults><FitNesseVersion>v20251025</FitNesseVersion><rootPath>$suite</rootPath>$rows$logs<finalCounts><right>1</right><wrong>1</wrong><ignores>0</ignores><exceptions>0</exceptions></finalCounts></testResults>};
}

my $xml = response_xml();
my $parsed = parse_suite_result($xml,200,$suite);
is($parsed->{status},'completed','native suite XML is parsed');
is_deeply([sort keys %{$parsed->{results}}],
  [sort "$suite.One", "$suite.Nested.Two"],
  'suite result history links provide full stable page paths');
is_deeply($parsed->{results}{"$suite.One"}{counts},
  { right => 2, wrong => 0, ignored => 1, exceptions => 0 },
  'per-page right, wrong, ignored, and exception counts are parsed');
is_deeply($parsed->{executionOrder},["$suite.One","$suite.Nested.Two"],
  'suite response order is retained as diagnostic evidence');
is($parsed->{version},'v20251025','FitNesse version is exposed for pinned-version validation');

my @expected = (
  { page => "$suite.One", counts => { right => 2, wrong => 0, ignored => 1, exceptions => 0 } },
  { page => "$suite.Nested.Two", counts => { right => 0, wrong => 1, ignored => 0, exceptions => 2 } },
);
my $match = compare_suite_results(\@expected,$parsed->{results},
  { right => 1, wrong => 1, ignores => 0, exceptions => 0 },$parsed->{finalCounts});
ok(!$match->{failed},'all per-page counts match exactly');
my $final_mismatch = compare_suite_results(\@expected,$parsed->{results},
  { right => 1, wrong => 1, ignores => 0, exceptions => 0 },
  { %{$parsed->{finalCounts}}, right => 2 });
ok($final_mismatch->{failed},'suite final-count drift also fails as a consistency check');
is_deeply($final_mismatch->{finalCountChanges},[
  { count => 'right', expected => 1, actual => 2 },
], 'suite final-count deviation is identified');

my $changed = { %{$parsed->{results}} };
$changed->{"$suite.One"} = { counts => { %{$changed->{"$suite.One"}{counts}}, right => 3 } };
my $mismatch = compare_suite_results(\@expected,$changed);
ok($mismatch->{failed},'increased assertion counts still fail the exact baseline comparison');
is_deeply($mismatch->{countChanges},[
  { page => "$suite.One", count => 'right', expected => 2, actual => 3 },
], 'count drift identifies page, count, expected value, and actual value');

my $missing = compare_suite_results(\@expected,{ "$suite.One" => $parsed->{results}{"$suite.One"} });
is_deeply($missing->{missingPages},["$suite.Nested.Two"],'omitted suite page is reported');
my $extra = compare_suite_results(\@expected,{ %{$parsed->{results}}, "$suite.Unexpected" => { counts => {} } });
is_deeply($extra->{unexpectedPages},["$suite.Unexpected"],'unexpected suite page is reported');

my $duplicate_row = '<result><counts><right>0</right><wrong>0</wrong><ignores>0</ignores><exceptions>0</exceptions></counts><relativePageName>One</relativePageName><pageHistoryLink>' . $suite . '.One?pageHistory</pageHistoryLink></result>';
my $duplicate_xml = response_xml(rows => $duplicate_row x 2);
like(join(';',@{parse_suite_result($duplicate_xml,200,$suite)->{errors}}),qr/duplicate page result/,
  'duplicate page results are rejected');
is(parse_suite_result('<html/>',200,$suite)->{status},'execution_error','malformed results are rejected');
is(parse_suite_result($xml,500,$suite)->{status},'execution_error','HTTP failure is rejected');
my $bad_count_xml = response_xml(rows => '<result><counts><right>2</right></counts><relativePageName>One</relativePageName><pageHistoryLink>' . $suite . '.One?pageHistory</pageHistoryLink></result>');
like(join(';',@{parse_suite_result($bad_count_xml,200,$suite)->{errors}}),qr/invalid assertion counts/,
  'missing count fields are rejected');
my $no_results_xml = response_xml(rows => '');
like(join(';',@{parse_suite_result($no_results_xml,200,$suite)->{errors}}),qr/no page results/,
  'empty suite result inventory is rejected');

my $logs = $parsed->{executionLogs};
my $attributed = verify_suite_execution_logs($logs,'127.0.0.1',19099,\@labels);
ok(!$attributed->{failed},'audited test-system label plus exact Perl socket command confirms backend');
my $pipe_attributed = verify_suite_execution_logs([
  { testSystem => 'SLIM:/repo/bin/perl-slim', command => '/repo/bin/perl-slim 1',
    exitCode => '0', exceptions => [] },
], '127.0.0.1',1,\@labels,'pipe','/repo/bin/perl-slim');
ok(!$pipe_attributed->{failed},'pipe execution log confirms the Perl child command and successful exit');
my $flagged_pipe = verify_suite_execution_logs([
  { testSystem => 'SLIM:/repo/bin/perl-slim', command => '/repo/bin/perl-slim -v -s 1 1',
    exitCode => '0', exceptions => [] },
], '127.0.0.1',1,\@labels,'pipe','/repo/bin/perl-slim');
ok(!$flagged_pipe->{failed},'supported FitNesse SLIM_FLAGS retain positive child attribution');
my $remote_debug_pipe = verify_suite_execution_logs([
  { testSystem => 'SLIM:remote_debug:/repo/bin/perl-slim', command => '/repo/bin/perl-slim 1',
    exitCode => '0', exceptions => [] },
], '127.0.0.1',1,\@labels,'pipe','/repo/bin/perl-slim');
ok(!$remote_debug_pipe->{failed},'audited remote-debug label is accepted only with the exact Perl child command');
my $java_pipe = verify_suite_execution_logs([
  { testSystem => 'slim:fitnesse.slim.SlimService', command => 'java -cp fitnesse.jar ... 1',
    exitCode => '0', exceptions => [] },
], '127.0.0.1',1,\@labels,'pipe','/repo/bin/perl-slim');
ok($java_pipe->{failed},'Java SlimService is not accepted as pipe backend evidence');
my $wrong_label = verify_suite_execution_logs([
  { %{$logs->[0]}, testSystem => 'slim:fitnesse.slim.JavaSlimService' },
], '127.0.0.1',19099,\@labels);
ok($wrong_label->{failed},'unexpected Java test-system label fails attribution');
my $wrong_host = verify_suite_execution_logs([
  { %{$logs->[0]}, command => 'Connection to running SlimService: 127.0.0.1:8099' },
], '127.0.0.1',19099,\@labels);
ok($wrong_host->{failed},'connection to a different listener fails attribution');
my $failed_system = verify_suite_execution_logs([
  { %{$logs->[0]}, exitCode => '15' },
], '127.0.0.1',19099,\@labels);
ok($failed_system->{failed},'nonzero test-system exit status fails attribution');
my $exception_system = verify_suite_execution_logs([
  { %{$logs->[0]}, exceptions => ['connection failed'] },
], '127.0.0.1',19099,\@labels);
ok($exception_system->{failed},'test-system exceptions fail attribution');
ok(verify_suite_execution_logs([], '127.0.0.1',19099,\@labels)->{failed},
  'missing execution logs fail attribution');

my $trace = verify_perl_trace("command=[one]\nresponse=[one]\ncommand=[two]\nresponse=[two]\n");
is_deeply([$trace->{commands},$trace->{responses}], [2,2],
  'Perl request and response trace is counted');
ok(!$trace->{failed},'balanced protocol traffic confirms an active Perl service');
ok(verify_perl_trace('server ready only')->{failed},'startup without protocol traffic is insufficient evidence');
ok(verify_perl_trace("command=[one]\nresponse=[one]\ncommand=[two]\n")-> {failed},
  'missing Perl response is a service failure');

my $tmp = tempdir(CLEANUP => 1);
my $jar = "$tmp/fitnesse.zip";
my $zip = IO::Compress::Zip->new($jar,Name=>'Resources/FitNesseRoot/Suite/Leaf/content.txt')
  or die "create ZIP fixture: $ZipError";
print {$zip} 'kept' or die "write ZIP fixture: $ZipError";
$zip->newStream(Name=>'Resources/FitNesseRoot/MySuite/Generated/content.txt')
  or die "create generated-page stream: $ZipError";
print {$zip} 'discarded' or die "write generated-page stream: $ZipError";
close $zip or die "close ZIP fixture: $ZipError";
my $destination = "$tmp/extracted/FitNesseRoot";
extract_wiki_from_jar($jar,$destination);
open my $page, '<', "$destination/Suite/Leaf/content.txt" or die $!;
is(scalar(<$page>),'kept','clean wiki is extracted from the pinned JAR resources');
close $page;
ok(!-e "$destination/MySuite",'JAR extraction excludes generated MySuite content');
my $runner = abs_path('bin/perl-slim');
configure_pipe_wiki($destination,$runner);
open my $root_content, '<', "$destination/content.txt" or die $!;
my $root_text = do { local $/; <$root_content> };
close $root_content;
like($root_text,qr/!define SLIM_PORT \{1\}/,'pipe configuration selects FitNesse port 1');
like($root_text,qr/\Q$runner\E/,'pipe configuration names the repository Perl executable');
unlike($root_text,qr/!define\s+TEST_SYSTEM\b/,
  'pipe transport setup does not make every generated wiki page a Slim test');
is(pipe_query($runner), '&COMMAND_PATTERN=%25m&TEST_RUNNER=' . do { my $encoded = $runner; $encoded =~ s/([^A-Za-z0-9_.~-])/sprintf('%%%02X',ord($1))/ge; $encoded } . '&SLIM_PORT=1',
  'pipe URL query encodes the command pattern and runner path');

SKIP: {
  skip 'pinned FitNesse JAR is unavailable for startup failure fixtures', 6
    unless -f '/opt/fitnesse/fitnesse.jar';
  my $run_tmp = tempdir(CLEANUP => 1);
  my $runner = abs_path('bin/test-fitnesse-suite');
  my $repo = abs_path('.');
  my $run_failure = sub {
    my($name,$extra_env) = @_;
    my $output = "$run_tmp/$name.log";
    my $pid = fork();
    die "fork runner failure fixture: $!" unless defined $pid;
    if (!$pid) {
      open STDOUT, '>', $output or die "open $output: $!";
      open STDERR, '>&', STDOUT or die "redirect stderr: $!";
      $ENV{TEST_SLIM_SUITE_LOG_DIR} = "$run_tmp/$name-runtime";
      $ENV{TEST_SLIM_SUITE_STARTUP_TIMEOUT} = 5;
      $ENV{TEST_SLIM_SUITE_TOTAL_TIMEOUT} = 15;
      $ENV{FITNESSE_JAR} = '/opt/fitnesse/fitnesse.jar';
      $ENV{PERL5LIB} = File::Spec->catdir($repo,'lib') . ':' . File::Spec->catdir($repo,'t/lib');
      $ENV{$_} = $extra_env->{$_} for keys %$extra_env;
      chdir $repo or die "chdir $repo: $!";
      exec {$^X} $^X, $runner, '--transport', 'tcp';
      die "exec $runner: $!";
    }
    waitpid($pid,0);
    my $status = $? >> 8;
    open my $fh, '<', $output or die "read $output: $!";
    local $/;
    my $text = <$fh> // '';
    close $fh;
    return ($status,$text,"$run_tmp/$name-runtime");
  };

  my($perl_status,$perl_output) = $run_failure->('perl-start-failure',
    { TEST_SLIM_SUITE_PERL_EXECUTABLE => '/bin/false' });
  is($perl_status,1,'Perl listener startup failure returns nonzero');
  like($perl_output,qr/Perl SLiM exited before readiness/,
    'Perl listener startup failure is identified');

  my($fitnesse_status,$fitnesse_output) = $run_failure->('fitnesse-start-failure',
    { JAVA => '/bin/false' });
  is($fitnesse_status,1,'FitNesse startup failure returns nonzero');
  like($fitnesse_output,qr/FitNesse exited before readiness/,
    'FitNesse startup failure is identified');
  my($port) = $fitnesse_output =~ /Started external Perl SLiM on 127\.0\.0\.1:(\d+)/;
  ok(defined($port),'the failed FitNesse run had started its external Perl child');
  ok(defined($port) && !probe_slim('127.0.0.1',$port,0.2)->{ready},
    'runner cleanup terminated the Perl child after FitNesse startup failure');
}

done_testing();
