package Time::Available;

use 5.001;
use strict;
use warnings;
use Carp;
use Time::Local;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	'days' => [ qw(
		DAY_MONDAY
		DAY_TUESDAY
		DAY_WEDNESDAY
		DAY_THURSDAY
		DAY_FRIDAY
		DAY_SATURDAY
		DAY_SUNDAY
		DAY_WEEKDAY
		DAY_WEEKEND
		DAY_EVERYDAY
	) ],
	'fmt_interval' => [ qw(fmt_interval) ]
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{'days'} },
	@{ $EXPORT_TAGS{'fmt_interval'} }
	);

our @EXPORT;	# don't export anything by default!

our $VERSION = '0.05';

# define some constants used later
use constant DAY_MONDAY    => 0x01;
use constant DAY_TUESDAY   => 0x02;
use constant DAY_WEDNESDAY => 0x04;
use constant DAY_THURSDAY  => 0x08;
use constant DAY_FRIDAY    => 0x10;
use constant DAY_SATURDAY  => 0x20;
use constant DAY_SUNDAY    => 0x40;
use constant DAY_WEEKDAY   => 0x1F;
use constant DAY_WEEKEND   => 0x60;
use constant DAY_EVERYDAY  => 0x7F;

use constant SEC_PER_DAY   => 86400;

my $debug = 0;

#
# make new instance
#
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	$self->{ARGS} = {@_};
	$debug = $self->{ARGS}->{DEBUG};

	croak("need start time") if (! defined($self->{ARGS}->{start}));

	# calc start and stop seconds
	my ($hh,$mm,$ss) = split(/:/,$self->{ARGS}->{start},3);
	print STDERR "new: start time ",$hh||0,":",$mm||0,":",$ss||0,"\n" if ($debug);
	croak("need at least hour specified for start time") if (! defined($hh));
	$mm |= 0;
	$ss |= 0;
	$self->{start_arr} = [$ss,$mm,$hh];

	my $start = $hh;
	$start *= 60;
	$start += $mm;
	$start *= 60;
	$start += $ss;

	croak("need end time") if (! defined($self->{ARGS}->{end}));

	($hh,$mm,$ss) = split(/:/,$self->{ARGS}->{end},3);
	print STDERR "new: end time ",$hh||0,":",$mm||0,":",$ss||0,"\n" if ($debug);
	croak("need at least hour specified for end time") if (! defined($hh));
	$mm |= 0;
	$ss |= 0;
	$self->{end_arr} = [$ss,$mm,$hh];

	my $end = $hh;
	$end *= 60;
	$end += $mm;
	$end *= 60;
	$end += $ss;

	croak("need dayMask specified") if (! defined($self->{ARGS}->{dayMask}));

	$self->{dayMask} = $self->{ARGS}->{dayMask};

	# over midnight?
	if ($start > $end) {
		$self->{sec_in_interval} = (86400 - $start + $end);
	} else {
		$self->{sec_in_interval} = ($end - $start);
	}
	$self ? return $self : return undef;
}

#
# this sub (originally from Time::Avail) will return if day is applicable
#

sub _dayOk($) {
	my $self = shift;
	my $day = shift || 0;

	my $dayMask = $self->{dayMask};

	my $dayOk = 0;

	if( ( $day == 0 ) && ( $dayMask & DAY_SUNDAY ) ) {
		$dayOk = 1;
	} elsif( ( $day == 1) && ( $dayMask & DAY_MONDAY ) ) {
		$dayOk = 1;
	} elsif( ($day == 2) && ( $dayMask & DAY_TUESDAY ) ) {
		$dayOk = 1;
	} elsif( ($day == 3)  && ( $dayMask & DAY_WEDNESDAY ) ) {
		$dayOk = 1;
	} elsif( ( $day == 4) && ( $dayMask & DAY_THURSDAY ) ) {
		$dayOk = 1;
	} elsif( ( $day == 5 ) && ( $dayMask & DAY_FRIDAY ) ) {
		$dayOk = 1;
	} elsif( ( $day == 6 ) && ( $dayMask & DAY_SATURDAY ) ) {
		$dayOk = 1;
	}

	print STDERR "day: $day dayMask: ",unpack("B32", pack("N", $dayMask))," ok: $dayOk\n" if ($debug);

	return $dayOk;
}

#
# calculate start and end of interval in given day
#

sub _start {
	my $self = shift;
	my $t = shift || croak "_start needs timestap";

	my @lt = localtime($t);
	$lt[0] = $self->{start_arr}[0];
	$lt[1] = $self->{start_arr}[1];
	$lt[2] = $self->{start_arr}[2];
	return timelocal(@lt);
}

sub _end {
	my $self = shift;
	my $t = shift || croak "_end needs timestap";

	my @lt = localtime($t);
	$lt[0] = $self->{end_arr}[0];
	$lt[1] = $self->{end_arr}[1];
	$lt[2] = $self->{end_arr}[2];
	return timelocal(@lt);
}

#
# this will return number of seconds that service is available if passed
# uptime of service
#

sub _t {
	my $t = shift || die "no t?";
	return "$t [" . localtime($t) . "]";
}

sub uptime {
	my $self = shift;

	my $time = shift || croak "need uptime timestamp to calculate uptime";

	# calculate offset -- that is number of seconds since midnight
	my @lt = localtime($time);

	# check if day falls into dayMask
	return 0 if (! $self->_dayOk($lt[6]) );

	my $s=0;

	my $start = $self->_start($time);
	my $end = $self->_end($time);

	print STDERR "uptime start: ",_t($start)," end: ",_t($end)," time: $time [$lt[2]:$lt[1]:$lt[0]]\n" if ($debug);

	if ( $end > $start ) {
		if ($time < $start) {
			$s = $end - $start;
		} elsif ($time < $end) {
			$s = $end - $time;
		}
	} elsif ( $start > $end ) {	# over midnight
		if ( $time < $end ) {
			if ( $time < $start) {
				$s = SEC_PER_DAY - $start + $end - $time;
			} else {
				$s = SEC_PER_DAY - $start + $end;
			}
		} else {
			if ( $time < $start ) {
				$s = SEC_PER_DAY - $start;
			} else {
				$s = SEC_PER_DAY - $time;
			}
		}
	}
		
	return $s;
}

#
# this will return number of seconds that service is available if passed
# downtime of service
#

sub downtime {
	my $self = shift;

	my $time = shift || croak "need downtime timestamp to calculate uptime";

	# calculate offset -- that is number of seconds since midnight
	my @lt = localtime($time);

	# check if day falls into dayMask
	return 0 if (! $self->_dayOk($lt[6]) );

	my $s=0;

	my $start = $self->_start($time);
	my $end = $self->_end($time);

	print STDERR "downtime start: ",_t($start)," end: ",_t($end)," time: $time [$lt[2]:$lt[1]:$lt[0]]\n" if ($debug);

	if ( $end > $start ) {
		if ($time > $start && $time <= $end) {
			$s = $end - $time;
		} elsif ($time < $start) {
			$s = 0;
		}
	} elsif ( $start > $end ) {	# over midnight
		if ( $time < $end ) {
			if ( $time < $start) {
				$s = $time;
			} else {
				$s = 0;
			}
		} else {
			if ( $time < $start ) {
				$s = SEC_PER_DAY - $end;
			} else {
				$s = SEC_PER_DAY - $end + $start - $time;
			}
		}
	}
		
	return $s;
}

#
# this auxillary function will pretty-format interval in [days]d hh:mm:ss
#

sub fmt_interval {
	my $int = shift || 0;
	my $out = "";

	my $s=$int;
	my $d = int($s/(24*60*60));
	$s = $s % (24*60*60);
	my $h = int($s/(60*60));
	$s = $s % (60*60);
	my $m = int($s/60);
	$s = $s % 60;
	
	$out .= $d."d " if ($d > 0);

	if ($debug) {
		$out .= sprintf("%02d:%02d:%02d [%d]",$h,$m,$s, $int);
	} else {
		$out .= sprintf("%02d:%02d:%02d",$h,$m,$s);
	}

	return $out;
}

#
# this function will calculate uptime for some interval
#

sub interval {
	my $self = shift;
	my $from = shift || croak "need start time for interval";
	my $to = shift || croak "need end time for interval";

	print STDERR "from:\t",_t($from),"\n" if ($debug);
	print STDERR "to:\t",_t($to),"\n" if ($debug);

	my $total = 0;

	# calc first day availability
	print STDERR "t:\t",_t($from),"\n" if ($debug);
	$total += $self->uptime($from);

	print STDERR "total: ",fmt_interval($total)," (first)\n" if ($debug);

	# add all whole days

	my $sec_in_day = $self->{sec_in_interval};
	my $day = 86400;	# 24*60*60

	my $loop_start_time = int(${from}/${day})*$day + $day;
	my $loop_end_time = int(${to}/${day})*$day;

	print STDERR "loop (start - end): $loop_start_time - $loop_end_time\n" if ($debug);

	for (my $t = $loop_start_time; $t < $loop_end_time; $t += $day) {
		print STDERR "t:\t",_($t),"\n" if ($debug);
		$total += $sec_in_day if ($self->day_in_interval($t));
		print STDERR "total: ",fmt_interval($total)," (loop)\n" if ($debug);
	}

	# add rest of last day
	print STDERR "t:\t",_t($to),"\n" if ($debug);

	if ($to > $self->_start($to)) {
		if ($to <= $self->_end($to)) {
			$total += ( $to - $self->_start($to) );
		} elsif($self->day_in_interval($to) && $loop_start_time < $loop_end_time) {
			$total += $sec_in_day;
		}
	} else {
		$total = abs($total - $self->downtime($to));
	}
	print STDERR "total: ",fmt_interval($total)," (final)\n" if ($debug);

	return $total;
}

#
# this function will check if day falls into interval
# 

sub day_in_interval {
	my $self = shift;

	my $time = shift || croak "need timestamp to check if day is in interval";

	my @lt = localtime($time);
	return $self->_dayOk($lt[6]);
}

#
# return seconds in defined interval
#


1;
__END__

=head1 NAME

Time::Available - Perl extension to calculate time availability

=head1 SYNOPSIS

  use Time::Available;

  # init interval and dayMask
  my $interval = new( start=>'07:00', stop=>'17:00',
  	dayMask=> Time::Available::DAY_WEEKDAY );

  # alternative way to init module using exporting of days
  use Time::Available qw(:days);
  my $interval = new( start=>'07:00', stop=>'17:00',
  	dayMask=> DAY_WEEKDAY );

  # calculate current uptime availability from now in seconds
  print $interval->uptime(localtime);

  # calculate maximum downtime in seconds from current moment
  print $interval->downtime(localtime);

  # calculate availablity in seconds from interval of uptime
  print $interval->interval($utime1,$utime2);

  # pretty print interval data (this will produce output '1d 11:11:11')
  use Time::Available qw(:fmt_interval);
  print fmt_interval(126671);

=head1 DESCRIPTION

Time::Available is used to calculate availability of some resource if start
and end time of availability is supplied. Availability is calculated
relative to some interval which is defined when new instance of module is
created.

Start and end dates must be specified in 24-hour format. You can specify
just hour, hour:minute or hour:minute:seconds format. Start and end time is
specified in your B<local time zone>. Timestamp, are specified in unix
utime, and module will take care of recalculating (using C<localtime> and
C<timelocal> when needed). There is one small canvat here: module is assuing
that time you are specifing is in same time zone in which your module is
running (that is from local system).

The B<dayMask> parameter is constructed by OR'ing together one or more of
the following dayMask constants:

=over 4

=item *
Time::Available::DAY_MONDAY

=item *
Time::Available::DAY_TUESDAY

=item *
Time::Available::DAY_WEDNESDAY

=item *
Time::Available::DAY_THURSDAY

=item *
Time::Available::DAY_FRIDAY

=item *
Time::Available::DAY_SATURDAY

=item *
Time::Available::DAY_SUNDAY

=item *
Time::Available::DAY_WEEKDAY

=item *
Time::Available::DAY_WEEKEND

=item *
Time::Available::DAY_EVERYDAY

=back

They should be self-explainatory.

=head2 EXPORT

None by default.

If you specify B<:days>, Time::Available will export all
DAY_* constraints to your enviroment (causing possible pollution of name
space). You have been warned.

With B<:fmt_interval> it will include function B<fmt_interval> which will
pretty-format interval into [days]d hh:mm:ss.


=head1 HISTORY

=over 8

=item 0.01

Original version; based somewhat on Time::Avail code

=item 0.02

First version which works well

=item 0.03

Fix intervals which start with 0 hours, and bug with sunday (it never
matched dayMask)

=item 0.04

Fixed bug when interval begins in previous day and end before start of
interval

=item 0.05

Fixed another bug when interval begins in non-masked day and ends after
begining of interval

=back

=head1 BUGS

=over 8

=item *
Allow arbitary (array?) of holidays to be included.

=back

=head1 SEE ALSO

L<Time::Avail> is CPAN module that started it all. However, it lacked
calculating of availability of some interval and precision in seconds, so
this module was born. It also had some bugs in dayMask which where reported
to author, but his e-mail address bounced.

More information about this module might be found on
http://www.rot13.org/~dpavlin/projects.html#cpan

=head1 AUTHOR

Dobrica Pavlinusic, E<lt>dpavlin@rot13.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006 by Dobrica Pavlinusic

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
