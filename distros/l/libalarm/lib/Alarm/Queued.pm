package Alarm::Queued;

$VERSION = 1.0;

use strict;

=head1 NAME

Alarm::Queued - Allow multiple, queued alarms.

=head1 DESCRIPTION

This module is an attempt to enhance Perl's built-in
alarm/C<$SIG{ALRM}> functionality.

The built-in function, and its associated signal handler,
allow you to arrange for your program to receive a SIGALRM
signal, which you can then catch and deal with appropriately.

Unfortunately, due to the nature of the design of these
signals (at the OS level), you can only have one alarm
and handler active at any given time.  That's where this
module comes in.

This module allows you to define multiple alarms, each
with an associated handler.  These alarms are queued, which
means that if you set one alarm and then set another alarm,
shorter than the first, the second alarm does not go off
until after the first one has gone off and been handled.
(If you'd like to have the alarms go off as their set time
expires, regardless of whether or not previous alarms are
still pending, see Alarm::Concurrent.)

To set an alarm, call the C<setalarm()> function with the
set time of the alarm and a reference to the subroutine
to be called when the alarm goes off.  You can then go on
with your program and the alarm will be called after the
set time has passed.

It is also possible to set an alarm that does not have a
handler associated with it using C<Alarm::Queued::alarm()>.
(This function can also be imported into your namespace,
in which case it will replace Perl's built-in alarm for
your package only.)

If an alarm that does not have a handler associated
with it goes off, the default handler, pointed to by
C<$Alarm::Queued::DEFAULT_HANLDER>, is called.  You can
change the default handler by assigning to this variable.

The default C<$Alarm::Queued::DEFAULT_HANDLER> simply
dies with the message "Alarm clock!\n".

=head1 IMPORT/EXPORT

No methods are exported by default but you can import
any of the functions in the L<FUNCTIONS|"FUNCTIONS"> section.

You can also import the special tag C<:ALL> which will
import all the functions in the L<FUNCTIONS|"FUNCTIONS"> section.

=head1 OVERRIDE

If you import the special tag C<:OVERRIDE>, this module
will override Perl's built-in alarm function for
B<every namespace> and it will take over Perl's magic
C<%SIG> variable, changing any attempts to read or write
C<$SIG{ALRM}> into calls to C<gethandler()> and
C<sethandler()>, respectively.

This can be useful when you are calling code that tries
to set its own alarm the "old fashioned way."  It can also,
however, be dangerous.  Overriding alarm is documented and
should be stable but taking over C<%SIG> is more risky (see
L<CAVEATS|"CAVEATS">).

Note that if you do I<not> override alarm and C<%SIG>, any
code you use that sets "legacy alarms" will disable all of
your queued alarms.  You can call C<Alarm::Queued::restore()>
to reinstall the Alarm::Queued handler.  This function may
not be imported.

=cut

use Alarm::_TieSIG; # In case they want to take over $SIG{ALRM}.
use Carp;

use Exporter;
use vars qw( @ISA @EXPORT_OK %EXPORT_TAGS );
@ISA = qw(Exporter);
@EXPORT_OK = qw(
  setalarm
  clearalarm
  alarm
  sethandler
  gethandler
);
%EXPORT_TAGS = (
  ALL => [@EXPORT_OK],
);

#
# Exporter doesn't allow hooks for handling
# special tags.  So, we have to do it ourselves.
#
sub import {
  my $thispkg = shift;

  # Look for and remove special :OVERRIDE tag.
  my $override = 0;
  @_ = grep { ($_ eq ':OVERLOAD') ? ($override = 1, 0) : 1 } @_;

  if($override) {
    $thispkg->export('CORE::GLOBAL', 'alarm');
    Alarm::_TieSIG::tiesig(); # ALL YOUR %SIG ARE BELONG TO US!!!
  };

  $thispkg->export_to_level(1, $thispkg, @_); # export the rest
}

# Called for an alarm with no defined handler.
sub _default_handler {
  die "Alarm clock!\n";
}

use vars '$DEFAULT_HANDLER';
$DEFAULT_HANDLER = \&_default_handler; # Overeridable.

#
# Each element of @ALARM_QUEUE should be a pointer
# to an array containing exactly three elements:
#
#  0) The duration of the alarm in seconds
#  1) The time at which the alarm was set
#  2) A pointer to a subroutine that should be called
#     when the alarm goes off.
#
use vars qw( @ALARM_QUEUE );
@ALARM_QUEUE = ();

restore(1);  # Install our alarm handler.

# Custom alarm handler.
sub _alrm {
  return unless(@ALARM_QUEUE);

  # Call handler for this alarm and remove it from the queue.
  my $handler = shift(@ALARM_QUEUE)->[2] || $DEFAULT_HANDLER;
  $handler->();

  while(@ALARM_QUEUE) {
    my $time_remaining = $ALARM_QUEUE[0][1]+$ALARM_QUEUE[0][0]-time;
    if($time_remaining <= 0) {
      $handler = shift(@ALARM_QUEUE)->[2] || $DEFAULT_HANDLER;
      $handler->(); # Call handler for this alarm.
    } else {
      CORE::alarm($time_remaining);
      last;
    }
  }
}


#********************************************************************#

=head1 FUNCTIONS

The following functions are available for use.

=over 4

=item setalarm SECONDS CODEREF

Sets a new alarm and associates a handler with it.
This handler is called when the specified number of
seconds have elapsed I<and> all previous alarms
have gone off.  See L<DESCRIPTION|"DESCRIPTION"> for
more information.

=cut
sub setalarm($$) {
  my ($alarm, $code) = @_;

  unless(not defined($code) or UNIVERSAL::isa($code, 'CODE')) {
    croak("Alarm handler must be CODEREF");
  }

  push( @ALARM_QUEUE, [ $alarm, time(), $code ] );
  CORE::alarm($alarm) if(@ALARM_QUEUE == 1);
}

=item clearalarm INDEX LENGTH

=item clearalarm INDEX

=item clearalarm

Clears one or more previously set alarms.  The index is
an array index, with 0 being the currently active alarm
and -1 being the last (most recent) alarm that was set.

INDEX defaults to 0 and LENGTH defaults to 1.

If you clear the active alarm and it was blocking other
alarms from going off, those alarms are immediately triggered.

=cut
sub clearalarm(;$$) {
  my $index  = shift || 0;
  my $length = shift || 1;

  splice @ALARM_QUEUE, $index, $length;

  unless($index) {
    while(@ALARM_QUEUE) {
      my $time_remaining = $ALARM_QUEUE[0][1]+$ALARM_QUEUE[0][0]-time;
      if($time_remaining <= 0) {
        my $handler = shift(@ALARM_QUEUE)->[2] || \&default_handler;
        $handler->(); # Call handler for this alarm.
      } else {
        CORE::alarm($time_remaining);
        last;
      }
    }
  }
}

=item alarm SECONDS

=item alarm

Creates a new alarm with no handler.  A handler can
later be set for it via sethandler() or C<$SIG{ALRM}>,
if overridden.

For the most part, this function behaves exactly like
Perl's built-in alarm function, except that it sets up a
concurrent alarm instead.  Thus, each call to alarm does
not disable previous alarms unless called with a set time
of 0.

Calling C<alarm()> with a set time of 0 will disable the
last alarm set.

If SECONDS is not specified, the value stored in C<$_>
is used.

=cut
sub alarm(;$) {
  my $alarm = @_ ? shift : $_;

  if($alarm == 0) {
    clearalarm(-1);
  } else {
    push( @ALARM_QUEUE, [ $alarm, time(), undef ] );
    CORE::alarm($alarm) if(@ALARM_QUEUE == 1);
  }
}

=item sethandler INDEX CODEREF

=item sethandler CODEREF

Sets a handler for the alarm found at INDEX in the queue.  This
is an array index, so negative values may be used to indicate
a position relative to the end of the queue.

If INDEX is not specified, the handler is set for the last
alarm in the queue that doesn't have one associated with it.
This means that if you set multiple alarms using C<alarm()>,
you should arrange their respective C<sethandler()>'s in the
I<opposite> order.

=cut
sub sethandler($;$) {

  unless(not defined($_[-1]) or UNIVERSAL::isa($_[-1], 'CODE')) {
    croak("Alarm handler must be CODEREF");
  }

  if(@_ == 2) {
    $ALARM_QUEUE[$_[0]]->[2] = $_[1];
  } else {
    foreach my $alarm (reverse @ALARM_QUEUE) {
      if(not defined $alarm->[2]) {
        $alarm->[2] = shift();
        last;
      }
    }
  }
}

=item gethandler INDEX

=item gethandler

Returns the handler for the alarm found at INDEX in the queue.
This is an array index, so negative values may be used.

If INDEX is not specified, returns the handler for the currently
active alarm.

=cut
sub gethandler(;$) {
  my $index = shift || 0;
  return(
    ($index < @ALARM_QUEUE and $index > -1)
      ?
    $ALARM_QUEUE[$index][2]
      :
    undef
  );
}

=item restore FLAG

=item restore

This function reinstalls the Alarm::Queued alarm handler
if it has been replaced by a "legacy alarm handler."

If FLAG is present and true, C<restore()> will save the
current handler by setting it as a new queued alarm (as
if you had called C<setalarm()> for it).

This function may not be imported.

Note:  Do B<not> call this function if you have imported
the C<:OVERLOAD> symbol.  It can have unpredictable results.

=cut
sub restore(;$) {
  return if(defined($SIG{ALRM}) and $SIG{ALRM} == \&_alrm);

  my $oldalrm = CORE::alarm(5);

  if($oldalrm and shift) {
    # Save legacy alarm.
    setalarm($oldalrm, $SIG{ALRM});
  }

  # Install our alarm handler.
  $SIG{ALRM} = \&_alrm;
}

=head1 CAVEATS

=over 4

=item *

C<%SIG> is Perl magic and should probably not be messed
with, though I have not witnessed any problems in the
(admittedly limited) testing I've done.  I would be
interested to hear from anyone who performs extensive
testing, with different versions of Perl, of the
reliability of doing this.

Moreover, since there is no way to just take over
C<$SIG{ALRM}>, the entire magic hash is usurped and any
other C<%SIG}> accesses are simply passed through to the
original magic hash.  This means that if there I<are> any
problems, they will most likely affect all other signal
handlers you have defined, including C<$SIG{__WARN__}>
and C<$SIG{__DIE__}> and others.

In other words, if you're going to use the :OVERRIDE
option, you do so at your own risk (and you'd better be
pretty damn sure of yourself, too).

=item *

The default C<$DEFAULT_HANDLER> simply dies with the
message "Alarm clock!\n".

=item *

All warnings about alarms possibly being off by up to a full
second still apply.  See the documentation for alarm for more
information.

=item *

The alarm handling routine does not make any allowances
for systems that clear the alarm handler before it is
called.  This may be changed in the future.

=item *

According to L<perlipc/"Signals">, doing just about I<anything>
in signal handling routines is dangerous because it might
be called during a non-re-entrant system library routines
which could cause a memory fault and core dump.

The Alarm::Queued alarm handling routine does quite a bit.

You have been warned.

=back

=head1 AUTHOR

Written by Cory Johns (c) 2001.

=cut

1;
