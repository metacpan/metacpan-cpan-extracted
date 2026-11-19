#!/usr/bin/env perl
use threads; use threads::shared;

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops btw/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug run_perlscript ts tsstr timed_run_hresult/;

STDERR->autoflush();
STDOUT->autoflush();

use POSIX ();
use Time::HiRes qw/sleep/;

use feature 'signatures';

#################################################################
# Check that jobs actually run on concurrent threads
#################################################################

use Thread::DependentJobs qw/my_jobid/;
Thread::DependentJobs->Configure(DEBUG => $debug);

my $numcpus = $ENV{NUMBER_OF_PROCESSORS}  # provided by Windows
    || (`grep "processor\t:" /proc/cpuinfo  | wc -l`);
chomp $numcpus;
unless (looks_like_number($numcpus) && $numcpus >= 1) {
  skip_all("Can not determine number of CPUs");
}

my $num_threads = min($numcpus, 3); # use at most 3 threads

use constant SLEEP_SECS => 2;

#----------------------------------------------------------
sub _inner_spin($count) {
  for (my $n=0; $n < $count; $n++) {
    my $t=0; for (my $i=0;$i<20000;++$i) {
      $t += (((((((((($i*1.001)/1.01)/1)/123)/1)/1)*1)*1)*1)*1);
    }
  }
}
use constant CYCLES_PER_SEC => do{ # calibrate to CPU speed
  _inner_spin(10); # warmup
  my $t0 = Time::HiRes::time();
  my $tot;
  for ($tot=0; ;$tot++) {
    _inner_spin(1);
    my $t1 = Time::HiRes::time();
    last if ($t1-$t0) >= 1/5;
  }
  ($tot+1) *5
};
sub spin($secs) {
  _inner_spin($secs * CYCLES_PER_SEC);
}
if (1 or $debug) {
  note "CYCLES_PER_SEC = ",CYCLES_PER_SEC,"\n";
  note "SLEEP_SECS = ",SLEEP_SECS,"\n";
  note "numcpus = ",$numcpus,"\n";
  note "num_threads = ",$num_threads,"\n";
}
#----------------------------------------------------------

spinner(args => [2]) if $debug; ## TEST IN MAIN THREAD

my %results_direct :shared ;

my $jobsch = Thread::DependentJobs->new(NUMTHREADS => $num_threads);

note tsstr, " [main] before scheduling any jobs";
my @jobids;
for my $n (1..$num_threads) {
  push @jobids, $jobsch->sched(subname => 'spinner', context => 'scalar',
                               args => [SLEEP_SECS, \%results_direct]);
}
my $r = $jobsch->wait();
for my $jobid(sort keys %$r) {
  my $h = $r->{$jobid};
  die "Job $jobid failed: $h->{ABORTMSG}" if $h->{ABORTMSG};
  my $result = $h->{RESULT} // oops dvis '$h';
  # If they ran in parallel, the wall time should approximately equal cpu time.
  note dvis '### $result' if $debug;
  oops dvis '%results_direct\n$result'
    unless exists $result->{secs};
  ok(abs($result->{et}-SLEEP_SECS) < SLEEP_SECS,
     "Job $jobid : actual et=$result->{et} vs SLEEP_SECS=${\SLEEP_SECS}");
  oops dvis '%results_direct\n$result'
    if $result->{et} != $results_direct{$jobid}->{et};
}
note tsstr, " [main] after  wait";

done_testing;

sub spinner(%params) {
  my $tid = threads->tid;
  my $jobid = my_jobid();
  my ($secs, $result_href) = @{ $params{args} };
  note tsstr, " [$tid] spinner starting secs=$secs";
  my $t0 = Time::HiRes::time();
  spin($secs);
  my $t1 = Time::HiRes::time();
  my $actual_et = $t1 - $t0;
  note tsstr, " [$tid] spin $secs secs done, took $actual_et wall-clock secs";
  if (defined $result_href) {
    lock $result_href;
    # Test both storing by ref
    $result_href->{$jobid} = shared_clone {secs => $secs, et => $actual_et};
  }
  # ...and as a return value
  return {secs => $secs, et => $actual_et};
}
