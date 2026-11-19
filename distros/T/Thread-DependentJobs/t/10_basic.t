#!/usr/bin/env perl
use threads; use threads::shared;

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug run_perlscript/;

use feature 'signatures';

use Spreadsheet::Edit::Log qw/:btw :time set_logdest/;
btw_rjust_prefix(1);

use POSIX ();
use Time::HiRes qw/sleep/;
STDERR->autoflush();
STDOUT->autoflush();
set_logdest(\*STDOUT);

use Thread::DependentJobs;
Thread::DependentJobs->Configure(DEBUG => $debug);
use Thread::Semaphore ();

my %created :shared;

my %copied_inputs :shared;
my %copied_outputs :shared;

{
my $sema1 = Thread::Semaphore->new() // oops; # default count==1

my $jobsch = Thread::DependentJobs->new(NUMTHREADS => undef);
note "Created job scheduler having ",$jobsch->get_numthreads, " threads.\n";

note "Created ws ",addrvis($jobsch);

my $sema2 = Thread::Semaphore->new(2) // oops; # default count==1

my $j0 = $jobsch->sched(subname => "jobfunc", inputs => ["xxx"], semas => [$sema1]);

#btw visnew->dviso('$jobsch');

my $j1 = $jobsch->sched(subname => "bomb", outputs => ["xxx"], semas => [[$sema2,2,2], $sema1]);

my $j2 = $jobsch->sched(subname => "jobfunc", args=>[11..15], outputs => ["ccc"], inputs => ["bbb", "aaa"], context => 'list');
my $j3 = $jobsch->sched(subname => "jobfunc", args=>[1..5], outputs => ["aaa"], inputs => []);
my $j4 = $jobsch->sched(subname => "jobfunc", args=>[6..10], outputs => ["bbb"], inputs => ["aaa"]);
#$jobsch->abort_job($j4);
#btw dvis '$j0 $j1 $j2 $j3 $j4';

my $r = $jobsch->wait();

btw dvis '$j0 $j1 $j2 $j3 $j4 %copied_inputs %copied_outputs' if $debug;

# j0 needed 'xxx', which was poisoned when j1 died
like($r->{$j0}->{ABORTMSG}, qr/cancelled|poisoned/i);
like($copied_inputs{$j0}, undef);
like($copied_outputs{$j0}, undef);

# j1 was to produce 'xxx' but died
like($r->{$j1}->{ABORTMSG}, qr/die/i, "j1 results");
like($r->{$j1}->{EXCEPTION}, {msg => "death bomb: ", data => {uuu1 => [33..36], uuu2 => "foo"}});
like($copied_inputs{$j1}, undef);
like($copied_outputs{$j1}, undef);

# j2, run in list context, consumed 'bbb' and 'aaa' and produced 'ccc'
#btw dvis '$r';
like($r->{$j2}->{RESULT}, [11,12,13,14], "j2 results");
ok(! exists $r->{$j2}->{ABORTMSG});
ok(! exists $r->{$j2}->{EXCEPTION});
like($copied_inputs{$j2}, ["bbb", "aaa"]);
like($copied_outputs{$j2}, ["ccc"]);

# j3, run in scalar context, produced 'aaa'
like($r->{$j3}->{RESULT}, 14, "j3 results");
ok(! exists $r->{$j3}->{ABORTMSG});
ok(! exists $r->{$j3}->{EXCEPTION});
like($copied_inputs{$j3}, []);
like($copied_outputs{$j3}, ["aaa"]);

# j4 consumed 'aaa' and produced 'bbb'
like($r->{$j4}->{RESULT}, 14, "j4 results");
ok(! exists $r->{$j4}->{ABORTMSG});
ok(! exists $r->{$j4}->{EXCEPTION});
like($copied_inputs{$j4}, ["aaa"]);
like($copied_outputs{$j4}, ["bbb"]);

}

done_testing();
exit 0;

sub jobfunc(%params) {
  my $tid = threads->tid;
  my $jobsch = $params{js} // oops;
  my $jobid = $jobsch->my_jobid();
  if (1 or $debug) {
    btw "## [$tid] #############################\n",
        dvis('jobfunc: $jobid %params wantarray='),vis(wantarray);
  }
  foreach my $token (@{ $params{inputs} }) {
    ok($created{$token}, "[$tid] $jobid My input {${\vis($token)}}} was created");
  }
  foreach my $token (@{ $params{outputs} }) {
    note "[$tid] $jobid setting created[",vis($token),"]\n";
    lock %created;
    $created{$token} = $jobsch->my_jobid();
  }
  { lock %copied_outputs; $copied_outputs{$jobid} = $params{outputs}; }
  { lock %copied_inputs;  $copied_inputs{$jobid}  = $params{inputs}; }
  #sleep 1;
  (11,12,13,14)
}
sub bomb(%params) {
  my %unshared = (uuu1 => [33..36], uuu2 => "foo");
  #sleep 0.5;
  die {msg => "death bomb: ", data => \%unshared};
}
