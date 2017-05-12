
package Time::SoFar;

use integer;
use vars qw($VERSION);
$VERSION="1.00";
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw( runtime runinterval figuretimes );

my $lasttime;
my $day;
my $hour;
my $min;
my $sec;

sub figuretimes($;$) {
  my $rtime = shift;
  my $noopt = shift;
  my @times;

  $min   = $rtime / 60;        # requires 'use integer'
  $sec   = $rtime % 60;
  $hour  = $min   / 60;        # requires 'use integer'
  $min   = $min   % 60;
  $day   = $hour  / 24;        # requires 'use integer'
  $hour  = $hour  % 24;

  if ($day or $noopt) {
    @times = ($day, $hour, $min, $sec);
  } elsif ($hour) {
    @times = ($hour, $min, $sec);
  } else {
    @times = ($min, $sec);
  }

  if (wantarray) {
    return @times;
  } else {
    my $return = join(':', @times);
    $return =~ s/:(\d)\b/:0$1/g;
    return $return;
  }
} # end &figuretimes

sub runtime(;$) {
  my $noopt = shift;
  $lasttime = (time() - $^T);

  return &figuretimes($lasttime, $noopt);
} # end &runtime

sub runinterval(;$) {
  my $noopt = shift;
  if (!defined($lasttime)) {
    $lasttime = 0;
  }
  my $rtime    = (time() - $^T);
  my $interval = $rtime - $lasttime;
  $lasttime = $rtime;
  
  return &figuretimes($interval, $noopt);
} # end &runinterval

1;

__END__

=head1 NAME

Time::SoFar - Perl module to calculate run time

=head1 SYNOPSIS

    use Time::SoFar qw( runtime runinterval figuretimes );

    # [...] denotes optional arguments
    $times = runtime( [$no_optimize] );
    @times = runtime( [$no_optimize] );

    $times = runinterval( [$no_optimize] );
    @times = runinterval( [$no_optimize] );

    $times = figuretimes( $seconds [, $no_optimize] );
    @times = figuretimes( $seconds [, $no_optimize] );

=head1 SAMPLES

    my $elapsed = runtime();
    print "Elapsed time $elapsed\n";
    # prints, eg, "Elapsed time 17:34\n"

    my $sincethen = runinterval(1);
    print "Time since then $sincethen\n";
    # prints, eg, "Time since then 0:00:00:51\n"

    ($day, $hour, $min, $sec) = figuretimes(86400 + 2*3600 + 3*60 + 4, 1);
    # $day = 1; $hour = 2; $min = 3; $sec = 4;
    
    @times = figuretimes(2*3600 + 3*60 + 4);
    # @times = (2, 3, 4)
    
    @times = figuretimes(17,1);
    # @times = (0, 0, 0, 17)
    
    $times = figuretimes(2*3600 + 3*60 + 4, 1);
    # $times = '0:02:03:04';

=head1 DESCRIPTION

B<Time::SoFar> has two functions for calculating how long a script has
been running. C<runtime()> always works from the time the script
was started (using I<$^T>). C<runinterval()> works from the last time
C<runtime()> or C<runinterval()> was called (or since the start of
the script). 

Both C<runtime()> and C<runinterval()> use C<figuretimes()> to 
render a raw number of seconds into component time units. Both
take an optional boolean argument that gets passed to
C<figuretimes()> to influence its output.

In an array context C<figuretimes()> returns the timecomponents as
an array, in a scalar context it returns those components as a B<:>
delimited string. The default behaviour is to optimize away 0 output
from the longer period end of the output, leaving a minimum of 
minutes:seconds. This is good for arrays that will be passed to 
C<join()>, but not so good for a list of variables, so this behaviour
can be disabled by using a true value for I<$no_optimize>.

=head1 INHERITANCE

Time::SoFar inherits only from Exporter.

=head1 CAVEATS

Time::SoFar has a granularity of seconds, and is therefore not so
useful for small elapsed times.

=head1 PREREQUISITES

Only stock perl modules are used.

=head1 OSNAMES

So long as I<$^T> and C<time()> are calculated using the same epoch
there should be no operating system dependence.

=head1 SEE ALSO

I<$^T> in L<perlvar>.

=head1 COPYRIGHT

Copyright 2000 by Eli the Bearded / Benjamin Elijah Griffin.
Released under the same license(s) as Perl.

=head1 AUTHOR

Eli the Bearded wrote this to do away with all the I<$^T> one liners
at the end of his batch processing scripts.

=cut
