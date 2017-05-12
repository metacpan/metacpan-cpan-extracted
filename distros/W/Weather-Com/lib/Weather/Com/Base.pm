package Weather::Com::Base;

use 5.006;
use strict;
use warnings;
use Carp;
use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use Data::Dumper;
use Time::Local;
use base qw(Weather::Com::Object Exporter);

#--------------------------------------------------------------------
# Define some globals
#--------------------------------------------------------------------
our @EXPORT_OK = qw( 
	celsius2fahrenheit 
	fahrenheit2celsius 
	convert_winddirection
);

our $VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)/g;

my $CITY_SEARCH_URI    = "http://xoap.weather.com/search/search?where=";
my $WEATHER_SEARCH_URI = "http://xoap.weather.com/weather/local/";

my %winddir = (
				"none"            => "none",
				'N/A'             => "Not Available",
				"VAR"             => "Variable",
				"N"               => "North",
				"NNW"             => "North Northwest",
				"NW"              => "Northwest",
				"WNW"             => "West Northwest",
				"W"               => "West",
				"WSW"             => "West Southwest",
				"SW"              => "Southwest",
				"SSW"             => "South Southwest",
				"S"               => "South",
				"SSE"             => "South Southeast",
				"SE"              => "Southeast",
				"ESE"             => "East Southeast",
				"E"               => "East",
				"ENE"             => "East Northeast",
				"NE"              => "Northeast",
				"NNE"             => "North Northeast",
				"Not Available"   => 'N/A',
				"North"           => "N",
				"North Northwest" => "NNW",
				"Northwest"       => "NW",
				"West Northwest"  => "WNW",
				"West"            => "W",
				"West Southwest"  => "WSW",
				"Southwest"       => "SW",
				"South Southwest" => "SSW",
				"South"           => "S",
				"South Southeast" => "SSE",
				"Southeast"       => "SE",
				"East Southeast"  => "ESE",
				"East"            => "E",
				"East Northeast"  => "ENE",
				"Northeast"       => "NE",
				"North Northeast" => "NNE",
				"Variable"        => "VAR",
);

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

	# get SUPER instance
	my $self = $class->SUPER::new( \%parameters );

	# some general attributes
	$self->{PROXY}   = "none";
	$self->{TIMEOUT} = 180;
	$self->{DEBUG}   = 0;

	# license information
	$self->{PARTNER_ID}  = undef;
	$self->{LICENSE_KEY} = undef;

	# API specific attributes
	$self->{UNITS}    = 'm';    # could be 'm' for metric or 's' for us standard
	$self->{CC}       = 0;      # show current conditions true/false
	$self->{FORECAST} = 0;      # multi day forecast 0 = no, 1..10 days
	$self->{LINKS}    = 0;

	# save params for further use
	$self->{ARGS} = \%parameters;

	# do some initialization with validity checking
	$self = $self->_init();

	# and some debugging output
	$self->_debug( "Returning object: " . Dumper($self) );

	return $self;
}

sub _init {
	my $self   = shift;
	my $params = $self->{ARGS};

	# set proxy if param is set properly
	if ( $params->{proxy} && ( lc( $params->{proxy} ) ne "none" ) ) {
		unless ( $params->{proxy} =~ /^(http|HTTP)\:\/\// ) {
			die ref($self)
			  . ": 'proxy' parameter has to start with 'http://'!\n";
		}
		$self->{PROXY} = $params->{proxy};
	}

	# set proxy authentication data if param is set properly
	if (    $params->{proxy_user}
		 && $params->{proxy_pass}
		 && ( lc( $params->{proxy_user} ) ne "none" ) )
	{
		$self->{PROXY_USER} = $params->{proxy_user};
		$self->{PROXY_PASS} = $params->{proxy_pass};
	}

	# set timeout if it is a possitive integer or 0
	if ( $params->{timeout} ) {
		unless (    ( $params->{timeout} =~ /^\d+$/ )
				 && ( $params->{timeout} > -1 ) )
		{
			die ref($self)
			  . ": 'timeout' parameter has to be a positive integer or 0!\n";
		}
		$self->{TIMEOUT} = $params->{timeout};
	}

	# set units of measure if set to 'm' or 's'
	if ( $params->{units} ) {
		unless ( lc( $params->{units} ) =~ /^m|s$/ ) {
			die ref($self)
			  . ": 'units' parameter has to be set to 'm' or 's'!\n";
		}
		$self->{UNITS} = $params->{units} if ( $params->{units} );

	}

	# forecast has to be between 0 and 10
	if ( $params->{forecast} ) {
		unless ( $params->{forecast} =~ /^[1]?\d$/ ) {
			die ref($self)
			  . ": 'forecast' parameter has to between 0 and 10!\n";
		}
		$self->{FORECAST} = $params->{forecast};
	}

	# set params that don't need to be checked
	$self->{PARTNER_ID} = $params->{partner_id}
	  if ( $params->{partner_id} );
	$self->{LICENSE_KEY} = $params->{license} if ( $params->{license} );
	$self->{DEBUG}       = $params->{debug}   if ( $params->{debug} );
	$self->{CC}          = $params->{current} if ( $params->{current} );
	$self->{LINKS}       = $params->{links}   if ( $params->{links} );

	if ( $params->{lang} ) {
		$self->{LANGUAGE} = $params->{lang};
	} else {
		$self->{LANGUAGE} = 'en_US';
	}

	return $self;
}

#------------------------------------------------------------------------
# getting data from weather.com
#------------------------------------------------------------------------
sub search {
	my $self  = shift;
	my $place = shift;

	# set error and die if no place provided
	unless ($place) {
		die ref($self), ": ERROR Please provide a location to search for!\n";
	}

	# build up HTTP GET request
	$place = uri_escape($place);
	my $searchlocation = $CITY_SEARCH_URI . $place;
	$searchlocation .= '&prod=xoap';
	if ( $self->{PARTNER_ID} && $self->{LICENSE_KEY} ) {
		$searchlocation .= '&par=' . $self->{PARTNER_ID};
		$searchlocation .= '&key=' . $self->{LICENSE_KEY};
	}

	$self->_debug($searchlocation);

	# get information
	my $locationXML;
	my $i = 0;
	while ( !$locationXML || ( $locationXML !~ /^\<\?xml/ ) && ( $i < 3 ) ) {
		eval { $locationXML = $self->_getWebPage($searchlocation); };
		if ($@) {
			die ref($self),
": ERROR No response from weather server while searching place: $@\n";
		}

		# check if at least one location has been returned
		# if not return 0
		if ( $locationXML =~ /^\s*$/g ) {
			$self->_debug(
				"No location found using $place (url escaped) as search string." );
			return 0;
		}

		$i++;
	}

	return 0 unless ( $locationXML =~ /^\<\?xml/ );

	# parse answer
	my $simpleHash = XMLin($locationXML);

	# XML::Simple behaves differently when one location is return than
	# when more locations are returned ...
	my $locations = undef;
	if ( $simpleHash->{loc}->{content} ) {
		$locations->{ $simpleHash->{loc}->{id} } =
		  $simpleHash->{loc}->{content};
	} else {
		foreach ( keys %{ $simpleHash->{loc} } ) {
			$locations->{$_} = $simpleHash->{loc}->{$_}->{content};
		}
	}

	$self->_debug( Dumper($locations) );

	return $locations;
}    # end search()

sub get_weather {
	my $self  = shift;
	my $locid = shift;

	unless ($locid) {
		die ref($self), ": ERROR Please provide a location id!\n";
	}

	# prepare HTTP Request
	my $searchlocation = $WEATHER_SEARCH_URI . $locid;
	$searchlocation .= '?unit=' . $self->{UNITS};
	$searchlocation .= '&prod=xoap';

	if ( $self->{PARTNER_ID} && $self->{LICENSE_KEY} ) {
		$searchlocation .= '&par=' . $self->{PARTNER_ID};
		$searchlocation .= '&key=' . $self->{LICENSE_KEY};
	}
	if ( $self->{CC} ) {
		$searchlocation .= '&cc=*';
	}
	if ( $self->{FORECAST} ) {
		$searchlocation .= '&dayf=' . $self->{FORECAST};
	}
	if ( $self->{LINKS} ) {
		$searchlocation .= '&link=xoap';
	}

	# get weather data
	$self->_debug($searchlocation);
	my $weatherXML;
	eval { $weatherXML = $self->_getWebPage($searchlocation); };
	if ($@) {
		die ref($self),
		  ": ERROR No response from weather server while loading data: $@\n";
	}

	# parse weather data
	my %options = (
					ForceArray => ["day"],    
	);
	my $simpleHash = XMLin($weatherXML, %options);

	# do some error handling if weather.com returns an error message
	if ( $simpleHash->{err} ) {
		die ref($self), ": ERROR ", $simpleHash->{err}->{content}, "\n";
	}

	$self->_debug(Dumper($simpleHash));

	return $simpleHash;
}

#--------------------------------------------------------------------
# Utility function to get one web pages content or die on error
#--------------------------------------------------------------------
sub _getWebPage {
	my $self = shift;
	my $path = shift;

	# instantiate a new user agent, with proxy if necessary
	my $ua      = LWP::UserAgent->new();
	my $request = HTTP::Request->new( "GET" => $path );

	$ua->proxy( 'http', $self->{PROXY} )
	  if ( lc( $self->{PROXY} ) ne "none" );
	$request->proxy_authorization_basic( $self->{PROXY_USER},
										 $self->{PROXY_PASS} )
	  if ( lc( $self->{PROXY_USER} ) ne "none" );
	$ua->timeout( $self->{TIMEOUT} );

	# print some debugging info on the user agent object
	$self->_debug("This is the user agent we wanna use:");
	$self->_debug( Dumper($ua) );
	$self->_debug("Together with this request:");
	$self->_debug( Dumper($request) );

	# get the html page
	my $response = $ua->request($request);

	# and do some error handling
	my $html = undef;
	if ( $response->is_success() ) {
		$html = $response->content();
	} else {
		die "ERROR While getting resource: $path :\n", $response->status_line(),
		  "\n";
	}

	# and print the complete HTML response for debugging purposes
	$self->_debug($html);

	return $html;
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

#########################################################################
#
#	STATIC methods go here
#
#------------------------------------------------------------------------
# methods for temperature conversion
#------------------------------------------------------------------------
sub celsius2fahrenheit {
	my $celsius = shift;
	my $fahrenheit = sprintf( "%d", ( $celsius * 1.8 ) + 32 );
	return $fahrenheit;
}

sub fahrenheit2celsius {
	my $fahrenheit = shift;
	my $celsius = sprintf( "%d", ( $fahrenheit - 32 ) / 1.8 );
	return $celsius;
}

#------------------------------------------------------------------------
# internal time conversion methods
#------------------------------------------------------------------------
sub _lsup2epoc {

	# this method returns epoc for gmt corresponding to
	# the provided last update value (lsup)
	my $lsup       = shift;
	my $gmt_offset = shift;

	my ( $date, $time, $ampm, $zone ) = split( / /, $lsup );
	my ( $mon, $mday, $year ) = split( "/", $date );
	my ( $hour, $min ) = split( /:/, $time );

	$year += 100;
	$hour += 12 if ( $ampm eq "PM" );

	my $gmtime = timegm( 0, $min, $hour, $mday, $mon - 1, $year );
	$gmtime -= $gmt_offset * 3600;

	return $gmtime;
}

sub _epoc2lsup {

	# this method takes epoc (gmt) and builds up the weather.com
	# internally used last update format (lsup)
	my $epoc       = shift;
	my $gmt_offset = shift;

	my ( $sec, $min, $hour, $mday, $mon, $year ) =
	  gmtime( $epoc + $gmt_offset * 3600 );

	$year -= 100;
	$year = '0' . $year if ( $year < 10 );
	$mon++;
	my $ampm = "AM";

	if ( $hour > 12 ) {
		$hour -= 12;
		$ampm = "PM";
	}

	my $time = join( ":", $hour, $min );
	my $date = join( "/", $mon,  $mday, $year );
	my $lsup = join( " ", $date, $time, $ampm, "Local Time" );

	return $lsup;
}

sub _simple2twentyfour {
	my $stime   = shift;
	my $colon   = index( $stime, ":" );
	my $hour    = substr( $stime, 0, $colon );
	my $minutes = substr( $stime, $colon + 1, 2 );
	my $ampm    = substr( $stime, 6 );

	if ( lc($ampm) =~ /PM/ ) {
		return $hour + 12 . ":" . $minutes;
	} else {
		return "$hour:$minutes";
	}
}

#------------------------------------------------------------------------
# wind direction conversion methods
#------------------------------------------------------------------------
sub convert_winddirection {
	my $indir = shift;
	return $winddir{$indir};
}

1;
__END__

=pod

=head1 NAME

Weather::Com::Base - Perl extension for getting weather information from weather.com

=head1 SYNOPSIS

  use Data::Dumper;
  use Weather::Com::Base;
  
  # define parameters for weather search
  my %params = (
		'current'    => 1,
		'forecast'   => 3,
		'links'      => 1,
		'units'      => 's',
		'proxy'      => 'http://proxy.sonstwo.de',
		'timeout'    => 250,
		'debug'      => 1,
		'partner_id' => 'somepartnerid',
		'license'    => '12345678',
  );
  
  # instantiate a new weather.com object
  my $weather_com = Weather::Com::Base->new(%params);
  
  # search for locations called 'Heidelberg'
  my $locations = $weather_com->search('Heidelberg')
  	or die "No location found!\n";
  
  # and then get the weather for each location found
  foreach (keys %{$locations}) {
	my $weather = $weather_com->get_weather($_);
	print Dumper($weather);
  }

=head1 DESCRIPTION

I<Weather::Com::Base> is a Perl module that provides low level OO interface
to gather all weather information that is provided by I<weather.com>. 

This module should not be used directly because of the business rules
applying if one want's to use the I<weather.com>'s I<xoap> interface.
These business rules enforce you to implement several caching rules.

Therefore, if you want to use a low level interface, please use
I<Weather::Com::Cached> instead. It has the same interface as this module
but it implements all caching rules of I<weather.com>.

=head2 EXPORT

None by default. But there are a few static methods for conversion
purposes you may wanna use:

=over 4

=item * celsius2fahrenheit(celsius)

Takes the temperature in celsius and returns the temperature in fahrenheit
(as an integer value).

=item * fahrenheit2celsius(fahrenheit)

Takes the temperature in fahrenheit  and returns the temperature in celius
(as an integer value).

=item * convert_winddirection(direction)

Takes a wind mnemonic ("N", "WNW", etc.) or a long name of a wind direction
("North Northeast") and returns the other format.

The long names are only understood if used as follows:

				"North"
				"North Northwest"
				"Northwest"
				"West Northwest"
				"West"
				"West Southwest"
				"Southwest"
				"South Southwest"
				"South"
				"South Southeast"
				"Southeast"
				"East Southeast"
				"East"
				"East Northeast"
				"Northeast"
				"North Northeast"
				"Variable"

=back

=head1 CONSTRUCTOR

=head2 new(hash or hashref)

The constructor takes a hash or a hashref containing a bunch of parameters
used to configure your weather search. None of these paramters is mandatory.
As there are reasonable defaults for any of them, you need only to provide
those parameters where you whish to go with non-default values.

The parameters in detail:

=over 4

=item current =>  0 | 1 

This parameter defines whether to fetch the current conditions of a location
or not.

Defaults to 0 (false).

=item forecast => 0 | 1 .. 10

This parameter defines whether to fetch a weather forecast or not. 

If set to 0 (false) no forecast is read, if set to a value 
between 1 and 10 a forecast for the number of days is requested. If
set to any other value, this is interpreted as 0!

Defaults to 0 (false).

=item links => 0 | 1

This parameter specifies whether to load some http links from I<weather.com>
also or not.

=item units => s | m

This parameter defines whether to fetch information in metric (m) or 
US (s) format. 

Defaults to 'm'.

=item proxy => 'none' | 'http://some.proxy.de:8080'

Usually no proxy is used by the L<LWP::UserAgent> module used to communicate
with I<weather.com>. If you want to use an HTTP proxy you can specify one here.

=item proxy_user => undef | 'myuser'

If specified, this parameter is provided to the proxy for authentication
purposes.

Defaults to I<undef>.

=item proxy_pass => undef | 'mypassword'

If specified, this parameter is provided to the proxy for authentication
purposes.

Defaults to I<undef>.

=item timeout => some integer (in seconds)

The timeout for I<LWP::UserAgent> to get an HTTP request done usually is set to
180s. If you need a longer timeout or for some reasons a shorter one you can
set this here.

Defaults to 180 seconds.

=item debug => 0 | 1

Set debugging on/off.

Defaults to 0 (off).

=item partner_id => 'somepartnerid'

To be allowed to fetch weather information from I<weather.com> you need to
register (free of charge) to get a so called I<Partner Id> and a 
I<License Key>. 

=item license => 'somelicensekey'

See I<partner_id>.

=back

=head1 METHODS

=head2 search(place to search)

Searches for all known locations matching the provided search string.

At I<weather.com> you have to request weather data for a specific location.
Therefor you first have to find the location id for the location you are
looking for. I<weather.com> provides two possibilities to search:

=over 4

=item 1. by name

You may search for a location by name, e.g. "Heidelberg", "Heidelberg, Germany",
"New York, NY", etc.

=item 2. by postal code

You may search for a location by the postal code.

=back

If the search causes an error, this methods dies with a (hopefully) helpful
error message. 

If the search returns no matches, 0 is returned.

Else, the method returns a hashref containing all locations found.
The hashref looks as follows if you search for I<Heidelberg>:

  $HASHREF = {
  	'GMXX0053' => 'Heidelberg, Germany',
  	'USKY0990' => 'Heidelberg, KY',
  	'USMS0154' => 'Heidelberg, MS'
  };

The keys of the hash are the location ids as used within I<weather.com>. 
This keys have to be used for fetching the weather information of one
location.

=head2 get_weather(location id)

This method fetches all weather information as defined by the object
attributes you may have modified while instantiating the weather
object. 

If an error occurs while fetching weather information, this method
dies setting $@ to a meaningfull error message.

The following hashref shows the maximum of data that can be fetched from
I<weather.com>. The parts of the hashref are explained afterwards.

  $HASHREF = {
  	'head' => {
  		'ur'     => 'mm',
  		'ud'     => 'km',
  		'us'     => 'km/h',
  		'form'   => 'MEDIUM',
  		'up'     => 'mb',
  		'locale' => 'en_US',
  		'ut'     => 'C'
  	},
  	'loc' => {
  		'suns'   => '8:40 PM',
  		'zone'   => '2',
  		'lat'    => '49.41',
  		'tm'     => '3:48 PM',
  		'sunr'   => '6:18 AM',
  		'dnam'   => 'Heidelberg, Germany',
  		'id'     => 'GMXX0053',
  		'lon'    => '8.68'
  	},
  	'cc' => {
		'icon' => '28',
		'flik' => '21',
		'obst' => 'Mannhein, Germany',
		'lsup' => '8/16/04 3:20 PM Local Time',
		'tmp'  => '21',
		'hmid' => '78',
		'wind' => {
			'gust' => 'N/A',
			'd'    => '170',
			's'    => '11',
			't'    => 'S'
		},
		'bar'  => {
			'r' => '1,010.8',
			'd' => 'steady'
        },
		'dewp' => '17',
		'uv'   => {
			't' => 'Moderate',
			'i' => '3'
		},
		'vis'  => '10.0',
		't'    => 'Mostly Cloudy'
	},
	'dayf' => {
		'lsup' => '8/16/04 12:17 PM Local Time',
		'day'  => [	
			{
				'hi'   => '27',
				'suns' => '8:40 PM',
				'dt'   => 'Aug 16',
				'part' => [
					{
						'hmid' => '57',
						'wind' => {
							'gust' => 'N/A',
							'd'    => '204',
							's'    => '16',
							't'    => 'SSW'
						},
						'icon' => '28',
						'p'    => 'd',
						'ppcp' => '20',
						't'    => 'Mostly Cloudy'
					},
					{
						'hmid' => '87',
						'wind' => {
							'gust' => 'N/A',
							'd'    => '215',
							's'    => '13',
							't'    => 'SW'
						},
						'icon' => '11',
						'p'    => 'n',
						'ppcp' => '60',
						't'    => 'Showers'
					}
				],
				'd'    => '0',
				'sunr' => '6:18 AM',
				'low'  => '16',
				't'    => 'Monday'
			},
			
			... next day ...,
			
			... and so on ...,
			
		]
	},
	'lnks' => {
		'link' => [
			{
				'l'   => 'http://www.weather.com/outlook/health/allergies/USMS0154?par=xoap',
				'pos' => '1',
				't'   => 'Pollen Reports'
			},
			{
				'l'   => 'http://www.weather.com/outlook/travel/flights/citywx/USMS0154?par=xoap',
				'pos' => '2',
				't'   => 'Airport Delays'
			},
			{
				'l'   => 'http://www.weather.com/outlook/events/special/result/USMS0154?when=thisweek&par=xoap',
				'pos' => '3',
				't'   => 'Special Events'
			},
			{
				'l'   => 'http://www.weather.com/services/desktop.html?par=xoap',
				'pos' => '4',
				't'   => 'Download Desktop Weather'
			}
		],
		'type' => 'prmo'
	},
	'ver' => '2.0'
  };

=head3 Header Information Block

The hashref I<head> contains unit of measure definitions for the
whole dataset. Usually they are either all metric or all us.

=over 4

=item locale

Should always be I<en_US>. Up to now I have not found any possiblity to
get other locales.

=item ut (unit of temperature)

Could be I<C> for Celsius or I<F> for Fahrenheit.

=item us (unit of speed)

Could be I<km/h> or I<mph>.

=item ud (unit of distance)

Could be I<km> or I<mi>.

=item ur (unit of precipitation)

Could be I<mb> (millibar) or I<in>.

=item up (unit of pressure)

Could be I<mb> or I<in> for in Hg.

=item format (textformat)

Could be I<SHORT>, I<MEDIUM> or I<LONG>.

=back

=head3 Location Information Block

The hashref I<loc> contains some information about the location that does
not change very much each hour or day.

=over 4

=item id (location id)

This is the location id as used to get the weather for the location.

=item dnam (descriptive name)

This is a name describing the location, e.g. I<Heidelberg, Germany>.

=item tm (time)

This is the current local time of the location (if not using cached data).

Time is always presented like I<8:45 AM> or I<11:33 PM>.

=item zone (timezone)

This is the timezone. It is presented as time offset from GMT.

=item suns (time of sunset)

=item sunr (time of sunrise)

=item lat (latitude)

The latitude is presented as 2 digit decimal.

=item lon (longitude)

The longitude is presented as 2 digit decimal.

=back

=head3 Current Conditions Block

The hashref I<cc> contains information about the current conditions.

=over 4

=item icon

The SDK from I<weather.com> contains a set of weather icons. These icons
have filenames like I<28.png>. This element is this icon number.

=item flik (windchill)

This is the temperature considering the windchill factor.

=item obst (observatory)

The observatory that reported the weather data.

=item lsup (last updated)

Date and time when the weather data has been reported. Format is 
I<8/16/04 6:10 AM EDT>. In some cases (e.g. for Heidelberg in Germany)
there may be no official timezone identifier but the keyword I<Local>
or I<Local Time>.

=item tmp (temperature)

=item hmid (humidity)

=item wind

=over 8

=item gust

Maximum gust speed.

=item d

Wind direction in degrees.

=item t

Text description of direction.

=item s

Wind speed

=back

=item bar (air pressure)

=over 8

=item r (pressure)

Decimal current pressure.

=item d (description)

Text description of raise or fall of pressure.

=back

=item dewp

Integer dew point.

=item uv (uv index data)

=over 8

=item i

Integer index value.

=item t

Text description of value.

=back

=item vis (decimal visibility)

=item t

Text description of condition.

=back

=head3 Forecasts

Up to 10 days of forecasts can be found in the hashref I<dayf>. 

=over 4

=item lsup (last updated)

self explanatory

=item day

I<day> contains either a hash containing the forecast for one day or
it contains an an array of hashes, one for each day.

=over 8

=item dt (date)

The date of the forecasted day. Only name of month and day, e.g. I<Aug 16>.

=item d (number of the day)

=item t (name of the day)

e.g. I<Monday>

=item hi (highest temperature)

=item low (lowest temperature)

=item suns (time of sunset)

=item sunr (time of sunrise)

=item part (block of day part data)

There are always to blocks of day part data. One for the the night and
one for the day.

=over 12

=item hmid (humidity)

=item wind (see current conditions block)

=item icon (see current conditions block)

=item p (part of day)

Maybe I<d> for I<day> or I<n> for I<night>.

=item ppcp (percent chance of precipitation)

=item t (description of conditions)

=back                 

=back

=back

=head3 Links

The hashref I<lnks> contains some links to other weather information that may
be interesting for the chosen location. This will not be explained in further
detail here. Just play around with the sample...

=head1 SEE ALSO

See also L<Weather::Com::Cached> for the cached version of
the low level API.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (http://www.weather.com/services/xmloap.html)!

=cut
