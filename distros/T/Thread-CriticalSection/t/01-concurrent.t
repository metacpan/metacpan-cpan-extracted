#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use File::Temp qw/ :POSIX /;

use threads;
use Thread::CriticalSection;

# create 25 pairs of threads, one increments, the other decrements a counter
# run each thread for 100 loops
# counter must be zero at the end

my $n_threads = 50;
my $n_loops = 250;
my $cs = Thread::CriticalSection->new;

my $c_inside : shared;
my $m_inside : shared;

sub _unsafe_add_delta_to_counter {
  my ($delta, $n_loops, $counter_fn) = @_;
  
  while ($n_loops--) {
    my $counter = _counter_read($counter_fn);
    $c_inside++;
    $m_inside++ unless $c_inside == 1;
#    diag("value '$counter' from '$counter_fn', iter '$n_loops/$delta/$c_inside/$m_inside'");
    $counter += $delta;
    _counter_write($counter_fn, $counter);
    $c_inside--;
  }
}

sub _safe_add_delta_to_counter {
  my ($delta, $n_loops, $counter_fn) = @_;
  
  while ($n_loops--) {
    $cs->execute(sub {
      my $counter = _counter_read($counter_fn);
      $c_inside++;
      $m_inside++ unless $c_inside == 1;
#      diag("value '$counter' from '$counter_fn', iter '$n_loops/$delta/$c_inside/$m_inside'");
      $counter += $delta;
      _counter_write($counter_fn, $counter);
      $c_inside--;
    });
  }
}


# Start the racers, unsafe race

diag("First tests are supposed to cause havoc, including abnormal thread terminations.");
$m_inside = 0; $c_inside = 0;
my $value = _run_threads(\&_unsafe_add_delta_to_counter, $n_threads, $n_loops);
ok($value, "Counter is not 0 ($value), not safe updates");
ok($m_inside, "Had some ($m_inside) multiple insiders");

# Start the racers, safe race
$m_inside = 0; $c_inside = 0;
$value = _run_threads(\&_safe_add_delta_to_counter, $n_threads, $n_loops);
ok(!$value, 'Counter is 0, safe updates');
ok(!$m_inside, "None ($m_inside) multiple insiders detected");


##############
# Thread stuff

sub _run_threads {
  my ($sub, $n_threads, $n_loops) = @_;
  my @thrs;
  
  # Create and reset counter to 0
  my $counter_fn = tmpnam();
  _counter_write($counter_fn, 0);
  
  diag("Starting all $n_threads thread pairs");
  while ($n_threads--) {
    push @thrs, scalar(threads->create($sub, +1, $n_loops, $counter_fn));
    push @thrs, scalar(threads->create($sub, -1, $n_loops, $counter_fn));
  }
  
  diag("Waiting for all threads to join us");
  foreach my $thr (@thrs) {
    $thr->join;
  }
  
  diag("Thread's dead baby, thread's dead");
  return _counter_read($counter_fn);
}


###############
# Counter funcs

sub _counter_write {
  my ($fn, $value) = @_;
  my $tid = threads->tid();
  my $new_fn = "$fn.$tid";
  
  my $fh;
  open($fh, '>', $new_fn) || die "Could not create temp file '$new_fn': $!,";
  $fh->syswrite($value)   || die "Could not write '$value' to '$new_fn': $!";
  close($fh)              || die "Could not close file '$new_fn': $!";
  rename($new_fn, $fn)    || die "Could not rename '$new_fn' to '$fn': $!";
  
  return;
}

sub _counter_read {
  my ($fn) = @_;
  my $value;
  
  my $fh;  
  open($fh, '<', $fn)      || die "Could not open file '$fn': $!,";
  $fh->sysread($value, 50) || die "Could not read from '$fn': $!";
  close($fh)               || die "Could not close file '$fh': $!";
  
  return $value;
}
