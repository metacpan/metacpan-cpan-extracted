package WWW::Weather::Yahoo;
use strict;
use warnings;
use WWW::Mechanize;
use XML::XPath;
use utf8;
#use XML::XPath::XMLParser;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.07';
    @ISA     = qw(Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    bless $self, $class;
    my $city = shift;
    my $unit = shift || 'c';    #c or f, (celcius vs farenheit)

    if ( ! $city ) {
        warn 'No city given. Usage Example: WWW::Weather::Yahoo->new( "São Paulo, SP" ) ';
        return undef;
    }

    my $mech = WWW::Mechanize->new( );
    $mech->agent_alias( 'Windows IE 6' );
    my $woeid;
    if ( $city =~ m/^(\d+)$/g ) {
        $woeid = $city; #user passed an woeid
    }
    else {
        $woeid = woeid_by_location( $city );
    }

    if ( !$woeid ) {
        warn "Nothing found. Check the city input.";
        return undef;
    }
    $self->{_woeid} = $woeid;

    my $weather_url =
      "http://weather.yahooapis.com/forecastrss?w=$woeid&u=$unit";
    my $url = $weather_url;
    $mech->get( $url );
    my $content = $mech->content;
    if ( $content =~ m/City not found/ ) {
        return undef;
    }
    $self->{_weather} = parse_content( $content, $city );

    return $self;
}

sub woeid_by_location {
    my $loc = shift;
    my $finder =
"http://query.yahooapis.com/v1/public/yql?q=select * from geo.placefinder where text =\' $loc \' ";
    my $mech = WWW::Mechanize->new();
    $mech->agent_alias('Windows IE 6');
    $mech->get($finder);
    my $xml = $mech->content;

    if ( !$xml ) {
        warn 'INVALID LOCAL';
        return undef;
    }

    my $xml_placefinder = XML::XPath->new( xml => $xml );
    return $xml_placefinder->findvalue('//woeid');
}

sub parse_content {
    my $content = shift;
    my $city    = shift;
    my $weather = {};
    $weather->{city_name} = $city;
    if ( $content =~
        m/yweather:location city="(.+)"( +)region="(.+)"( +)country="(.+)"/ )
    {
        $weather->{location_city}    = $1;
        $weather->{location_region}  = $3;
        $weather->{location_country} = $5;
    }
    if ( $content =~
m/yweather:units temperature="(.+)"( +)distance="(.+)"( +)pressure="(.+)"( +)speed="(.+)"/
      )
    {
        $weather->{unit_temperature} = $1;
        $weather->{unit_distance}    = $3;
        $weather->{unit_pressure}    = $5;
        $weather->{unit_speed}       = $7;
    }

    if ( $content =~
        m/yweather:wind chill="(.+)"( +)direction="(.+)"( +)speed="(.+)"/ )
    {
        $weather->{wind_chill}     = $1;
        $weather->{wind_direction} = $3;
        $weather->{wind_speed}     = $5;
    }
    if ( $content =~
m/yweather:atmosphere humidity="(.+)"( +)visibility="(.+)"( +)pressure="(.+)"( +)rising="(.+)"/
      )
    {
        $weather->{atmosphere_humidity}   = $1;
        $weather->{atmosphere_visibility} = $3;
        $weather->{atmosphere_pressure}   = $5;
        $weather->{atmosphere_rising}     = $7;

    }
    if ( $content =~ m/yweather:astronomy sunrise="(.+)"( +)sunset="(.+)"/ ) {
        $weather->{astronomy_sunrise} = $1;
        $weather->{astronomy_sunset}  = $3;
    }
    if ( $content =~ m/geo:lat>(.+)</ ) {
        $weather->{location_lat} = $1;
    }
    if ( $content =~ m/geo:long>(.+)<\// ) {
        $weather->{location_lng} = $1;
    }

    if ( $content =~
m/yweather:condition( +)text="(.+)"( +)code="(.+)"( +)temp="(.+)"( +)date="(.+)"/
      )
    {
        $weather->{condition_text} = $2;
        $weather->{condition_code} = $4;
        $weather->{condition_temp} = $6;
        $weather->{condition_date} = $8;
    }

    if ( $content =~ m/img src="(.+)"/ ) {
        $weather->{condition_img_src} = $1;
    }

    my $count = 1;
    while ( $content =~
m/yweather:forecast day="(.+)"( +)date="(.+)"( +)low="(.+)"( +)high="(.+)"( +)text="(.+)"( +)code="(.+)"/g
      )
    {
        if ( $count == 2 ) {
            $weather->{forecast_tomorrow_day}  = $1;
            $weather->{forecast_tomorrow_date} = $3;
            $weather->{forecast_tomorrow_low}  = $5;
            $weather->{forecast_tomorrow_high} = $7;
            $weather->{forecast_tomorrow_text} = $9;
            $weather->{forecast_tomorrow_code} = $11;
        }
        $count++;
    }
    return $weather;
}

=head1 NAME

    WWW::Weather::Yahoo - Gets information from yahoo weather.

=head1 SYNOPSIS

    use WWW::Weather::Yahoo;
    my $yw = WWW::Weather::Yahoo->new( 'São Paulo, SP', 'c' );#by city name
    my $yw = WWW::Weather::Yahoo->new( 'São Paulo, SP', 'f' );#by city name
    my $yw = WWW::Weather::Yahoo->new( 455827 , 'c' );        #by woeid
    print $yw->{ _weather }{location_city};
    print $yw->{ _weather }{location_region};       
    print $yw->{ _weather }{location_country};
    print $yw->{ _weather }{unit_temperature};
    print $yw->{ _weather }{unit_distance};
    print $yw->{ _weather }{unit_pressure};
    print $yw->{ _weather }{unit_speed};
    print $yw->{ _weather }{wind_chill};
    print $yw->{ _weather }{wind_direction};
    print $yw->{ _weather }{wind_speed};
    print $yw->{ _weather }{atmosphere_humidity};
    print $yw->{ _weather }{atmosphere_visibility};
    print $yw->{ _weather }{atmosphere_pressure};
    print $yw->{ _weather }{atmosphere_rising};
    print $yw->{ _weather }{astronomy_sunrise};
    print $yw->{ _weather }{astronomy_sunset};
    print $yw->{ _weather }{location_lat};
    print $yw->{ _weather }{location_lng};
    print $yw->{ _weather }{condition_text};
    print $yw->{ _weather }{condition_code};
    print $yw->{ _weather }{condition_temp};
    print $yw->{ _weather }{condition_date};
    print $yw->{ _weather }{condition_img_src};
    print $yw->{ _weather }{forecast_tomorrow_day};
    print $yw->{ _weather }{forecast_tomorrow_date};
    print $yw->{ _weather }{forecast_tomorrow_low};
    print $yw->{ _weather }{forecast_tomorrow_high};
    print $yw->{ _weather }{forecast_tomorrow_text};
    print $yw->{ _weather }{forecast_tomorrow_code};


=head1 DESCRIPTION

    WWW::Weather::Yahoo retrieves weather data from http://weather.yahoo.com.  
    Enter the city name and get weather data.


=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    HERNAN
    hernanlopes@gmail.com

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;

# The preceding line will help the module return a true value

