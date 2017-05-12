package Misc::Stopwatch;
use strict;
our $VERSION = 0.1;
use Time::HiRes qw(gettimeofday tv_interval);

# ------------------------------------------------------------------------------
# new - Construct a new Misc::Stopwatch
# new
# ------------------------------------------------------------------------------
#|test(!abort) use Misc::Stopwatch;
#|test(true) my $sw = Misc::Stopwatch->new();
# ------------------------------------------------------------------------------

sub new {
  bless [], (ref($_[0]) || $_[0]);
}

# ------------------------------------------------------------------------------
# start - Reset and Start the stopwatch
# start
# Returns C<$self>.
#
# Note that calling this on an already-running instance will reset it.
# ------------------------------------------------------------------------------
#|test(!abort) my $sw = Misc::Stopwatch->new()->start();
# ------------------------------------------------------------------------------

sub start {
  $_[0]->reset();
  $_[0]->_capture();
}

# ------------------------------------------------------------------------------
# lap - Preserve the elapsed time without stopping
# lap
#
# Returns C<$self>.
#
# This is is a no-op unless the stopwatch is running.
# ------------------------------------------------------------------------------
#|test(!abort) my $sw = Misc::Stopwatch->new()->start()->lap();
# ------------------------------------------------------------------------------

sub lap {
  return $_[0] unless $_[0]->is_running;
  $_[0]->_capture();
}

# ------------------------------------------------------------------------------
# stop - Stop
# stop
# Returns C<$self>.
# ------------------------------------------------------------------------------
#|test(!abort) my $sw = Misc::Stopwatch->new()->start()->stop();
# ------------------------------------------------------------------------------

sub stop {
  $_[0]->lap();
  push @{$_[0]}, undef;
  $_[0];
}

# ------------------------------------------------------------------------------
# elapsed - Return the elapsed time
# elapsed $lap
# elapsed
# In its second form, elapsed will return the time from L</start> to now (or when
# L</stop> was called).
# 
# C<undefined> is returned when:
#
# 1.) C<$lap> is provided but no such lap exists
#
# 2.) L</is_running> returns a false value
# ------------------------------------------------------------------------------
#|test(true) Misc::Stopwatch->new()->start()->elapsed();
# ------------------------------------------------------------------------------

sub elapsed {
  my ($self, $lap) = @_;
  my ($b, $e) = ($$self[0], undef);
  if (defined $lap) {
    $e = $$self[$lap];
  } elsif ($self->is_running) {
    $e = [gettimeofday];
  } else {
    $e = $$self[-2];
  }
  defined ($b && $e) ? tv_interval($b, $e) : 0;
}

# ------------------------------------------------------------------------------
# reset - Stop and clear data
# reset
# Returns C<$self>.
# ------------------------------------------------------------------------------
#|test(!abort) my $sw = Misc::Stopwatch->new()->reset();
# ------------------------------------------------------------------------------

sub reset {
  @{$_[0]} = ();
  $_[0];
}

# ------------------------------------------------------------------------------
# is_running - Boolean logic
# is_running
# Returns a true value if the stopwatch has been started and has not been 
# stopped.
# ------------------------------------------------------------------------------
#|test(false) Misc::Stopwatch->new()->is_running();
#|test(true) Misc::Stopwatch->new()->start()->is_running();
# ------------------------------------------------------------------------------

sub is_running {
  defined $_[0][$#{$_[0]}];
}

# ------------------------------------------------------------------------------
# _capture - Capture the moment
# _capture
# ------------------------------------------------------------------------------

sub _capture {
  push @{$_[0]}, [gettimeofday];
  $_[0];
}

1;

__END__

=pod:summary Measure elapsed time

=pod:synopsis

  #!/usr/bin/perl
  use Misc::Stopwatch;
  my $sw = Misc::Stopwatch->new()->start();
  for (1 .. 3) {
    sleep 1;
    $sw->lap();
  }
  $sw->stop();
  printf "Lap 1: %f\n", $sw->elapsed(1);
  printf "Lap 2: %f\n", $sw->elapsed(2);
  printf "Lap 3: %f\n", $sw->elapsed(3);
  printf "Total: %f\n", $sw->elapsed();

Will output something like:

  Lap 1: 1.000244
  Lap 2: 2.000375
  Lap 3: 3.000527
  Total: 3.000544

=pod:description

This module provides convenient methods as expected from a stopwatch.

  start       Starts the stopwatch
  lap         Marks a lap time
  stop        Stops it
  elapsed     Returns the elapsed time
  reset       Stops if running and clears all laps
  is_running  True or False

Similar modules:

C<Time::Stopwatch> - provides a tied interface and will work without 
C<Time::HiRes>.

C<Benchmark::Stopwatch> - is mostly identical, however does not have the 
C<elapsed> method.

=cut
