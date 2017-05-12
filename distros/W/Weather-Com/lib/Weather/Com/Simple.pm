package Weather::Com::Simple;

use Carp;
use Weather::Com::Base qw(celsius2fahrenheit convert_winddirection);
use Weather::Com::Cached;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	my %parameters;

	# some general attributes
	$self->{PROXY} = "none";
	$self->{DEBUG} = 0;
	$self->{CACHE} = ".";

	# parameters provided by new method
	if ( ref( $_[0] ) eq "HASH" ) {
		%parameters = %{ $_[0] };
	} else {
		%parameters = @_;
	}

	$self = bless( $self, $class );

	# check mandatory parameters
	unless ( $parameters{place} ) {
		$self->_debug("ERROR: Location not specified");
		return undef;
	}

	# put wanted parameters into $self
	$self->{PLACE}      = $parameters{place};
	$self->{PROXY}      = $parameters{proxy} if ( $parameters{proxy} );
	$self->{PROXY_USER} = $parameters{proxy_user}
	  if ( $parameters{proxy_user} );
	$self->{PROXY_PASS} = $parameters{proxy_pass}
	  if ( $parameters{proxy_pass} );
	$self->{DEBUG} = $parameters{debug} if ( $parameters{debug} );
	$self->{CACHE} = $parameters{cache} if ( $parameters{cache} );

	# Weather::Com::Cached object
	my %weatherargs = (
						'current'    => 1,
						'forecast'   => 0,
						'proxy'      => $self->{PROXY},
						'proxy_user' => $self->{PROXY_USER},
						'proxy_pass' => $self->{PROXY_PASS},
						'debug'      => $self->{DEBUG},
						'cache'      => $self->{CACHE},
	);

	$weatherargs{timeout} = $parameters{timeout} if ( $parameters{timeout} );
	$weatherargs{partner_id} = $parameters{partner_id}
	  if ( $parameters{partner_id} );
	$weatherargs{license} = $parameters{license} if ( $parameters{license} );

	# initialize weather object
	$self->{WEATHER} = Weather::Com::Cached->new(%weatherargs);

	return $self;
}    # end new()

#------------------------------------------------------------------------
# accessor methods
#------------------------------------------------------------------------
sub get_weather {
	my $self = shift;
	my $allweather;
	my $place_result = $self->{WEATHER}->search( $self->{PLACE} );

	# check if search succeeded
	unless ($place_result) {
		$self->_debug($@);
		return undef;
	}

	foreach ( keys %{$place_result} ) {
		my $weatherdata = $self->{WEATHER}->get_weather($_);

		unless ($weatherdata) {
			$self->_debug($@);
			return 0;
		}

		my $place_weather = {

			# header data
			'place'   => $weatherdata->{loc}->{dnam},
			'updated' => _parse_timestring( $weatherdata->{cc}->{lsup} ),

			# temperature celsius/fahrenheit
			'celsius'             => $weatherdata->{cc}->{tmp},
			'temperature_celsius' => $weatherdata->{cc}->{tmp},
			'windchill_celsius'   => $weatherdata->{cc}->{flik},
			'fahrenheit' => celsius2fahrenheit( $weatherdata->{cc}->{tmp} ),
			'temperature_fahrenheit' =>
			  celsius2fahrenheit( $weatherdata->{cc}->{tmp} ),
			'windchill_fahrenheit' =>
			  celsius2fahrenheit( $weatherdata->{cc}->{flik} ),    

			# wind
			'wind'          => _parse_wind( $weatherdata->{cc}->{wind} ),
			'windspeed_kmh' =>
			  _parse_windspeed_kmh( $weatherdata->{cc}->{wind} ),
			'windspeed_mph' =>
			  _parse_windspeed_mph( $weatherdata->{cc}->{wind} ),

			# other
			'humidity'   => $weatherdata->{cc}->{hmid},
			'conditions' => $weatherdata->{cc}->{t},
			'pressure'   => _parse_pressure( $weatherdata->{cc}->{bar} ),
		};

		push( @{$allweather}, $place_weather );
	}

	return $allweather;
}

sub getweather {
	return get_weather(@_);
}

#------------------------------------------------------------------------
# internal parsing utilities
#------------------------------------------------------------------------
sub _parse_wind {
	my $winddata = shift;
	my $wind;

	if ( lc( $winddata->{s} ) =~ /calm/ ) {
		$wind = "calm";
	} else {
		my $kmh       = _parse_windspeed_kmh($winddata);
		my $mph       = _parse_windspeed_mph($winddata);
		my $direction = convert_winddirection( $winddata->{t} );
		$wind = "$mph mph $kmh km/h from the $direction";
	}
	return $wind;
}

sub _parse_windspeed_kmh {
	my $winddata = shift;
	my $speed;

	if ( lc( $winddata->{s} ) =~ /calm/ ) {
		$speed = "calm";
	} else {
		$speed = $winddata->{s};
	}
	return $speed;
}

sub _parse_windspeed_mph {
	my $winddata = shift;
	my $speed;

	if ( lc( $winddata->{s} ) =~ /calm/ ) {
		$speed = "calm";
	} else {
		$speed = sprintf( "%d", $winddata->{s} * 0.6213722 );
	}
	return $speed;
}

sub _parse_pressure {
	my $pressuredata = shift;
	my $pressure;

	my $hPa = $pressuredata->{r};
	$hPa =~ s/,//g;
	my $in = $hPa * 0.02953;

	$pressure = sprintf( "%.2f in / %.1f hPa", $in, $hPa );
}

sub _parse_timestring {
	my $timestring = shift;
	my @months = (
				   "",       "January",   "February", "March",
				   "April",  "May",       "June",     "July",
				   "August", "September", "October",  "November",
				   "Dezember"
	);

	my ( $date, $time, $ampm, $zone ) = split( / /, $timestring );
	my ( $month, $mday, $year ) = split( "/", $date );

	return "$time $ampm $zone on $months[$month] $mday, " . ( $year + 2000 );
}

#------------------------------------------------------------------------
# other internals
#------------------------------------------------------------------------
sub _debug {
	my $self   = shift;
	my $notice = shift;
	if ( $self->{DEBUG} ) {
		carp ref($self) . " DEBUG NOTE: $notice\n";
		return 1;
	}
	return 0;
}

1;

__END__

=pod

=head1 NAME

Weather::Com::Simple - Simple Wrapper around the L<Weather::Com::Cached> API

=head1 SYNOPSIS

  use Data::Dumper;
  use Weather::Com::Simple;
  
  # define parameters for weather search
  my %params = (
		'partner_id' => 'somepartnerid',
		'license'    => '12345678',
		'place'      => 'Heidelberg',
  );
  
  # instantiate a new weather.com object
  my $simple_weather = Weather::Com::Simple->new(%params);

  my $weather = $simple_weather->get_weather();
  
  print Dumper($weather);
  

=head1 DESCRIPTION

I<Weather::Com::Simple> is a very high level wrapper around I<Weather::Com::Cached>.
You provide a place to search for (e.g. a city or "city, country") and you'll get
back a simple hash containing some usefull weather information about all locations
whose name matches to the search string.

=head1 CONSTRUCTOR

=head2 new(hash or hashref)

The constructor takes the same hash or hashref as L<Weather::Com::Cached> does.
Please refer to that documentation for further details.

Except from the L<Weather::Com::Cached> parameters this constructor takes a
parameter I<place> which defines the location to search for. It is not
possible to provide the location to search to the I<get_weather()> method!

=head1 METHODS

=head2 get_weather()

This method invokes the L<Weather::Com::Cached> API to fetch some
weather information and returns an arrayref containing one
or many hashrefs with some high level weather information.

If no location matching the search string is found, it returns
I<undef>.

When you construct a L<Weather::Com::Simple> object like shown in
the synopsis above, the arrayref returned has the following structure:

  $VAR1 = [
		{
			'place'      => 'Heidelberg, Germany',
			'celsius'                => '0',
			'fahrenheit'             => '32',
			'temperature_celsius'    => '0',
			'temperature_fahrenheit' => '32'
			'windchill_celsius'      => '-6',
			'windchill_fahrenheit'   => '21',
			'windspeed_kmh'          => '26',
			'windspeed_mph'          => '16',
			'wind'       => '16 mph 26 km/h from the North Northeast',
			'updated'    => '11:50 AM Local on January 26, 2005',
			'conditions' => 'Partly Cloudy',
			'pressure'   => '30.21 in / 1023.0 hPa',
			'humidity'   => '60',
   		},
		{
			'place' => 'Heidelberg, KY',
			
			...
			
		},
		{
			'place' => 'Heidelberg, MS',
			
			...
			
		}
	];


=head1 SEE ALSO

See also documentation of L<Weather::Com> and L<Weather::Com::Cached>.

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

