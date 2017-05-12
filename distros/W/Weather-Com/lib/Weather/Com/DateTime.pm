package Weather::Com::DateTime;

use 5.006;
use strict;
no warnings;

#use warnings;
use Carp;
use Data::Dumper;
use Time::Format;
use Time::Local;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)/g;

our %months = (
	'Jan' => 0,
	'Feb' => 1,
	'Mar' => 2,
	'Apr' => 3,
	'May' => 4,
	'Jun' => 5,
	'Jul' => 6,
	'Aug' => 7,
	'Sep' => 8,
	'Oct' => 9,
	'Nov' => 10,
	'Dec' => 11
);

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};

	$self->{EPOC} = timelocal(gmtime(time()));
	if (@_) {
		$self->{ZONE} = shift;
	}
	else {
		$self->{ZONE} = 0;
	}

	bless( $self, $class );

	return $self;
}    # end new()

#------------------------------------------------------------------------
# very special setter methods
#------------------------------------------------------------------------
# this method assumes that time is irrelevant => no conversion needed
sub set_date {
	my $self       = shift;
	my $datestring = shift;
	my $month      = substr( $datestring, 0, 3 );
	my $day        = substr( $datestring, 3 );
	my @now        = gmtime();

	my $localmidnight = undef;
	eval { $localmidnight = timelocal( 0, 0, 0, $day, $months{$month}, $now[5] ); };
	if ($@) {
		croak($@);
	}

	my $gmtime = $localmidnight - ( $self->{ZONE} * 3600 );
	$self->{EPOC} = $gmtime;
	return $self->{EPOC};
}

# this method assumes that the date is irrelevant!
sub set_time {
	my $self       = shift;
	my $timestring = shift;
	my $colon      = index( $timestring, ":" );
	my $hour       = substr( $timestring, 0, $colon );
	my $minute     = substr( $timestring, $colon + 1, 2 );
	my $ampm       = substr( $timestring, $colon + 4 );
	$hour += 12 if ( lc($ampm) eq "pm" );

	my @now       = gmtime();
	my $localtime = undef;
	eval {
		$localtime = timelocal( 0, $minute, $hour, $now[3], $now[4], $now[5] );
	};
	if ($@) {
		croak($@);
	}
	if ($@) {
		croak($@);
	}

	my $gmtime = $localtime - ( $self->{ZONE} * 3600 );
	$self->{EPOC} = $gmtime;
	return $self->{EPOC};
}

sub set_lsup {
	my $self = shift;

	# this method returns epoc for gmt corresponding to
	# the provided last update value (lsup)
	my $lsup = shift;

	my ( $date, $time, $ampm, $zone ) = split( / /, $lsup );
	my ( $mon, $mday, $year ) = split( "/", $date );
	my ( $hour, $min ) = split( /:/, $time );

	$year += 100;
	$hour += 12 if ( $ampm eq "PM" );

	my $localtime;
	eval { $localtime = timelocal( 0, $min, $hour, $mday, $mon - 1, $year ); };
	if ($@) {
		croak($@);
	}

	my $gmtime = $localtime - ( $self->{ZONE} * 3600 );
	$self->{EPOC} = $gmtime;
	return $self->{EPOC};
}

#------------------------------------------------------------------------
# Access date and time
#------------------------------------------------------------------------
# epoc is alway GMT
sub epoc {
	my $self = shift;

	if (@_) {
		$self->{EPOC} = timelocal(gmtime(shift));
	}

	# we have to fake up $epoc
	# because of Time::Format behaviour, $epoc has to be in localtime
	# and to be able to provide a GMT conform epoc, we have to transform
	# this here
	return timegm(localtime($self->{EPOC}));
}

sub formatted {
	my $self      = shift;
	my $format    = shift;
	
	# Time::Format always returns localtime of the server the
	# script runs on. We have to eliminate this.
	my $localepoc = $self->{EPOC} + ( $self->{ZONE} * 3600 );
	return $time{ $format, $localepoc };    
}

#------------------------------------------------------------------------
# Access date
#------------------------------------------------------------------------
sub weekday {
	my $self = shift;
	return $self->formatted('Weekday');
}

sub date {
	my $self = shift;
	return $self->formatted('d. Month yyyy');
}

sub year {
	my $self = shift;
	return $self->formatted('yyyy');
}

sub month {
	my $self = shift;
	return $self->formatted('Month');
}

sub mon {
	my $self = shift;
	return $self->formatted('mm{on}');
}

sub day {
	my $self = shift;
	return $self->formatted('dd');
}

#------------------------------------------------------------------------
# Access time
#------------------------------------------------------------------------
sub time {
	my $self = shift;
	return $self->formatted('hh:mm');
}

sub time_ampm {
	my $self = shift;
	return $self->formatted('H:mm AM');
}

#------------------------------------------------------------------------
# 24hour HACK
# This method overwrites Time::Local::timelocal
# That is to easily workaround a problem between weather.com and
# the original 'timelocal' function: 'timelocal' only accepts hours
# from 0 to 23, but weather.com works from 0 to 24...
#------------------------------------------------------------------------
sub timelocal {
	my ( $sec, $min, $hour, $mday, $mon, $year ) = @_;
	my $twentyforhack = 0;

	if ( $hour == 24 ) {
		$hour          = 23;
		$twentyforhack = 1;
	}

	my $epoc = &Time::Local::timelocal( 0, $min, $hour, $mday, $mon, $year );

	if ($twentyforhack) {
		$epoc += 3600;
	}

	return $epoc;
}

1;

__END__

=pod

=head1 NAME

Weather::Com::DateTime - date and time class

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use Weather::Com::DateTime;
  
  my $gmt_offset = 1; # e.g. for Germany in winter
  my $datetime = Weather::Com::DateTime->new($gmt_offset);
  $datetime->set_lsup('02/25/05 11:21 PM Local Time');
  
  print "This is the date '02/25/05 11:21 PM' in Germany:\n";
  print "Epoc:                    ", $datetime->epoc(), "\n";
  print "GMT (UTC):               ". gmtime($datetime->epoc()). "\n";
  print "My local time:           ". localtime($datetime->epoc()). "\n";
  print "And finally German time: ", $datetime->time(), " o'clock at ", 
  	$datetime->date(), "\n\n";

=head1 DESCRIPTION

I<Weather::Com::DateTime> objects are used to encapsulate a date or time
provided by the OO interface (e.g. localtime, sunrise, sunset, etc.).

This is done because there are many ways to use a date or time and to
present it in your programs using I<Weather::Com>. This class provides
some predefined formats for date and time but also enables you to
easily define your own ones.

These objects always represent the local time of a I<Weather::Com::Location>
object. That is, if you have a location object for New York City and your
server running the weather script is located in Los Angeles, for example,
this line

  print "Sunrise at: ", $location->sunrise()->time(), "\n";

will print the time of sunrise (in 24h format) in EST and not corresponding
to the timezone of Los Angeles! If you'd like to now what this is in GMT 
you could call

  print "Sunrise at: ". gmtime($location->sunrise()->epoc()). "\n";

or if you want to know when the sun rises at the location in your
servers local time than just call

  print "Sunrise at: ". localtime($location->sunrise()->epoc()). "\n";


There are two ways to get your own date or time format:

=over 4

=item 1.

You use the C<formatted()> method and provide a format string to it.

=item 2.

If you'd like to define your own C<date()> or C<time()> method, simply
change the corresponding methods.

What you can change in which way without destroying the whole class,
is described in section B<INTERFACE>.

=back

=head1 CONSTRUCTOR

You usually would not construct an object of this class yourself. 
This is implicitely done when you call one of the OO interfaces
date or time methods.

The constructor can take a GMT offset in positive or negative hours.

If one calls the constructor without any GMT offset, we assume you want
a GMT object.

=head1 METHODS

=head2 epoc(epoc seconds)

With this method you can set the date and time using epocs (GMT) directly.

It returns the currently set epoc seconds (GMT).

=head2 formatted(format)

This method returns a date or time formatted in the way you ask for and
corresponding to the local time of the parent object.

The C<format> you provide to this method has to be a valid I<Time::Format>
format. For details please refer to L<Time::Format>.

=head2 set_date(date)

With this method one can set the date of the object using an input
format like C<Feb 13> which is the 13th of february of the current
year.

Using this method, the time is set to I<00:00>. The year is the
current one.

=head2 set_time(time)

With this method one can set the time of the object using an input
format like C<8:30 AM>.

The date is set to the current date of the host the script is running
on.

=head2 set_lsup(lsup)

With this method one can set the date of the object using the
I<weather.com>'s special last update format that is like
C<2/12/05 4:50 PM Local Time>.

=head2 date()

Returns the date in the format C<1. February 2005>.

=head2 time()

Returns the time in the format C<22:15>.

=head2 time_ampm()

Returns the time in the format C<10:15 PM>.

=head2 weekday()

Returns the day of week with like C<Wednesday>.

=head2 day()

Returns the day in month.

=head2 month()

Returns the name of the month.

=head2 mon()

Returns the number of the month

=head2 year()

Returns the year (4 digits).

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (L<http://www.weather.com/services/xmloap.html>)!

=cut

