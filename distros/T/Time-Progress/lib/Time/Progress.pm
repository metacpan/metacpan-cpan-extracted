##############################################################################
#
#  Time::Progress
#  2013-2023 (c) Vladi Belperchinov-Shabanski "Cade" <cade@bis.bg>
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Time::Progress;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '2.14';

our $SMOOTHING_DELTA_DEFAULT = '0.1';
our %ATTRS =  (
              min             => 1,
              max             => 1,
              format          => 1,
              smoothing       => 1,
              smoothing_delta => 1,
              );

sub new
{
  my $class = shift;
  my $self = { min => 0, max => 100, smoothing => 0, smoothing_delta => $SMOOTHING_DELTA_DEFAULT };
  bless $self;
  $self->attr( @_ );
  $self->restart();
  return $self;
}

sub attr
{
  my $self = shift;
  croak "bad number of attribute/value pairs" unless @_ == 0 or @_ % 2 == 0;
  my @ret;
  my %h = @_;
  for( keys %h )
    {
    croak "invalid attribute name: $_" unless $ATTRS{ $_ };
    $self->{ $_ } = $h{ $_ } if defined $h{ $_ };
    push @ret, $self->{ $_ };
    }
  return @ret;
}

sub restart
{
  my $self = shift;
  my @ret = $self->attr( @_ );
  $self->{ 'start' } = time();
  $self->{ 'stop'  } = undef;
  $self->{ 'min_speed' } = 'n';
  $self->{ 'max_speed' } = 'a';
  return @ret;
}

sub stop
{
  my $self = shift;
  $self->{ 'stop'  } = time();
}

sub continue
{
  my $self = shift;
  $self->{ 'stop'  } = undef;
}

sub report
{
  my $self = shift;
  my $format = shift || $self->{ 'format' };
  my $cur = shift;

  my $start = $self->{ 'start' };

  my $now = $self->{ 'stop' } || time();

  croak "use restart() first" unless $start > 0;
  croak "time glitch (running backwards?)" if $now < $start;
  croak "empty format, use format() first" unless $format;

  my $l = $now - $start;
  my $L = sprintf "%3d:%02d", int( $l / 60 ), ( $l % 60 );

  my $min    = $self->{ 'min' };
  my $max    = $self->{ 'max' };
  my $last_e = $self->{ 'last_e' };
  my $sdelta = $self->{ 'smoothing_delta' };
  
  $cur = $min unless defined $cur;
  $sdelta = $SMOOTHING_DELTA_DEFAULT unless $sdelta > 0 and $sdelta < 1;

  my $b  = 'n/a';
  my $bl = 79;

  if ( $format =~ /%(\d*)[bB]/ )
    {
    $bl = $1;
    $bl = 79 if $bl eq '' or $bl < 1;
    }

  my $e  = "n/a";
  my $E  = "n/a";
  my $f  = "n/a";
  my $p  = 0;
  my $ps = "n/a";
  my $s  = "n/a";

  if ( (($min <= $cur and $cur <= $max) or ($min >= $cur and $cur >= $max)) )
    {
    if ( $cur - $min == 0 )
      {
      $e = 0;
      }
    else
      {
      $e = $l * ( $max - $min ) / ( $cur - $min );
      $e = int( $e - $l );
      if ( $self->{ 'smoothing' } && $last_e && $last_e < $e && ( ( $e - $last_e ) / $last_e ) < $sdelta )
        {
        $e = $last_e;
        }
      $e = 0 if $e < 0;
      $self->{last_e} = $e if $self->{ 'smoothing' };
      }
    $E = sprintf "%3d:%02d", int( $e / 60 ), ( $e % 60 );

    $f = $now + $e;
    $f = localtime( $f );

    if ( $max - $min != 0 )
      {
      $p = 100 * ( $cur - $min ) / ( $max - $min );
      $b = '#' x int( $bl * $p / 100 ) . '.' x $bl;
      $b = substr $b, 0, $bl;
      $ps = sprintf "%5.1f%%", $p;
      }
    $s = int( ( $cur - $min ) / ( time() - $self->{ 'start' } ) ) if time() - $self->{ 'start' } > 0;
    $self->{ 'min_speed' } = $s if $p > 1 and $s > 0 and ( $self->{ 'min_speed' } eq 'n' or $self->{ 'min_speed' } > $s );
    $self->{ 'max_speed' } = $s if $p > 1 and $s > 0 and ( $self->{ 'max_speed' } eq 'a' or $self->{ 'max_speed' } < $s );
    }

  $format =~ s/%(\d*)l/$self->sp_format( $l, $1 )/ge;
  $format =~ s/%(\d*)L/$self->sp_format( $L, $1 )/ge;
  $format =~ s/%(\d*)e/$self->sp_format( $e, $1 )/ge;
  $format =~ s/%(\d*)E/$self->sp_format( $E, $1 )/ge;
  $format =~ s/%p/$ps/g;
  $format =~ s/%f/$f/g;
  $format =~ s/%\d*[bB]/$b/g;
  $format =~ s/%s/$s/g;
  $format =~ s/%S/$self->{ 'min_speed' } . "\/" . $self->{ 'max_speed' }/ge;

  return $format;
}

sub sp_format
{
  my $self = shift;

  my $val  = shift;
  my $len  = shift;

  return $val unless $len ne '' and $len > 0;
  return sprintf( "%${len}s", $val );
}

sub elapsed
{ my $self = shift; return $self->report("%l",@_); }

sub elapsed_str
{ my $self = shift; return $self->report("elapsed time is %L min.\n",@_); }

sub estimate
{ my $self = shift; return $self->report("%e",@_); }

sub estimate_str
{ my $self = shift; return $self->report("remaining time is %E min.\n",@_); }

1;

=pod

=head1 NAME

Time::Progress - Elapsed and estimated finish time reporting.

=head1 SYNOPSIS

  use Time::Progress;

  my ($min, $max) = (0, 4);
  my $p = Time::Progress->new(min => $min, max => $max);

  for (my $c = $min; $c <= $max; $c++) {
    print STDERR $p->report("\r%20b  ETA: %E", $c);
    # do some work
  }
  print STDERR "\n";

=head1 DESCRIPTION

This module displays progress information for long-running processes.
This can be percentage complete, time elapsed, estimated time remaining,
an ASCII progress bar, or any combination of those.

It is useful for code where you perform a number of steps,
or iterations of a loop,
where the number of iterations is known before you start the loop.

The typical usage of this module is:

=over 4

=item *
Create an instance of C<Time::Progress>, specifying min and max count values.

=item *
At the head of the loop, you call the C<report()> method with
a format specifier and the iteration count,
and get back a string that should be displayed.

=back

If you include a carriage return character (\r) in the format string,
then the message will be over-written at each step.
Putting \r at the start of the format string,
as in the SYNOPSIS,
results in the cursor sitting at the end of the message.

If you display to STDOUT, then remember to enable auto-flushing:

 use IO::Handle;
 STDOUT->autoflush(1);

The shortest time interval that can be measured is 1 second.

=head1 METHODS

=head2 new

  my $p = Time::Progress->new(%options);

Returns new object of Time::Progress class and starts the timer.
It also sets min and max values to 0 and 100,
so the next B<report> calls will default to percents range.

You can configure the instance with the following parameters:

=over 4

=item min

Sets the B<min> attribute, as described in the C<attr> section below.

=item max

Sets the B<max> attribute, as described in the C<attr> section below.

=item smoothing

If set to a true value, then the estimated time remaining is smoothed
in a simplistic way: if the time remaining ever goes up, by less than
10% of the previous estimate, then we just stick with the previous
estimate. This prevents flickering estimates.
By default this feature is turned off.

=item smoothing_delta

Sets smoothing delta parameter. Default value is 0.1 (i.e. 10%).
See 'smoothing' parameter for more details. 

=back

=head2 restart

Restarts the timer and clears the stop mark.
Optionally restart() may act also
as attr() for setting attributes:

  $p->restart( min => 1, max => 5 );

is the same as:

  $p->attr( min => 1, max => 5 );
  $p->restart();

If you need to count things, you can set just 'max' attribute since 'min' is
already set to 0 when object is constructed by new():

  $p->restart( max => 42 );

=head2 stop

Sets the stop mark. This is only useful if you do some work, then finish,
then do some work that shouldn't be timed and finally report. Something
like:

  $p->restart;
  # do some work here...
  $p->stop;
  # do some post-work here
  print $p->report;
  # `post-work' will not be timed

Stop is useless if you want to report time as soon as work is finished like:

  $p->restart;
  # do some work here...
  print $p->report;

=head2 continue

Clears the stop mark. (mostly useless, perhaps you need to B<restart>?)

=head2 attr

Sets and returns internal values for attributes. Available attributes are:

=over 4

=item min

This is the min value of the items that will follow (used to calculate
estimated finish time)

=item max

This is the max value of all items in the even (also used to calculate
estimated finish time)

=item format

This is the default B<report> format. It is used if B<report> is called
without parameters.

=back

B<attr> returns array of the set attributes:

  my ( $new_min, $new_max ) = $p->attr( min => 1, max => 5 );

If you want just to get values use undef:

  my $old_format = $p->attr( format => undef );

This way of handling attributes is a bit heavy but saves a lot
of attribute handling functions. B<attr> will complain if you pass odd number
of parameters.

=head2 report

This is the most complex method in this package :)

The expected arguments are:

  $p->report( format, [current_item] );

I<format> is string that will be used for the result string. Recognized
special sequences are:

=over 4

=item %l

elapsed seconds

=item %L

elapsed time in minutes in format MM:SS

=item %e

remaining seconds

=item %E

remaining time in minutes in format MM:SS

=item %p

percentage done in format PPP.P%

=item %f

estimated finish time in format returned by B<localtime()>

=item %b

=item %B

progress bar which looks like:

  ##############......................

%b takes optional width:

  %40b -- 40-chars wide bar
  %9b  --  9-chars wide bar
  %b   -- 79-chars wide bar (default)

=item %s

current speed in items per second

=item %S

current min/max speeds (calculated after first 1% of the progress)

=back

Parameters can be omitted and then default format set with B<attr> will
be used.

Sequences 'L', 'l', 'E' and 'e' can have width also:

  %10e
  %5l
  ...

Estimate time calculations can be used only if min and max values are set
(see B<attr> method) and current item is passed to B<report>! if you want
to use the default format but still have estimates use it like this:

  $p->format( undef, 45 );

If you don't give current item (step) or didn't set proper min/max value
then all estimate sequences will have value `n/a'.

You can freely mix reports during the same event.


=head2 elapsed($item)

Returns the time elapsed, in seconds.
This help function, and those described below,
take one argument: the current item number.


=head2 estimate($item)

Returns an estimate of the time remaining, in seconds.


=head2 elapsed_str($item)

Returns elapsed time as a formatted string:

  "elapsed time is MM:SS min.\n"

=head2 estimate_str($item)

Returns estimated remaining time, as a formatted string:

  "remaining time is MM:SS min.\n"



=head1 FORMAT EXAMPLES

 # $c is current element (step) reached
 # for the examples: min = 0, max = 100, $c = 33.3

 print $p->report( "done %p elapsed: %L (%l sec), ETA %E (%e sec)\n", $c );
 # prints:
 # done  33.3% elapsed time   0:05 (5 sec), ETA   0:07 (7 sec)

 print $p->report( "%45b %p\r", $c );
 # prints:
 # ###############..............................  33.3%

 print $p->report( "done %p ETA %f\n", $c );
 # prints:
 # done  33.3% ETA Sun Oct 21 16:50:57 2001

 print $p->report( "%30b %p %s/sec (%S) %L ETA: %E" );
 # ..............................   0.7% 924/sec (938/951)   1:13 ETA: 173:35

=head1 SEE ALSO

The first thing you need to know about L<Smart::Comments> is that
it was written by Damian Conway, so you should expect to be a little
bit freaked out by it. It looks for certain format comments in your
code, and uses them to display progress messages. Includes support
for progress meters.

L<Progress::Any> separates the calculation of stats from the display
of those stats, so you can have different back-ends which display
progress is different ways. There are a number of separate back-ends
on CPAN.

L<Term::ProgressBar> displays a progress meter to a standard terminal.

L<Term::ProgressBar::Quiet> uses C<Term::ProgressBar> if your code
is running in a terminal. If not running interactively, then no progress bar
is shown.

L<Term::ProgressBar::Simple> provides a simple interface where you
get a C<$progress> object that you can just increment in a long-running loop.
It builds on C<Term::ProgressBar::Quiet>, so displays nothing
when not running interactively.

L<Term::Activity> displays a progress meter with timing information,
and two different skins.

L<Text::ProgressBar> is another customisable progress meter,
which comes with a number of 'widgets' for display progress
information in different ways.

L<ProgressBar::Stack> handles the case where a long-running process
has a number of sub-processes, and you want to record progress
of those too.

L<String::ProgressBar> provides a simple progress bar,
which shows progress using a bar of ASCII characters,
and the percentage complete.

L<Term::Spinner> is simpler than most of the other modules listed here,
as it just displays a 'spinner' to the terminal. This is useful if you
just want to show that something is happening, but can't predict how many
more operations will be required.

L<Term::Pulse> shows a pulsed progress bar in your terminal,
using a child process to pulse the progress bar until your job is complete.

L<Term::YAP> a fork of C<Term::Pulse>.

L<Term::StatusBar> is another progress bar module, but it hasn't
seen a release in the last 12 years.

=head1 GITHUB REPOSITORY


  https://github.com/cade-vs/perl-time-progress
  
  git clone https://github.com/cade-vs/perl-time-progress


=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@bis.bg> <cade@cpan.org>

  http://cade.datamax.bg

=head1 COPYRIGHT AND LICENSE

This software is (c) 2001-2019 by Vladi Belperchinov-Shabanski E<lt>cade@bis.bgE<gt> E<lt>cade@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

