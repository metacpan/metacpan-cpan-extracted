package Time::WorkHours;

=head1 NAME

Time::WorkHours - proportional shift DateTime to a work hours and few work hours routines

=head1 SYNOPSIS

    # our work hours is from 02:00 until 07:00
    my $wh = Time::WorkHours->new(
        work_interval_start => '02h',
        work_interval       => '5h',    # or 5*60
    );
    
    # shift given date to our work hours
    my $new_datetime = $wh->shift_to_work_time(DateTime->new(
        'hour'   => 14,
        'minute' => 32,
        # ... what ever month, year, day
    ));

=head1 DESCRIPTION

Purpouse of this module is to equaly distribute tasks that are comming
through the whole day into certain day interval.

Or just move comming request to the start of work hours.

For example imagine you want to process smoke tests only in the idle
server hours - in the night. But the CPAN modules are comming through
all day. You can note down the modules as they are comming and set
the processing time to C<< $wh->shift_to_work_time() >> so that
it will not take the processing time when the server has to do it's
"real" job.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use DateTime;
use Carp::Clan 'croak';

use base 'Class::Accessor::Fast';

=head1 PROPERTIES

    work_interval_start
    work_interval

=cut

__PACKAGE__->mk_accessors(qw{
    work_interval_start
    work_interval    
});


my $DAY_MINUTES = 24*60;


=head1 METHODS

=head2 new()

Object constructor. Pass two mandatory arguments. C<work_interval_start>
and C<work_interval>.

C<work_interval_start> is the minute (or hour) when the work hours
start.

C<work_interval> is how many minutes (or hours) does the work interval
last.

Both can be passed as a number in that case must represent minutes or as a string
with numbers and 'h' at the end representing the value in hours.

Example:

    $wh = Time::WorkHours->new(
        work_interval_start => '2h',  # or 120
        work_interval       => 180,   # or '3h'
    );

Work interval starts at 02:00 and lasts for 3 hours.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new({ @_ });
    
    croak 'pass work_interval_start'
        if not defined $self->work_interval_start;
    croak 'pass work_interval'
        if not defined $self->work_interval;
    
    return $self;
}


=head2 work_start($datetime)

Return nearest DateTime when the work time starts. If inside
the work interval then returns start datetime of this
interval.

If argument not passed the default is C<< DateTime->now >>.

=cut

sub work_start {
    my $self = shift;
    my $date = shift;
    
    # make a copy of passed DateTime
    if ($date) {
        $date = $date->clone();
    }
    else {
        $date = DateTime->now();
    }
    _strip_seconds($date);
    my $work_start = $date->clone;    

	my $work_interval_start  = $self->work_interval_start_minute;
	my $work_interval        = $self->work_interval_minutes;
	my $work_interval_end    = $work_interval_start + $work_interval;
    my $work_interval_shift += $DAY_MINUTES - $work_interval_end;

	$date->add('minutes' => $work_interval_shift);
    my $date_minutes = $date->hour*60 + $date->minute;
    
    $work_start->add('minutes' => $work_interval_start + $work_interval_shift - $date_minutes);
    
	return $work_start;
}


=head2 next_work_start($datetime)

Same as work_start but will always return DateTime in the
future.

=cut

sub next_work_start {
    my $self = shift;
    my $date = shift;
    
    my $work_start = $self->work_start($date);
    
    # shift by 24h if date is within work hours so the work_start is in the past
    $work_start->add('hours' => 24)
        if $work_start < $date;
    
    return $work_start;
}


=head2 work_end($datetime)

Returns nearest end of the work time.

If argument not passed the default is C<< DateTime->now >>.

=cut

sub work_end {
    my $self = shift;
    my $date = shift || DateTime->now;
    
    my $work_start    = $self->work_start($date);
    my $work_interval = $self->work_interval_minutes;

    return $work_start->add('minutes' => $work_interval);;
}


=head2 within($datetime)

Return true/false if the $datetime lies within work hours.

If argument not passed the default is C<< DateTime->now >>.

=cut

sub within {
    my $self = shift;
    my $date = shift || DateTime->now;
    
	my $work_start_datetime = $self->work_start($date);
	my $work_end_datetime   = $self->work_end($date);
	
	return 1
	    if (($date >= $work_start_datetime) and ($date < $work_end_datetime));
	return 0;
}


=head2 shift_to_work_time($date)

Takes the $date and moves it to the neares work time interval.
The shift is calculated proportionaly so that the time shifts are
distributed in the work hour interval in the same order as
they occure in 24h interval.

Example:

    my $wh = Time::WorkHours->new(
        work_interval_start => '22h',
        work_interval       => '4h',
    );
    my $new_datetime = $wh->shift_to_work_time(DateTime->new(
        'day'    => 5,
        'hour'   => 14,
        'minute' => 00,
        # ... what ever month, year
    ));

Will shift to next day to 00:00 as 14:00 is just in the middle of 02:00 - (22:00) - 02:00
interval so it's shifted to the middle of 22:00 - 02:00 work hours.

If the DateTime will be at 01:59 (last minute of the work interval) there will be no shift.

If the DateTime will be at 02:00 (first non work minute) the shift will be to 22:00.

If argument not passed the default is C<< DateTime->now >>.

=cut

sub shift_to_work_time {
    my $self = shift;
    my $date = shift || DateTime->now;
    
    croak 'pass DataTime object as argument'
        if ref $date ne 'DateTime';
    
    $date = $date->clone;
    
	my $work_interval_start = $self->work_interval_start_minute;
	my $work_interval       = $self->work_interval_minutes;
	my $work_start          = $self->work_start($date);
	my $work_interval_end   = $work_interval_start + $work_interval;
	my $work_interval_shift = $DAY_MINUTES - $work_interval_end;	

	$date->add('minutes' => $work_interval_shift);
    my $date_minutes = $date->hour*60 + $date->minute;
	
	my $event_date = $work_start->add('minutes' => ($date_minutes / $DAY_MINUTES) * $work_interval);
	
	return $event_date;
}


=head2 work_interval_start_minute()

Return number of minute in the day when the work interval starts.

=cut

sub work_interval_start_minute {
    my $self = shift;
    my $work_interval_start = $self->work_interval_start;
    
    if ($work_interval_start =~ m/\b([0-9]+)h$/) {
        return $1*60;
    }
    else {
        return $work_interval_start;
    }
}


=head2 work_interval_minutes()

Return for how many minutes does the work interval lasts.

=cut

sub work_interval_minutes {
    my $self = shift;
    my $work_interval = $self->work_interval;
    
    if ($work_interval =~ m/\b([0-9]+)h$/) {
        return $1*60;
    }
    else {
        return $work_interval;
    }
}

sub _strip_seconds {
    my $date = shift;
	$date->add('seconds' => -$date->second);
	return $date;
}


'ROMERQUELLE(R)';


__END__

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT & LICENSE

Copyright 2008 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
