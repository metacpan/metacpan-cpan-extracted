package Win32::PerfCounter;

use 5.005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(frequency counter ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Win32::PerfCounter', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Win32::PerfCounter - Use Windows' high performance counter

=head1 SYNOPSIS

  use Win32::PerfCounter qw(:all)
  # equivalent to 
  use Win32::PerfCounter qw(frequency counter)

  my $freq  = [ frequency() ]

  my $start = [ counter() ]
  do_sth();
  my $stop  = [ counter() ]

  use Time::HiRes qw(tv_interval);

  my $counter_per_second = tv_interval([0, 0], frequency());
  my $duration = tv_interval($start, $stop) / $counter_per_second;

  print "Something took $duration seconds to complete.\n";

=head1 ABSTRACT

Use Windows' high performance counter

=head1 DESCRIPTION

The Win32 API features a high performance counter that allows measuring extremely short time spans. Depending on your machine, the resolution should be around 1 microsecond (1 second = 1_000_000 microseconds). This module is an interface to the Win32 API functions QueryPerformanceCounter and QueryperformanceFrequency that implement this counter.

=item C<frequency>

Returns the resolution of the high performance counter in counter events per second, as an array of two integers (high and low part of an 64 bit integer). Returns undef if the high performance counter is not available on this machine. According to the Windows API specification, the return value of frequency is constant while the machine is running.

=item C<counter>

Returns the current value of the high performance counter, as an array of two integers (high and low part of an 64 bit integer). Returns undef if the high performance counter is not available on this machine. Note that the results need to be divided by the frequency first to be useful.

=head1 HINT

The return values used in this module are compatible with C<Time::HiRes::tv_interval>. Nice if you're lazy like me and don't want to do the calculations yourself. You can even convert C<frequency>'s return value into a floating point value as shown in the synopsis.

=head1 CAVEAT

Obviously, the XS call adds some overhead. If you want to get more exact results, you should measure the overhead of calling the C<counter()> function and subtract it from the results.

=head1 SEE ALSO

F<WinBase.h>, F<Windows.h>, L(Time::HiRes|Time::HiRes).

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Christian Renz E<lt>crenz @ web42.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut