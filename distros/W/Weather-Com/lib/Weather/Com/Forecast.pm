package Weather::Com::Forecast;

use 5.006;
use strict;
use Carp;
use Data::Dumper;
use Weather::Com::DayForecast;
use base "Weather::Com::Cached";

our $VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)/g;

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %parameters;

	# parameters provided by new method
	if ( ref( $_[0] ) eq "HASH" ) {
		%parameters = %{ $_[0] };
	} else {
		%parameters = @_;
	}

	unless ( $parameters{location_id} ) {
		die "You need to provide a location id!\n";
	}

	# set some parameters to sensible values for a
	# current conditions object
	$parameters{current}  = 0;
	$parameters{forecast} = 10;
	$parameters{links}    = 0;

	# creating the SUPER instance
	my $self = $class->SUPER::new( \%parameters );
	$self->{ID} = $parameters{location_id};

	# getting first weather info
	$self->{WEATHER} = $self->get_weather( $self->{ID} );
	$self->{DAYS}    = undef;
	$self->_build_forecasts();    
	$self->{LSUP} = time();

	return $self;
}    # end new()

#------------------------------------------------------------------------
# refresh weather data
#------------------------------------------------------------------------
sub refresh {
	my $self = shift;
	my $now  = time();

	# only refresh if last update has been more than 15 min ago
	if ( ( $now - $self->{LSUP} ) > 900 ) {
		$self->{WEATHER} = $self->get_weather( $self->{ID} );
		$self->_build_forecasts();
		$self->{LSUP} = $now;
	}
	return 1;
}

#------------------------------------------------------------------------
# access location data
#------------------------------------------------------------------------
sub day {
	my $self = shift;
	my $day  = shift;    # 0 - 9

	return 0 unless ( ( $day >= 0 ) && ( $day <= 9 ) );

	$self->refresh();
	return $self->{DAYS}->[$day];
}

sub all {
	my $self = shift;
	$self->refresh();

	if ( wantarray() ) {
		return @{ $self->{DAYS} };
	} else {
		return $self->{DAYS};
	}
}

#------------------------------------------------------------------------
# build up forecast hashes
#------------------------------------------------------------------------
sub _build_forecasts {
	my $self = shift;

	# initialize $self->{DAYS} array of new DayForecast objects
	unless ( $self->{DAYS} ) {
		for ( my $i = 0 ; $i < 10 ; $i++ ) {
			$self->_debug("Initializing forecast for day $i");
			$self->{DAYS}->[$i] = Weather::Com::DayForecast->new($self->{ARGS});
		}
	}

	# then update the DayForecast objects
	# but put the timeszone into it...
	foreach my $day ( @{ $self->{WEATHER}->{dayf}->{day} } ) {
		my %args = (%{$day}, (zone => $self->{ARGS}->{zone}));
		$self->{DAYS}->[ $day->{d} ]->update(\%args);
	}

	return 1;
}

1;

__END__

=pod

=head1 NAME

Weather::Com::Forecast - class representing all available weather 
forecasts for one location

=head1 SYNOPSIS

  [...]
    
  my @locations = $weather_finder->find('Heidelberg');

  my $forecast = $locations[0]->forecast();
  my $tomorrow = $forecast->day(1);

  print "Forecast for tomorrow:\n";
  print " - tomorrow it's the ", $tomorrow->date()->date(), "\n";  
  print " - sunrise will be at ", $tomorrow->sunrise()->time(), "\n";  
  print " - maximum temperature will be ", $tomorrow->high(), "\n";  

=head1 DESCRIPTION

Using I<Weather::Com::Forecast> objects is the way to access weather 
forecast information for one specific location (city) and 0 (today) to
9 days in the future.

Each time you call the I<Weather::Com::Location> objects' C<forecast()>
method, you'll get an updated I<Weather::Com::Forecast> object. This 
object is used to access the 10 I<Weather::Com::DayForecast> objects
containing the actual data.

=head1 CONSTRUCTOR

=head2 new(hash or hashref)

You usually would not construct an object of this class yourself. 
This is implicitely done when you call the C<forecast()> method of 
a I<Weather::Com::Location> object.

=head1 METHODS

=head2 all() 

Returns an arrayref of all I<Weather::Com::DayForecast> objects if called
in scalar context, an array if called in list context.

=head2 day(day number)

Returns the I<Weather::Com::DayForecast> object that corresponds to the day
number you provided. 

The day number can be any number between 0 and 9.

Day 0 is usually I<today>. Due to a bug (I think it is one) in the I<weather.com>
XOAP API, you may get the full forecast data of I<yesterday> if you call for
day 0 just after midnight. I think this may have do something with the timezone.
I have not fully investigated this issue, yet. Please contact me, if you have!

=head1 SEE ALSO

See also documentation of L<Weather::Com>, L<Weather::Com::Location>,
L<Weather::Com::DayForecast>.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (http://www.weather.com/services/xmloap.html)

=cut

