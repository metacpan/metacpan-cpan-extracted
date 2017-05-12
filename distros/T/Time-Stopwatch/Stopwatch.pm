package Time::Stopwatch;
$VERSION = '1.00';

# POD documentation after __END__ below

use strict;
use constant HIRES => eval { local $SIG{__DIE__}; require Time::HiRes };

sub TIESCALAR {
    my $pkg = shift;
    my $time = (HIRES ? Time::HiRes::time() : time()) - (@_ ? shift() : 0);
    bless \$time, $pkg;
}

sub FETCH { (HIRES ? Time::HiRes::time() : time()) - ${$_[0]}; }
sub STORE { ${$_[0]} = (HIRES ? Time::HiRes::time() : time()) - $_[1]; }

"That's all, folks!"
__END__

=head1 NAME

Time::Stopwatch - Use tied scalars as timers

=head1 SYNOPSIS

    use Time::Stopwatch;
    tie my $timer, 'Time::Stopwatch';

    do_something();
    print "Did something in $timer seconds.\n";

    my @times = map {
        $timer = 0;
        do_something_else();
        $timer;
    } 1 .. 5;

=head1 DESCRIPTION

The Time::Stopwatch module provides a convenient interface to
timing functions through tied scalars.  From the point of view of the
user, scalars tied to the module simply increase their value by one
every second.

Using the module should mostly be obvious from the synopsis.  You can
provide an initial value for the timers either by assigning to them or
by passing the value as a third argument to tie().

If you have the module Time::HiRes installed, the timers created by
Time::Stopwatch will automatically count fractional seconds.  Do
I<not> assume that the values of the timers are always integers.  You
may test the constant C<Time::Stopwatch::HIRES> to find out whether
high resolution timing is enabled.

=head2 A note on timing short intervals

Time::Stopwatch is primarily designed for timing moderately long
intervals (i.e. several seconds), where the overhead imposed by the
tie() interface does not matter.  With Time::HiRes installed, it can
nonetheless be used for even microsecond timing, provided that
appropriate care is taken.

=over 4

=item *

Explicitly initialize the timer by assignment.  The first measurement
taken before resetting the timer will be a few microseconds longer due
to the overhead of the tie() call.

=item *

B<Always> subtract the overhead of the timing code.  This is true in
general even if you're not using Time::Stopwatch.  (High-level
benchmarking tools like Benchmark.pm do this automatically.)  See the
code example below.

=item *

Take as many measurements as you can to minimize random errors.  The
Statistics::Descriptive module may be useful for analyzing the data.
This advice is also true for all benchmarking.

=item *

Remember that a benchmark measures the time take to run the benchmark.
Any generalizations to real applications may or may not be valid.  If
you want real world data, profile the real code in real use.

=back

The following sample code should give a relatively reasonable
measurement of a the time taken by a short operation:

    use Time::HiRes;  # high resolution timing required
    use Time::Stopwatch;

    use Statistics::Descriptive;
    my $stat = Statistics::Descriptive::Sparse->new();

    tie my $time, 'Time::Stopwatch';  # code timer
    tie my $wait, 'Time::Stopwatch';  # loop timer

    while ($wait < 60) {  # run for one minute
        my $diff = 0;
        $time = 0; do_whatever(); $diff += $time;
        $time = 0;                $diff -= $time;
        $stat->add_data($diff);
    }

    print("count: ", $stat->count(), " iterations\n",
          "mean:  ", $stat->mean(), " seconds\n",
          "s.d.:  ", $stat->standard_deviation(), " seconds\n");

Note that the above code includes the time of the subroutine call in
the measurement.

=head1 BUGS

Since tied scalars do not (yet?) support atomic modification, use of
operators like C<$t++> or C<$t *= 2> on timers will cause them to lose
the time it takes to fetch, modify and store the value.  I I<might> be
able to get around this by overloading the return value of C<FETCH>,
but I doubt if it's worth the trouble.  Just don't do that.

There is no way to force low-resolution timing if Time::HiRes has been
installed.  I'm not sure why anyone would want to, since int() will do
just fine if you want whole seconds, but still..

=head1 CHANGE LOG

=over 4

=item 1.00 (15 Mar 2001)

Explicitly localized C<$SIG{__DIE__}> when testing for Time::HiRes
availability.  Added "A note on timing short intervals" to the POD
documentation.  Bumped version to 1, no longer beta.

=item 0.03 (27 Feb 2001)

Modified tests to give more information, reduced subsecond accuracy
test to 1/10 seconds to allow for inaccurate select() implementations.
Tweaked synopsis and README.

=back

=head1 SEE ALSO

Time::HiRes, L<perlfunc/tie>

For a higher-level approach to timing, try (among others) the modules
Time::SoFar, Devel::Timer, or Benchmark.  Also see the profiling
modules Devel::DProf, Devel::SmallProf and Devel::OpProf.

=head1 AUTHORS

Copyright 2000-2001, Ilmari Karonen.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: perl@itz.pp.sci.fi

=cut
