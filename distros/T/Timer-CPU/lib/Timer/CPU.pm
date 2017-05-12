package Timer::CPU;

our $VERSION = '0.100';

use strict;


require XSLoader;   
XSLoader::load('Timer::CPU', $VERSION);


sub measure {
  my ($callback, %args) = @_;

  ## Params

  die "measure needs code ref" unless ref $callback eq 'CODE';

  my $warm_ups = $args{warm_ups};
  $warm_ups = 2 if !defined $warm_ups;

  my $iterations = $args{iterations} || 1000;

  my $method = $args{method} || 'min';


  ## Vars

  my @vals = (0) x $iterations;


  ## Warm-up the callback

  for (my $i = 0; $i < $warm_ups; $i++) {
    measure_XS($callback);
  }


  ## Gather real data

  for (my $i = 0; $i < $iterations; $i++) {
    $vals[$i] = measure_XS($callback);
  }


  ## Output

  @vals = sort { $a <=> $b } @vals;

  if ($method eq 'min') {
    return $vals[0];
  } elsif ($method eq 'max') {
    return $vals[-1];
  } elsif ($method eq 'median') {
    return $vals[int($iterations / 2)];
  } elsif ($method eq 'mean') {
    my $total = 0;
    $total += $_ foreach (@vals);
    return $total / $iterations;
  } else {
    die "unknown method '$method'";
  }
}



1;



__END__


=head1 NAME

Timer::CPU - Precise user-space timer using the CPU clock

=head1 SYNOPSIS

    use Timer::CPU;

    my $elapsed_ticks = Timer::CPU::measure(sub {
      ## Do stuff
    });


=head1 DESCRIPTION

For most timer operations, L<Time::HiRes> is great. Since it provides microsecond resolution in real "wall-clock" time it is very useful for determining how long an operation actually takes in seconds.

However, on most CPUs it is possible to take much higher resolution measurements. These measurements aren't in absolute units like seconds but instead in "cycles" or "ticks". These measurements relate to wall-clock time via an unspecified conversion ratio and can therefore only be used for relative comparisons between code on the same machine (and are subject to other constraints described below).

The resolution of this module is extremely high. For example, it can detect the difference between a sub that returns nothing, one that returns a number, and one that returns an empty string. It can detect whether an C<if> branch is taken or not, and even the difference between C<eq> comparing strings that match and strings that differ by only the last character.


=head1 USAGE

This module provides one function: C<Timer::CPU::measure>. Its first argument should be a callback code-ref. This is the code to be benchmarked. It is always called in void context. The return value is a number that corresponds to how many CPU cycles were spent executing your callback.

The following other arguments can be passed in as keyword arguments: C<warm_ups>, C<iterations>, and C<method>. For example:

    say Timer::CPU::measure(sub { },
                            warm_ups => 10,
                            iterations => 50000,
                            method => 'median');

C<measure> will first invoke your provided callback C<warm_ups> times (default is 2) and throw away the timing results. It will then invoke your callback C<iterations> times (default is 1000), recording the number of ticks elapsed for each invocation. Finally, it will return a summary of the results according to the C<method> parameter which should be one of C<min>, C<max>, C<mean>, or C<median>. The default method is C<min>.



=head1 CAVEATS

There are many caveats to this timing technique, but there are caveats to all timing techniques.

It can be difficult to measure perl code by ticks elapsed because, compared to C, perl code typically does a lot "under the hood".

On x86 and x86-64, this module uses the C<rdtsc> ("ReaD Time-Stamp Counter") instruction. On SPARC it accesses the C<%tick> register which is a 64-bit counter incremented every cycle. Various other CPUs might work (see C<cycle.h>) although they haven't been tested. An architecture that is noticeably missing is ARM.

As mentioned above, the real "wall-clock" time duration of a tick isn't necessarily known. You may be able to figure out the clock frequency with L<Sys::Info::Device::CPU>, but (on x86/x86-64) you should first verify your CPU is modernish and has a constant time-stamp counter (look for "constant_tsc" in /proc/cpuinfo if you are on linux).

If your kernel context-switches out your process your timing data will be corrupted. While performing benchmarks you should consider running in single-user mode or, if you have multiple CPUs/cores, pegging your process to a particular CPU (with something like L<Sys::CpuAffinity>).

Many CPUs have the ability to dynamically scale their clock speed in order to save power. If the CPU your process is running on changes clock speed during your measurements your data will be corrupted. You should consider fixing your CPU to a constant clock speed while running benchmarks.

If the machine is hibernated or suspended, data will be corrupted also.

On some architectures, operating systems can disable access to the time-stamp counter (ie by setting a bit in the CR4 register on x86). This is uncommon but is sometimes done in virtualised environments to protect against harvesting information from timing side-channels.






=head1 SEE ALSO

L<Timer-CPU github repo|https://github.com/hoytech/Timer-CPU>

L<Time::HiRes>

L<Time-Stamp Counter|http://en.wikipedia.org/wiki/Time_Stamp_Counter>

L<String::Compare::ConstantTime>



=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

The tick collection routines are copied from the file C<cycle.h> in the FFTW 3 project. They are written by Matteo Frigo and contributors (see source code) and are distributed under the MIT license.


=head1 COPYRIGHT & LICENSE

Copyright 2013-2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut




https://setisvn.ssl.berkeley.edu/svn/lib/fftw-3.0.1/kernel/cycle.h
http://procbench.sourceforge.net/
http://google-perftools.googlecode.com/svn/trunk/src/base/cycleclock.h



TODO:

! investigate if this is possible on ARM
? integrate CPU pinning
? detect/workaround CPU scaling
? on x86/x86-64 use CPUID instruction to serialize the instruction pipelining
? HPET? http://blog.fpmurphy.com/2009/07/linux-hpet-support.html
