package Time::StasisField;

=head1 NAME

Time::StasisField - control the flow of time

=cut

use strict;
use warnings;

use POSIX (qw{SIGALRM});
use Scalar::Util (qw{set_prototype});

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

I<Time::StasisField> provides a simple interface for controlling the flow of
time.  When the stasis field is disengaged, Perl's core time functions --
alarm, gmtime, localtime, sleep, and time -- behave normally, assuming that
time flows with the system clock.  When the stasis field is engaged, time
is guaranteed to advance at a predictable rate on every call.  For consistency,
all other time-related functions will use the modified time.

Example usage:

	use Time::StasisField;

	my @foos;

	@foos = map { Foo->new(create_time => time) } (1 .. 20);

	# All times will likely all look the same
	print $foos[-1]->create_time - $foos[0]->create_time;

	# The program will pause for 10 seconds
	sleep(10);

	# Time will be 10 seconds later
	print time;

	#Let's control time
	Time::StasisField->engage;

	@foos = map { Foo->new(create_time => time) } (1 .. 20);

	# All times will be distinct
	print $foos[-1]->create_time - $foos[0]->create_time;

	# Time will advance by 10 seconds
	sleep(10);

	# Fetch the current time without advancing it
	print Time::StasisField->now;


	Time::StasisField->seconds_per_tick(60);

	# Time is now 1 minute later
	print time;

	# Everything is back to normal
	Time::StasisField->disengage;

	# Hooray for system time
	print Time::StasisField->now;

=cut

############################
# Private Class Variables
############################

my $alarm_time;
my $current_time = 0;
my $is_alarm_set = 0;
my $is_engaged = 0;
my $is_frozen = 0;
my $seconds_per_tick = 1;

############################
# Helper Functions
############################

sub _validate_number {
	my $class = shift;

	#Make sure the value is numeric
	use warnings (FATAL => 'all');
	no warnings ("void");
	int($_[0]);
}

sub _trigger_alarm {
	my $class = shift;

	return
	  if ! $is_alarm_set
	  || $class->now < $alarm_time;

	CORE::alarm(0);
	$is_alarm_set = 0;
	kill SIGALRM, $$;
}

=head1 STASIS FIELD METHODS

=cut

=head2 engage

Enable the stasis field, seizing control of the system time and setting now to
the time the field was enabled. If engage is called while the field is already
enabled, now is updated to the current system time.

=cut

sub engage {
	my $class = shift;

	if ($class->is_engaged) {
		#Update now to real time
		$current_time = CORE::time;
		#Trigger the alarm that may have occurred during the transition
		$class->_trigger_alarm;

	} else {
		#Turn off the alarm so that we don't accidentally throw while switching state
		my $old_alarm = $class->alarm(0);

		$is_engaged = 1;
		$current_time = CORE::time;

		#Turn the alarm back on
		$class->alarm($old_alarm || 0);
	}

	return;
}

=head2 disenage

Disable the stasis field, returning control to the system time.

=cut

sub disengage {
	my $class = shift;

	return unless $class->is_engaged;

	$current_time = CORE::time;
	$is_engaged = 0;

	#Start the system alarm from now
	$class->alarm($alarm_time - $current_time) if $is_alarm_set;
	#Trigger the alarm that may have occurred during the transition
	$class->_trigger_alarm;

	return;
}

=head2 is_engaged

Return whether or not the stasis field is enabled.

=cut

sub is_engaged   { $is_engaged }

=head2 freeze

Time should stop advancing now.

=cut

sub freeze   { $is_frozen = 1 }

=head2 unfreeze

Time should continue advancing now.

=cut

sub unfreeze { $is_frozen = 0 }

=head2 is_frozen

Return whether or not time advances now.

=cut

sub is_frozen    { $is_frozen }

=head1 TIME METHODS

=cut

=head2 now

Accessor for the current time.  The supplied time may be any valid number,
though now will always return an integer.  Falls back to the system time when
the stasis field is disengaged.

=cut

sub now {
	my $class = shift;

	return CORE::time unless $class->is_engaged;

	if (@_) {
		$class->_validate_number($_[0]);
		$current_time = $_[0];
		$class->_trigger_alarm;
	}

	return int($current_time);
}

=head2 seconds_per_tick

Accessor for the number of seconds time changes with each tick.  Supports
negative and subsecond deltas. Only works on time in an engaged stasis field.

=cut

sub seconds_per_tick {
	my $class = shift;

	if (@_) {
		$class->_validate_number($_[0]);
		$seconds_per_tick = $_[0];
	}

	return $seconds_per_tick;
}

=head2 tick

Advance time by the value of seconds_per_tick, regardless of the freeze state.
Returns now.

=cut

sub tick {
	my $class = shift;

	return CORE::time unless $class->is_engaged;

	$current_time += $class->seconds_per_tick;
	$class->_trigger_alarm;

	return $class->now;
}

############################
# Core Overrides
############################

BEGIN {
	for my $function (qw{
		alarm
		gmtime
		localtime
		sleep
		time
	}) {
		no strict 'refs';
		*{"CORE::GLOBAL::$function"} = set_prototype(
			sub { unshift @_, 'Time::StasisField'; goto &{"Time::StasisField::$function"} },
			prototype("CORE::$function")
		);
	}
}

sub alarm {
	my $class = shift;
	my $offset = @_ ? $_[0] : $_;

	$class->_validate_number($offset);

	return CORE::alarm($offset) unless $class->is_engaged;

	my $previous_alarm_time_remaining =
		! defined $alarm_time ? $alarm_time :
		$is_alarm_set ? $alarm_time - $class->now : 0;
	$alarm_time = $offset > -1 ? $class->now + int($offset) : undef;
	$is_alarm_set = $offset >= 1;

	return $previous_alarm_time_remaining;
}

sub gmtime {
	my $class = shift;

	$class->_validate_number($_[0]) if @_;
	use warnings (FATAL => 'all');
	CORE::gmtime(@_ ? $_[0] : time);
}

sub localtime {
	my $class = shift;

	$class->_validate_number($_[0]) if @_;
	use warnings (FATAL => 'all');
	CORE::localtime(@_ ? $_[0] : time);
}

sub sleep {
	my $class = shift;

	return CORE::sleep unless @_;
	$class->_validate_number($_[0]);
	return CORE::sleep if $_[0] <= -1;
	return $class->is_engaged ? do { $class->now($class->now + $_[0]); int($_[0]) } : CORE::sleep($_[0]);
}

sub time {
	my $class = shift;

	return $class->is_frozen ? $class->now : $class->tick;
}

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-stasisfield at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-time-stasisfield/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Time::StasisField

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-time-stasisfield>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-time-stasisfield/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Time-StasisField>

=item * Official CPAN Page

L<http://search.cpan.org/dist/Time-StasisField/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Time::StasisField
