package Time::Mock;
$VERSION = v0.0.2;

use warnings;
use strict;
use Carp;

=head1 NAME

Time::Mock - shift and scale time

=head1 SYNOPSIS

Speed up your sleep(), alarm(), and time() calls.

  use Time::Mock throttle => 100;
  use Your::Code;

=head1 ABOUT

Test::MockTime is nice, but doesn't allow you to accelerate the timestep
and doesn't deal with Time::HiRes or give you any way to change the time
across forks.

TODO: replace Time::HiRes functions with wrappers

TODO: finish the interfaces to real time/sleep/alarm

=head1 Replaces

These core functions are replaced.

Eventually, much of the same bits from Time::HiRes will be
correspondingly overwritten.

=over

=item time

=item localtime

=item gmtime

=item sleep

Sleeps for 1/$throttle.

=item alarm

Alarm happens in 1/$throttle.

=back

=cut

# TODO issue:  anybody that said 'use Time::HiRes' before we arrived got
# imports of the original versions.  Complain very loudly?

use Time::HiRes ();
BEGIN {
  package Time::Mock::Original;
  *time = \&Time::HiRes::time;
  *sleep = \&Time::HiRes::sleep;
  *alarm = \&Time::HiRes::alarm;
}

sub time ();
sub localtime (;$);
sub gmtime (;$);
sub sleep  (;$);
sub alarm  (;$);
BEGIN {
  *CORE::GLOBAL::time      = \&time;
  *CORE::GLOBAL::localtime = \&localtime;
  *CORE::GLOBAL::gmtime    = \&gmtime;
  *CORE::GLOBAL::sleep     = \&sleep;
  *CORE::GLOBAL::alarm     = \&alarm;

  no warnings 'redefine';
  *Time::HiRes::time = sub () {goto &_hitime};
  *Time::HiRes::sleep = sub (;@) {goto &sleep};
  *Time::HiRes::alarm = sub ($;$) {goto &alarm};
}

sub import {
  my $class = shift;
  (@_ % 2) and croak("odd number of elements in argument list");
  my (%args) = @_;
  foreach my $k (keys(%args)) {
    $class->can($k) or croak("unknown method '$k'");
    $class->$k($args{$k});
  }
}

=head1 Class Methods

These are the knobs on your time machine, but note that it is probably
best to adjust them only once: see L<caveats>.  For convenience,
import() takes will call these methods with each key in its argument
list.

  perl -MTime::Mock=throttle,600,set,"2009-11-01 00:59" dst_bug.pl

=head2 throttle

Get or set the throttle.

  Time::Mock->throttle(10_000);

=head2 offset

Get or set the offset.

  Time::Mock->offset(120);

=head2 set

Set the time to a given value.  This may be a numeric time or anything
parseable by Date::Parse::str2time() (you need to install Date::Parse to
enable this.)

  Time::Mock->set("2009-11-01 00:59");

=head1 Caveats

This package remembers the actual system time when it was loaded and
makes adjustments from there.

Future versions might change this behavior if I can think of a good
reason and scheme for that.

=head2 forks and threads

The throttle value will hold across forks, but there is no support for
propagating changes to child processes.  So, set the knobs only before
you fork!

Don't ask about threads unless you're asking about me applying your
patch thanks.

=head2 Networking and System stuff

We're only lying about the clock inside of Perl, not magically messing
with the universe.

=head2 Time Travel is Dangerous

I suggest that you set the knobs at import() and don't mess with them
after that unless you're well aware of how your code is using time.

Messing with the throttle during runtime could also give your code the
illusion of time going backwards.  If your code tries to do math with
the return values of time() before and after a slow-down, there could be
trouble.

Changing the throttle while an alarm() is set won't change the original
alarm time.  There would be a similar caveat about sleep() if I hadn't already mentioned forks ;-)

Finally, don't ever let your past self see your future self.

=cut

our $accel = 1;
sub throttle {
  my $class = shift;
  return $accel unless(@_);

  my $v = shift(@_);
  $v or croak("cannot set throttle to zero");
  $accel = $v;
}

our $offset = 0;
sub offset {
  my $class = shift;
  return $offset unless(@_);
  $offset = shift(@_);
}

BEGIN { *_realtime = \&Time::Mock::Original::time};
our $otime = _realtime;

sub set {
  my $class = shift;
  my $set = shift(@_) or croak("must have time to set");
  unless($set =~ m/^\d+$/) {
    require Date::Parse;
    $set = Date::Parse::str2time($set);
  }
  $offset = $set - $otime;
}

sub _hitime () {
  return(($otime + $offset) + (_realtime - $otime) * $accel);
}

sub time () { 
  return sprintf("%0.0f", _hitime);
}

sub localtime (;$) {
	my ($time) = @_;

  $time = time unless(defined $time);
	return CORE::localtime($time);
}

sub gmtime (;$) {
	my ($time) = @_;

  $time = time unless(defined $time);
	return CORE::gmtime($time);;
}
sub sleep (;$) {
  my ($length) = @_;

  return CORE::sleep unless($length);
  return Time::Mock::Original::sleep($length / $accel);
}
sub alarm (;$) {
  my ($length) = @_;

  $length = $_ unless(defined($length));
  return CORE::alarm(0) unless($length);
  return Time::Mock::Original::alarm($length / $accel);
}




=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
