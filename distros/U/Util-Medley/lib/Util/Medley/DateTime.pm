package Util::Medley::DateTime;
$Util::Medley::DateTime::VERSION = '0.059';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Time::localtime;
use Time::Local;
use Kavorka '-all';
use Time::ParseDate;
use Time::HiRes;
use DateTime::Format::ISO8601;
use DateTime::Format::ISO8601::Format;

use constant SECS_PER_MIN => 60;
use constant SECS_PER_HOUR => SECS_PER_MIN() * 60;
use constant SECS_PER_DAY => SECS_PER_HOUR() * 24;

=head1 NAME

Util::Medley::DateTime - Class with various datetime methods.

=head1 VERSION

version 0.059

=cut

=head1 SYNOPSIS

  my $dt = Util::Medley::DateTime->new;

  #
  # positional  
  #
  say $dt->localDateTime(time);

  #
  # named pair
  #
  say $dt->localDateTime(epoch => time);
   
=cut

########################################################

=head1 DESCRIPTION

A small datetime library.  This doesn't do any calculations itself, but 
provides some simple methods to call for getting the date/time in commonly
used formats.

=cut

########################################################

=head1 ATTRIBUTES

none

=head1 METHODS

=head2 iso8601DateTime

Returns a iso8601-date-time string.

=over

=item usage:

 $dt->iso8601DateTime([$epoch]);

 $dt->iso8601DateTime([epoch => $epoch]);
 
=item args:

=over

=item epoch [Int]

Epoch time used to generate iso8601-date-time string.  Default is now.

=back

=back

=cut

multi method iso8601DateTime (Num :$epoch = time) {

	my $dt = DateTime->from_epoch(epoch => $epoch);
	my $format = DateTime::Format::ISO8601::Format->new;
	return $format->format_datetime($dt);
}

multi method iso8601DateTime (Num $epoch? = time) {

	return $self->iso8601DateTime(epoch => $epoch);
}

=head2 iso8601DateTimeToEpoch

Returns the epoch of a given iso8601-date-time string.

=over

=item usage:

 $dt->iso8601DateTimeToEpoch([$dateTime]);

 $dt->iso8601DateTime([dateTime => $dateTime]);
 
=item args:

=over

=item dateTime [Str]

An iso8601-date-time string.

=back

=back

=cut

multi method iso8601DateTimeToEpoch (Str :$dateTime!) {
	
    my $dt = DateTime::Format::ISO8601->parse_datetime($dateTime);
    return $dt->epoch;
}

multi method iso8601DateTimeToEpoch (Str $dateTime!) {

	return $self->iso8601DateTimeToEpoch(dateTime => $dateTime);
}

=head2 localDateTime

Returns the local-date-time in the format: YYYY-MM-DD HH:MM:SS.  

=over

=item usage:

 $dt->localDateTime([time]);

 $dt->localDateTime([epoch => time]);
 
=item args:

=over

=item time [Int]

Epoch time used to generate date/time string.  Default is now.

=back

=back
   
=cut

multi method localDateTime (Int :$epoch = time) {
	
	return $self->localDateTime($epoch);	
}

multi method localDateTime (Int $epoch = time) {

    my $l = localtime($epoch);

    my $str = sprintf(
        '%04d-%02d-%02d %02d:%02d:%02d',
        $l->year + 1900,
        $l->mon + 1,
        $l->mday, $l->hour, $l->min, $l->sec
    );

    return $str;
}


=head2 localDateTimeAdd

Adds days, hours, mins, and/or secs to a local-date-time string.

=over

=item usage:

 $newDateTime = $dt->localDateTimeAdd($dateTime, [0, 1, 0, 0]);

 $newDateTime = $dt->localDateTimeAdd( dateTime => $dateTime,
                                      [days     => 0],
                                      [hours    => 1],
                                      [mins     => 0],
                                      [secs     => 0]);
 
=item args:

=over

=item dateTime [Str]

A local-date-time string.

=item days [Int]

Days to add.

=item hours [Int]

Hours to add.

=item mins [Int]

Minutes to add.

=item secs [Int]

Seconds to add.

=back

=back
   
=cut

multi method localDateTimeAdd (Str :$dateTime!,
						  	   Int :$days  = 0,
						  	   Int :$hours = 0,
						  	   Int :$mins  = 0,
						  	   Int :$secs  = 0) {

	my $epoch = $self->localDateTimeToEpoch(dateTime => $dateTime);

	$epoch+= $days  * SECS_PER_DAY if $days;
	$epoch+= $hours * SECS_PER_HOUR if $hours;	
	$epoch+= $mins  * SECS_PER_MIN if $mins;
	$epoch+= $secs if $secs;
		 	
	return $self->localDateTime(epoch => $epoch);	
}

multi method localDateTimeAdd (Str $dateTime,
						 	   Int $days  = 0,
							   Int $hours = 0,
						  	   Int $mins  = 0,
						  	   Int $secs  = 0) {

	return $self->localDateTimeAdd(dateTime => $dateTime,
							  	   days     => $days, 
							  	   hours    => $hours,
							  	   mins     => $mins, 
							  	   secs     => $secs);
}


=head2 localDateTimeToEpoch

Converts a local-date-time string to epoch.

=over

=item usage:

 $epoch = $dt->localDateTimeToEpoch($dateTime);

 $epoch = $dt->localDateTimeToEpoch(dateTime => $dateTime);
 
=item args:

=over

=item dateTime [Str]

The local-date-time string to convert.

=back

=back
   
=cut

multi method localDateTimeToEpoch (Str :$dateTime!) {

	if (!$self->localDateTimeIsValid(dateTime => $dateTime)) {
		confess "invalid date-time format: $dateTime";			
	}

	my ($date, $time) = split(/\s+/, $dateTime);
	my ($year, $mon, $mday) = split(/-/, $date);
	my ($hour, $min, $sec) = split(/\:/, $time);
	
	my $epoch = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year );
		
	return $epoch;	
}

multi method localDateTimeToEpoch (Str $dateTime) {
	
	return $self->localDateTimeToEpoch(dateTime => $dateTime);
}

=head2 localDateTimeIsValid

Validates the date-time string against: YYYY-MM-DD HH:MM:SS.  Also,
checks if it is actually a valid date-time.

=over

=item usage:

 $dt->localDateTimeIsValid($dateTime);

 $dt->localDateTime(dateTime => $dateTime);
 
=item args:

=over

=item dateTime [Str]

The date-time string to validate.

=back

=back
   
=cut

multi method localDateTimeIsValid (Str :$dateTime!) {
	
	if ($dateTime =~ /^\d\d\d\d-\d\d\-\d\d \d\d\:\d\d\:\d\d$/) {
  		
  		my $epoch = parsedate($dateTime, VALIDATE=>1);
  		if ($epoch) {
  			return 1;
  		}
	}
	
	return 0;
}

multi method localDateTimeIsValid (Str $dateTime) {

	return $self->localDateTimeIsValid(dateTime	=> $dateTime);
}


=head2 timeMs

Returns the current epoch in milliseconds.

=over

=item usage:

  $ms = $dt->timeMs;
  
=back
   
=cut

method timeMs {
	
    return int(Time::HiRes::gettimeofday() * 1000);
}

1;
