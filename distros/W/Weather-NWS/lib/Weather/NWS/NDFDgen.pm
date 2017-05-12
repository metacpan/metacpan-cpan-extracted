package Weather::NWS::NDFDgen;

use warnings;
use strict;

use LWP::Simple;
use SOAP::DateTime;

use Readonly;

use Class::Std;

=pod 

=head1 NAME

Weather::NWS::NDFDgen - Object interface to the NWS NDFDgen Web Service.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=pod

=head1 SYNOPSIS

    use Weather::NWS::NDFDgen;

    my $NDFDgen = Weather::NWS::NDFDgen->new();

    my $NDFDgen = Weather::NWS::NDFDgen->new(
        'Product' => 'Time-Series',
        'Latitude' => 42,
        'Longitude' => -88,
        'Weather Parameters' => {
            'Maximum Temperature' => 1,
            'Minimum Temperature' => 0,
        },
    );
    
    my $latitude = 42;
    $NDFDgen->set_latitude($latitude);
    $latitude = $NDFDgen->get_latitude();
    
    my $longitude = -88;
    $NDFDgen->set_longitude($longitude);
    $longitude = $NDFDgen->get_longitude();   

    my $product = 'Time-Series';
    $NDFDgen->set_product($product);
    $product = $NDFDgen->get_product();
    
    my $start_time = scalar localtime;
    $NDFDgen->set_start_time($start_time);
    $start_time = $NDFDgen->get_start_time();
    
    my $end_time = scalar localtime;
    $NDFDgen->set_end_time($end_time);
    $end_time = $NDFDgen->get_end_time();
    
    $NDFDgen->set_weather_parameters(
        'Maximum Temperature' => 1,
        'Minimum Temperature' => 0,
    );
    my @weather_parameters = $NDFDgen->get_weather_parameters(
        'Maximum Temperature', 
        'Minimum Temperature',
    );
    
    my $xml = $NDFDgen->get_forecast_xml();
    
    my $xml = $NDFDgen->get_forecast_xml(
        'Product' => 'Time-Series',
        'Latitude' => 42,
        'Longitude' => -88,
        'Weather Parameters' => {
            'Maximum Temperature' => 1,
            'Minimum Temperature' => 0,
        },
    );

    my @products = $NDFDgen->get_available_products();
    
    my @weather_parameters = $NDFDgen->get_available_weather_parameters();
        
=cut

=pod

=head1 NDFDgen

The NDFDgen web service is provided by the National Weather Service as part
of their National Digital Forecast Database.  Official NWS documentation for 
the XML web service can be found at 
L<http://www.weather.gov/forecasts/xml/SOAP_server/ndfdXMLserver.php>.

The service allows for users to request custom weather forecasts based on
the following parameters.

=head2 Latitude

The latitude of the point for which you want NDFD data.  For Northern 
latituded, this will be a positive decimal value, such as 42.011.

=head2 Longitude

The longitude of the point for which you want NDFD data.  For Western
longitudes, this will be a negative decimal value, such as -88.81.
 
=head2 Product

There are two products presented by NDFDgen.  These are the time-series and
glance products.  The time-series product returns all data between the start 
and end times for the selected weather parameters.  The glance product returns 
all data between the start and end times for maximum temperature, minimum
temperature, cloud cover, weather and weather icons elements.

For this object, 'Time-Series' and 'Glance' are used to identify the products.

=head2 Start Time

The beginning time for which you want NDFD data.  The format for this date is 
and XSD DateTime, which is represented like '2004-01-01T00:00:00'.  You can 
really pass almost any date format in as the start time though because the
date is passed through L<SOAP::DateTime> before use.

=head2 End Time

The ending time for which you want NDFD data.  The format for this date is 
and XSD DateTime, which is represented like '2004-01-01T00:00:00'.  You can 
really pass almost any date format in as the end time though because the
date is passed through L<SOAP::DateTime> before use.

=head2 Weather Parameters

You can request any set of multiple weather parameters.  These parameters
are listed below.  The definitions are taken from the NWS at
L<http://www.nws.noaa.gov/ndfd/definitions.htm>.

=head3 Maximum Temperature

Maximum temperature is the daytime max or the overnight min temperature. 
Verifying observations are deduced via a comprehensive algorithm that examines 
reported max/min and hourly temperatures. Daytime is defined as 0700-1900 Local 
Standard Time, and overnight as 1900-0800 Local Standard Time.

=head3 Minimum Temperature

Minimum temperature is the daytime max or the overnight min temperature. 
Verifying observations are deduced via a comprehensive algorithm that examines 
reported max/min and hourly temperatures. Daytime is defined as 0700-1900 Local 
Standard Time, and overnight as 1900-0800 Local Standard Time.

=head3 3 Hourly Temperature

3 Hourly temperature is the expected temperature valid for the indicated hour.

=head3 Dewpoint Temperature

Dewpoint temperature is the expected dew point temperature for the indicated 
hour.

=head3 Apparent Temperature

Apparent temperature is the perceived temperature derived from either a 
combination of temperature and wind (Wind Chill), or temperature and humidity 
(Heat Index) for the indicated hour. Apparent temperature grids will signify 
the Wind Chill when temperatures fall to 50 °F or less, and the Heat Index 
when temperatures rise above 80 °F.  Between 51 and 80 °F the Apparent 
Temperature grids will be populated by the ambient air temperature.

=head3 12 Hour Probability of Precipitation

12 hour probability of precipitation is defined as the likelihood, expressed as 
a percent, of a measurable precipitation event (1/100th of an inch or more ) 
during the 12-hour valid period. The 12-hour periods begin and end at 0000 and 
1200 UTC.

=head3 Liquid Precipitation Amount

Liquid precipitation amount is the total amount of expected liquid 
precipitation during a 6-hour period. The 6-hour periods begin and end at 
0600, 1200, 1800, and 0000 UTC.

=head3 Cloud Cover Amount

Cloud cover amount is the expected amount of all opaque clouds (in percent) 
covering the sky for the indicated hour.

=head3 Snowfall Amount

Snowfall amount is the expected total accumulation of new snow during a 6-hour 
period. The 6-hour periods begin and end at 0600, 1200, 1800, and 0000 UTC.

=head3 Wind Speed

Wind speed is the expected sustained 10 meter wind speed for the indicated hour.

=head3 Wind Direction

Wind direction is the expected sustained 10 meter wind direction for the 
indicated hour, using 36 points of a compass.

=head3 Weather

Weather is the expected weather (precipitating or non-precipitating) valid at 
the indicated hour. Precipitating weather includes type, probability, and 
intensity information. In cases of convective weather, coverage may be 
substituted for probability.

=head3 Wave Height

Wave height (significant) is the average height (trough to crest) of the 
one-third highest waves for the indicated 12-hour period. The 12-hour periods 
begin and end at 0000 and 1200 UTC.

=head3 Weather Icons

Weather icons are links to images from the NWS that illustrate weather 
conditions at specific time points.

=head3 Relative Humidity

Relative humidity is the expected Relative Humidity (RH) for the indicated hour.  
RH is derived from the associated Temperature and Dew Point grids for the 
indicated hour.

=cut

Readonly my $SERVICE =>
  'http://www.weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl';

Readonly my %NAME_TO_ARGUMENT => (
    'Latitude'           => 'latitude',
    'Longitude'          => 'longitude',
    'Product'            => 'product',
    'Start Time'         => 'startTime',
    'End Time'           => 'endTime',
    'Weather Parameters' => 'weatherParameters',
);
Readonly my @ARGUMENTS => keys %NAME_TO_ARGUMENT;

Readonly my %NAME_TO_PRODUCT => (
    'Time-Series' => 'time-series',
    'Glance'      => 'glance',
);
Readonly my @PRODUCTS => keys %NAME_TO_PRODUCT;

Readonly my %NAME_TO_WEATHER_PARAMETER => (
    'Maximum Temperature'                  => 'maxt',
    'Minimum Temperature'                  => 'mint',
    '3 Hourly Temperature'                 => 'temp',
    'Dewpoint Temperature'                 => 'dew',
    'Apparent Temperature'                 => 'appt',
    '12 Hour Probability of Precipitation' => 'pop12',
    'Liquid Precipitation Amount'          => 'qpf',
    'Cloud Cover Amount'                   => 'sky',
    'Snowfall Amount'                      => 'snow',
    'Wind Speed'                           => 'wspd',
    'Wind Direction'                       => 'wdir',
    'Weather'                              => 'wx',
    'Wave Height'                          => 'waveh',
    'Weather Icons'                        => 'icons',
    'Relative Humidity'                    => 'rh',
);
Readonly my @WEATHER_PARAMETERS => keys %NAME_TO_WEATHER_PARAMETER;

Readonly my $DEFAULT_PRODUCT    => 'Time-Series';
Readonly my $DEFAULT_START_TIME => ConvertDate( scalar localtime );

=pod

=head1 METHODS

=cut

{
    my %forecaster : ATTR;
    my %forecast_xml : ATTR;
    my %default_latitude : ATTR;
    my %default_longitude : ATTR;
    my %default_product : ATTR;
    my %default_start_time : ATTR;
    my %default_end_time : ATTR;
    my %default_weather_parms : ATTR;

=pod

=head2 BUILD (new)

Constructor for new NDFDgen objects.  If called with no parameters, it will
return a new object initialized with the 'Time-Series' product and the
current time as the start time.  All other parameters are left unintialized.
Values can be provided for 'Latitude', 'Longitude', 'Product', 'Start Time',
'End Time', and 'Weather Parameters'.

=cut

    sub BUILD {
        my ( $self, $ident, $arg_ref ) = @_;

        my %args = %{$arg_ref};

        map { $default_weather_parms{$ident}{$_} = 0 } @WEATHER_PARAMETERS;

        $self->set_latitude( $args{'Latitude'}     || undef );
        $self->set_longitude( $args{'Longitude'}   || undef );
        $self->set_product( $args{'Product'}       || $DEFAULT_PRODUCT );
        $self->set_start_time( $args{'Start Time'} || $DEFAULT_START_TIME );
        $self->set_end_time( $args{'End Time'}     || undef );

        if ( $args{'Weather Parameters'} and ref $args{'Weather Parameters'} ) {
            $self->set_weather_parameters( %{ $args{'Weather Parameters'} } );
        }
    }

=pod

=head2 set_latitude

Sets the latitude for the object.  This is a decimal value.

=cut

    sub set_latitude {
        my ( $self, $new_latitude ) = @_;
        return $default_latitude{ ident $self} = $new_latitude;
    }

=pod

=head2 get_latitude

Returns the latitude stored in the object.

=cut

    sub get_latitude {
        my ($self) = @_;
        return $default_latitude{ ident $self};
    }

=pod

=head2 set_longitude

Sets the longitude for the object.  This is a decimal value.

=cut

    sub set_longitude {
        my ( $self, $new_longitude ) = @_;
        return $default_longitude{ ident $self} = $new_longitude;
    }

=pod

=head2 get_longitude

Returns the longitude stored in the object.

=cut

    sub get_longitude {
        my ($self) = @_;
        return $default_longitude{ ident $self};
    }

=pod

=head2 set_product

Sets the product for the object.  This is either 'Time-Series' or 'Glance'.

=cut

    sub set_product {
        my ( $self, $new_product ) = @_;

        die("Invalid product ($new_product)")
          unless ( grep { /^${new_product}$/ } @PRODUCTS );

        return $default_product{ ident $self} = $new_product;
    }

=pod

=head2 get_product

Returns the product stored in the object.

=cut

    sub get_product {
        my ($self) = @_;
        return $default_product{ ident $self};
    }

=pod

=head2 set_start_time

Sets the start time for the object.

=cut

    sub set_start_time {
        my ( $self, $new_start_time ) = @_;

        return unless $new_start_time;

        return $default_start_time{ ident $self} = ConvertDate($new_start_time);
    }

=pod

=head2 get_start_time

Gets the start time stored in the object.

=cut

    sub get_start_time {
        my ($self) = @_;
        return $default_start_time{ ident $self};
    }

=pod

=head2 set_end_time

Sets the end time for the object.

=cut

    sub set_end_time {
        my ( $self, $new_end_time ) = @_;

        return unless $new_end_time;

        return $default_end_time{ ident $self} = ConvertDate($new_end_time);
    }

=pod

=head2 get_end_time

Gets the end time stored in the object.

=cut

    sub get_end_time {
        my ($self) = @_;
        return $default_end_time{ ident $self};
    }

=pod

=head2 set_weather_parameters

Sets the weather parameters for the object.  These parameters are passed in
as a list of key-value pairs where the key is the weather parameter and the
value is a 1 or 0 indicating wether or not the parameter is going to be
requested or not.

=cut

    sub set_weather_parameters {
        my ( $self, @params ) = @_;

        return unless @params;
        return unless $#params % 2;

        my %params = @params;

        while ( my ( $parameter, $value ) = each %params ) {
            die("Invalid weather parameter ($parameter)")
              unless ( grep { /^$parameter$/ } @WEATHER_PARAMETERS );

            die("Invalid value ($value) for weather parameter ($parameter)")
              unless ( $value =~ /^[01]$/ );
        }

        my $stored_params = $default_weather_parms{ ident $self};

        while ( my ( $parameter, $value ) = each %params ) {
            $stored_params->{$parameter} = $value;
        }
        return @params;
    }

=pod

=head2 get_weather_parameters

Returns the requested weather parameters stored in the object as key-value
pairs where the key is the weather parameter and the value is a 1 or 0 
indicating wether or not the parameter is going to be requested or not.

A list of parameter names can be passed to this method so that only those 
parameters are returned.  If no arguments are passed to this method, all 
parameters will be returned.

=cut

    sub get_weather_parameters {
        my ( $self, @params ) = @_;

        my $stored_params = $default_weather_parms{ ident $self};

        return %{$stored_params} unless @params;

        my @results;

        for my $parameter (@params) {
            die("Invalid weather parameter ($parameter)")
              unless ( grep { /^$parameter$/ } @WEATHER_PARAMETERS );

            push @results, $parameter, $stored_params->{$parameter};
        }

        return @results;
    }

=pod

=head2 get_available_products

Return a list of all products available through this service.

=cut

    sub get_available_products {
        my ($self) = @_;
        return @PRODUCTS;
    }

=pod

=head2 get_available_weather_parameters

Return a list of all weather parameters that can be requested through this
service.

=cut

    sub get_available_weather_parameters {
        my ($self) = @_;
        return @WEATHER_PARAMETERS;
    }

=pod

=head2 get_forecast_xml

Return the NWS NDFD XML as described in 
L<http://products.weather.gov/PDD/Extensible_Markup_Language.pdf>.  The data
returned depends on the state of the NDFDgen object at the time of the call
to this method.  Any parameters can be overridden by being passed in as 
arguments to this method.

=cut

    sub get_forecast_xml {
        my ( $self, %args ) = @_;

        my ($ident) = ident $self;

        my (
            $latitude,   $longitude, $product,
            $start_time, $end_time,  %weather_params
        );

        die("Latitude required")
          unless $latitude = $args{'Latitude'} || $default_latitude{$ident};

        die("Longitude required")
          unless $longitude = $args{'Longitude'} || $default_longitude{$ident};

        die("Product required")
          unless $product = $args{'Product'} || $default_product{$ident};

        die("Start time required")
          unless $start_time = $args{'Start Time'}
              || $default_start_time{$ident};

        die("End time required")
          unless $end_time = $args{'End Time'} || $default_end_time{$ident};

        %weather_params = %{ $default_weather_parms{$ident} };
        if ( exists $args{'Weather Parameters'} ) {
            while ( my ( $param, $value ) =
                each %{ $args{'Weather Parameters'} } )
            {
                die("Invalid weather parameter ($param) found")
                  unless exists $weather_params{$param};
                $weather_params{$param} = $value;
            }
        }

        my $url =
'http://www.weather.gov/forecasts/xml/sample_products/browser_interface/ndfdXMLclient.php?';

        $url .= '&lat=' . $latitude;
        $url .= '&lon=' . $longitude;
        $url .= '&product=' . $NAME_TO_PRODUCT{$product};
        $url .= '&begin=' . $start_time if $start_time;
        $url .= '&end=' . $end_time if $end_time;

        for my $param ( keys %weather_params ) {
            if ( $weather_params{$param} ) {
                $url .= '&'
                  . $NAME_TO_WEATHER_PARAMETER{$param} . '='
                  . $NAME_TO_WEATHER_PARAMETER{$param};
            }
        }

        $forecast_xml{$ident} = get $url;

        return $forecast_xml{$ident};
    }

}

=pod

=head1 AUTHOR

Josh McAdams, C<< <josh dot mcadams at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-weather-nws-ndfdgen at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-NWS-NDFDgen>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Weather::NWS::NDFDgen

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Weather-NWS-NDFDgen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Weather-NWS-NDFDgen>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-NWS-NDFDgen>

=item * Search CPAN

L<http://search.cpan.org/dist/Weather-NWS-NDFDgen>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Josh McAdams, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Weather::NWS::NDFDgen
