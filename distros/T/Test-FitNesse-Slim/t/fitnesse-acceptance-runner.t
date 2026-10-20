use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use Test::More;
use lib 't/lib';
use Test::FitNesse::Slim::FitNesseAcceptance qw(
  bounded_request
  compare_page_counts
  compare_inventory
  free_port
  missing_wiki_pages
  parse_page_result
  perl_pipe_command_matches
  probe_slim
  preserve_exit_status
  start_owned_process
  owned_process_exited
  stop_owned_processes
  true_property_pages_in_wiki
  wait_until
);

sub baseline_page {
  my($page,$status) = @_;
  return { page => $page, conformance => { status => $status } };
}

sub successful_result {
  my(%args) = @_;
  return {
    status => 'completed',
    conformance => $args{conformance} || 'conformant',
    externalPerlConfirmed => exists($args{external}) ? $args{external} : 1,
  };
}

my @baseline = (
  baseline_page('PassingPage','conformant'),
  baseline_page('KnownFailure','harness_limited'),
);

my $allocated_port = free_port('127.0.0.1');
ok($allocated_port > 0, 'shared acceptance helper allocates an ephemeral port');
ok(!defined(wait_until('immediate fixture',1,sub { 1 })),
  'shared readiness helper returns when its condition is satisfied');
my($process_log_fh,$process_log) = tempfile();
close $process_log_fh;
my $owned = start_owned_process($^X,'-e','sleep 10',{log_file => $process_log});
ok($owned > 0, 'shared process helper starts an owned process');
ok(!owned_process_exited(), 'running owned process is not reported as exited');
stop_owned_processes();
is(waitpid($owned,1),-1, 'shared cleanup reaps the owned process');

my $clean = compare_inventory(\@baseline, {
  PassingPage => successful_result(),
  KnownFailure => successful_result(conformance => 'nonconformant'),
});
ok(!$clean->{failed}, 'known non-conformance is allowed');
is_deeply($clean->{knownFailures}, ['KnownFailure'], 'known failure remains reported');

my $missing = compare_inventory(\@baseline, { PassingPage => successful_result() });
ok($missing->{failed}, 'missing inventory page fails comparison');
is_deeply($missing->{missing}, ['KnownFailure'], 'missing page is identified');
is_deeply($missing->{unexecuted}, ['KnownFailure'], 'missing page is also unexecuted');

my $execution = compare_inventory(\@baseline, {
  PassingPage => { status => 'execution_error', error => 'HTTP 500' },
  KnownFailure => successful_result(conformance => 'nonconformant'),
});
ok($execution->{failed}, 'failed page execution fails comparison');
is_deeply($execution->{unexecuted}, ['PassingPage'], 'execution error is unexecuted');

my $regression = compare_inventory(\@baseline, {
  PassingPage => successful_result(conformance => 'nonconformant'),
  KnownFailure => successful_result(conformance => 'nonconformant'),
});
ok($regression->{failed}, 'previously conformant page regression fails comparison');
is_deeply($regression->{regressions}, ['PassingPage'], 'regressed page is identified');

my $newly_passing = compare_inventory(\@baseline, {
  PassingPage => successful_result(),
  KnownFailure => successful_result(),
});
ok(!$newly_passing->{failed}, 'newly passing page is not a failure');
is_deeply($newly_passing->{newlyConformant}, ['KnownFailure'], 'newly conformant page is reported');

my $no_perl = compare_inventory(\@baseline, {
  PassingPage => successful_result(external => 0),
  KnownFailure => successful_result(conformance => 'nonconformant'),
});
ok($no_perl->{failed}, 'unverified external Perl service fails comparison');
is_deeply($no_perl->{serviceFailures}, ['PassingPage'], 'service failure is attributed to page');

my($timed_response,$timed_error) = bounded_request(0.05, sub { select undef,undef,undef,1; 'late' });
ok(!defined($timed_response), 'hung request returns without a response');
like($timed_error, qr/request timed out/, 'hung request is reported as a timeout');

open my $response_fh, '<', 't/data/fitnesse-page-result.xml' or die $!;
local $/;
my $xml = <$response_fh>;
close $response_fh;
my $parsed = parse_page_result($xml,200,'127.0.0.1',8099);
is($parsed->{status}, 'completed', 'saved FitNesse XML is parsed as completed');
is_deeply($parsed->{counts}, { right => 3, wrong => 1, ignored => 2, exceptions => 0 },
  'primary assertion totals are parsed');
is($parsed->{conformance}, 'nonconformant', 'wrong assertions affect conformance');
ok($parsed->{externalPerlConfirmed}, 'execution log confirms external Perl connection');

my $pipe_xml = $xml;
$pipe_xml =~ s{<testSystem>.*?</testSystem>}{<testSystem>slim:/repo/bin/perl-slim</testSystem>}s;
$pipe_xml =~ s{<command>.*?</command>}{<command>/repo/bin/perl-slim 1</command>}s;
my $pipe_result = parse_page_result($pipe_xml,200,'127.0.0.1',8099,'pipe','/repo/bin/perl-slim');
ok($pipe_result->{perlExecutionConfirmed}, 'pipe execution log confirms the Perl child command');
ok(!$pipe_result->{externalPerlConfirmed}, 'a child process is not mislabeled as an external listener');
my $flagged_pipe_xml = $pipe_xml;
$flagged_pipe_xml =~ s{<command>.*?</command>}{<command>/repo/bin/perl-slim -v -s 1 1</command>}s;
ok(parse_page_result($flagged_pipe_xml,200,'127.0.0.1',8099,'pipe','/repo/bin/perl-slim')
    ->{perlExecutionConfirmed}, 'FitNesse -v -s flags retain Perl child attribution');
ok(perl_pipe_command_matches('/repo/bin/perl-slim -s 1 -v 1','/repo/bin/perl-slim'),
  'command verifier accepts supported options before the port');
ok(!perl_pipe_command_matches('/repo/bin/perl-slim -x 1','/repo/bin/perl-slim'),
  'command verifier rejects unknown flags');

my @count_baseline = ({ page => 'P', rawCounts => { right => 2, wrong => 1, ignored => 0, exceptions => 0 } });
my $same_counts = compare_page_counts(\@count_baseline,
  { P => { counts => { right => 2, wrong => 1, ignored => 0, exceptions => 0 } } });
ok(!$same_counts->{failed}, 'per-page exact tuple comparison accepts the baseline');
my $changed_counts = compare_page_counts(\@count_baseline,
  { P => { counts => { right => 3, wrong => 0, ignored => 0, exceptions => 0 } } });
ok($changed_counts->{failed}, 'per-page tuple comparison catches count shifts with equal aggregate total');

my $uppercase_system_xml = $xml;
$uppercase_system_xml =~ s/<testSystem>slim:/<testSystem>SLIM:/;
ok(parse_page_result($uppercase_system_xml,200,'127.0.0.1',8099)->{externalPerlConfirmed},
  'FitNesse uppercase SLIM label still confirms the external connection');

my $wrong_service_xml = $xml;
$wrong_service_xml =~ s/fitnesse\.slim\.SlimService/fitnesse\.slim\.JavaSlimService/;
my $wrong_service = parse_page_result($wrong_service_xml,200,'127.0.0.1',8099);
ok(!$wrong_service->{externalPerlConfirmed}, 'built-in Java Slim is not mistaken for external Perl');
is(parse_page_result('<html/>',500,'127.0.0.1',8099)->{status}, 'execution_error',
  'HTTP failure is an execution error');
is(parse_page_result('<html/>',200,'127.0.0.1',8099)->{status}, 'execution_error',
  'HTTP success without FitNesse results is an execution error');

my $tmp = tempdir(CLEANUP => 1);
my $page_dir = "$tmp/Suite/LeafPage";
require File::Path;
File::Path::make_path($page_dir);
open my $properties, '>', "$page_dir/properties.xml" or die $!;
print {$properties} "<properties><Test>true</Test></properties>\n";
close $properties;
is_deeply(missing_wiki_pages($tmp, [ baseline_page('Suite.LeafPage','conformant') ]), [],
  'wiki page is recognized only when its Test property is true');
is_deeply(missing_wiki_pages($tmp, [ baseline_page('Suite.Missing','conformant') ]), ['Suite.Missing'],
  'missing required wiki page is reported');
File::Path::make_path("$tmp/Suite/ExtraPage", "$tmp/Suite/NotATest");
open my $extra_properties, '>', "$tmp/Suite/ExtraPage/properties.xml" or die $!;
print {$extra_properties} "<properties><Test>true</Test><Suites>slim</Suites></properties>\n";
close $extra_properties;
open my $not_test_properties, '>', "$tmp/Suite/NotATest/properties.xml" or die $!;
print {$not_test_properties} "<properties><Test>false</Test></properties>\n";
close $not_test_properties;
is_deeply(true_property_pages_in_wiki($tmp), ['Suite.ExtraPage', 'Suite.LeafPage'],
  'baseline inventory detects explicit Test=true pages');

my $unbound = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
  Proto => 'tcp', Listen => 1, ReuseAddr => 1) or die "bind test socket: $!";
my $unused_port = $unbound->sockport;
close $unbound;
my $probe = probe_slim('127.0.0.1',$unused_port,0.1);
ok(!$probe->{ready}, 'unavailable SLiM service is not ready');
ok(!$probe->{reachable}, 'unavailable SLiM service is reported as service failure');

my $wrong_listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
  Proto => 'tcp', Listen => 1, ReuseAddr => 1) or die "bind wrong-service socket: $!";
my $wrong_port = $wrong_listener->sockport;
my $wrong_pid = fork();
die "fork wrong-service fixture: $!" unless defined $wrong_pid;
if (!$wrong_pid) {
  my $client = $wrong_listener->accept or exit 1;
  print {$client} "HTTP/1.1 200 OK\r\n\r\n";
  close $client;
  close $wrong_listener;
  exit 0;
}
my $wrong_probe = probe_slim('127.0.0.1',$wrong_port,0.5);
close $wrong_listener;
waitpid($wrong_pid,0);
ok($wrong_probe->{reachable}, 'wrong protocol listener is detected as reachable');
ok(!$wrong_probe->{ready}, 'HTTP listener is not accepted as a SLiM service');

for my $requested_status (0, 1) {
  my($status_fh, $wait_status_file) = tempfile();
  close $status_fh;
  my $script = <<'PERL';
use strict;
use warnings;
use POSIX qw(:sys_wait_h);
use lib 't/lib';
use Test::FitNesse::Slim::FitNesseAcceptance qw(preserve_exit_status);
my $pid = fork();
die "fork cleanup child: $!" unless defined $pid;
if (!$pid) { sleep 30; exit 0 }
END {
  preserve_exit_status(sub {
    kill 'TERM', $pid;
    waitpid($pid, 0);
    open my $fh, '>', $ARGV[1] or die "open wait status: $!";
    print {$fh} $?;
    close $fh;
  });
}
exit $ARGV[0];
PERL
  my $status = system($^X, '-e', $script, $requested_status, $wait_status_file);
  is($status >> 8, $requested_status,
    "cleanup preserves requested runner exit status $requested_status");
  is($status & 127, 0, 'runner process exits normally after terminating its child');
  open my $wait_fh, '<', $wait_status_file or die $!;
  my $child_status = <$wait_fh>;
  close $wait_fh;
  is($child_status, 15, 'cleanup reaps the child terminated with SIGTERM');
}

done_testing();
