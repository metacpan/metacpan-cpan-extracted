package Yahoo::Weather;

use 5.008008;
use strict;
use warnings;
use Carp;
use LWP::Simple qw/get/;
use XML::Simple;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our $xs=XML::Simple->new();
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Yahoo::Weather ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

use constant YAHOOWAPI => 'http://weather.yahooapis.com/forecastrss?';
use constant YAHOOYDN => 'http://query.yahooapis.com/v1/public/yql?q=';
use constant LOCATION_EMPTY => -1;
use constant INVALID_LOCATION=> -2;
use constant INVALID_ZIP=> -2;
use constant ZIP_EMPTY=> -1;
use constant WEATHER_FORECAST_NOT_AVAILABLE => -3;
use constant INVALID_KEYWORD => -4;
use constant SUGESTIONS_NOT_AVAILABLE => -4;


sub new {
  my $class=shift;
  my $self = {};
  bless ($self,$class);
  return $self;
}

sub getWeatherByLocation {

    my $self = shift;
    my $loc  = shift;
    my $degree  = shift;
 
    if (! $loc) {
        return LOCATION_EMPTY ;
    }

    my $woeid= $self->_getWoeidByLoc($loc);

    if (! $woeid) {
        return INVALID_LOCATION;
    }

    my $xml = get( $self->_getLocationURL($woeid,$degree) );

    my $w = $xs->xml_in($xml) or return WEATHER_FORECAST_NOT_AVAILABLE;

    my $detailedweather=$self->_parseWeatherXML($w);
    return $detailedweather;
}



sub _getLocationURL {

    my ( $self, $field ,$degree) = @_;
    my $str='u=c&w=';	

	if (lc($degree) eq 'f'){
	$str='u=f&w=';
       }
   
     my $url = YAHOOWAPI .$str.$field;
    return $url;
}

sub getWeatherByZip {
    my $self = shift;
    my $zip  = shift;
    my $degree  = shift;

    if (! $zip) {
        return ZIP_EMPTY;
    }

    my $woeid= $self->_getWoeidByZip($zip);
        
	if (! $woeid){
           return WEATHER_FORECAST_NOT_AVAILABLE
	}

    my $xml = get( $self->_getLocationURL($woeid,$degree) );
    my $w = $xs->xml_in($xml) or return WEATHER_FORECAST_NOT_AVAILABLE;
   
    my $detailedweather=$self->_parseWeatherXML($w);
    return $detailedweather;
}

sub getSugestions{
    my $self = shift;
    my $keyword = shift;

    if (! $keyword) {
        return INVALID_KEYWORD;
    }

    my $suggest= $self->_getSugestions($keyword);
	return $suggest;
}

sub _getWoeidByLoc{
    my $self = shift;
    my $loc  = shift;
    my $finder = "http://query.yahooapis.com/v1/public/yql?q=select * from geo.placefinder where text =\' $loc \' ";

	my $xml = get($finder);
	if (! $xml){
	return INVALID_LOCATION;
         }
   
    my $w = $xs->xml_in($xml) or return WEATHER_FORECAST_NOT_AVAILABLE;
    my $wwoeid=$self->_parseXmlForWoeid($w,$loc);
    return $wwoeid;

}    

sub _getSugestions{
    my $self = shift;
    my $field  = shift;
    my $finder = "http://query.yahooapis.com/v1/public/yql?q=select * from geo.placefinder where text =\' $field \' ";

        my $xml = get($finder);
        if (! $xml){
        return INVALID_KEYWORD;
         }
  
    my $w = $xs->xml_in($xml) or return SUGESTIONS_NOT_AVAILABLE;
    my $suggest=$self->_parseXmlForSuggestions($w,$field);
    return $suggest;

} 

sub _parseXmlForWoeid{
    my $self = shift;
    my $xmlref  = shift;
    my $check = shift;
    $check = lc($check);
    my $woeid;
    my $locdetailsref = $xmlref->{results}->{Result};
   if (ref($locdetailsref) eq 'HASH'){
	$woeid=$locdetailsref->{woeid};
  } 
  elsif(ref($locdetailsref) eq 'ARRAY'){
  my @arr= @$locdetailsref;
  foreach my $iter (@arr) {
  $woeid=$iter->{woeid} if((lc($iter->{uzip}) eq $check) || (lc($iter->{city}) eq $check) || (lc($iter->{neighborhood}) eq $check));
  }

  }else{
   return;
	}
  return $woeid;

}


sub _parseXmlForSuggestions{
    my $self = shift;
    my $xmlref  = shift;
    my $check = shift;
    my $locdetailsref = $xmlref->{results}->{Result};
  return $locdetailsref;
}

sub _getWoeidByZip {
    my $self = shift;
    my $zip  = shift;
    my $finder = "http://query.yahooapis.com/v1/public/yql?q=select * from geo.placefinder where text =\' $zip \' ";
         my $xml = get($finder);
  my $w = $xs->xml_in($xml) or return WEATHER_FORECAST_NOT_AVAILABLE;
  my $wwoeid=$self->_parsexmlforwoeid($w,$zip);
  return $wwoeid;

}

sub _parseWeatherXML {
    my $self = shift;
    my $xmlref  = shift;
    my $title=$xmlref->{channel}->{title};
    my $finalresult={};

   $finalresult->{LocationDetails}=$xmlref->{channel}->{'yweather:location'};
   $finalresult->{WindDetails}=$xmlref->{channel}->{'yweather:wind'};
   $finalresult->{Title}=$xmlref->{channel}->{description};
   $finalresult->{WeatherUnits}=$xmlref->{channel}->{'yweather:units'};
   $finalresult->{Atmosphere}=$xmlref->{channel}->{'yweather:atmosphere'};
   $finalresult->{LastUpdatedTime}=$xmlref->{channel}->{lastBuildDate};
   $finalresult->{Astronomy}=$xmlref->{channel}->{'yweather:astronomy'};
   $finalresult->{CurrentObservation}=$xmlref->{channel}->{item}->{'yweather:condition'};
   $finalresult->{TwoDayForecast} = $xmlref->{channel}->{item}->{'yweather:forecast'};

  return $finalresult;

}
# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is documentation for your Yahoo::Weather. 

=head1 NAME

Yahoo::Weather - Perl extension to Find Current Observation WEATHER  and Two Day Forecast for  a given Location or ZIP CODE.
		
		- This module also gives you the sugestions based on Location Name or Zip, it gives you GEOGRAPHICAL DETAILS.

=head1 SYNOPSIS

  use Yahoo::Weather;
 
  $obj=Yahoo::Weather->new();
  
  $obj->getWeatherByLocation($place);

  $obj->getWeatherByLocation($zip);

  $obj->getSugestions($zip);
  
  $obj->getSugestions($loc);

=head1 DESCRIPTION

Documentation for Yahoo::Weather. This module will get you Weather for 4.5 Million Locations (approx) but one at a time either by ZIPCODE or Place Name.

Create an Object for Yahoo::Weather.

Yahoo::Weather->new();

Get Weather Details Based on Location Name

  $obj->getWeatherByLocation($place);

Get Weather Details Based on Zip Code

  $obj->getWeatherByLocation($zip);

Get Weather Details Based on Location Name in FAH

  $obj->getWeatherByLocation($place,f);

Get Weather Details Based on Zip Code

  $obj->getWeatherByLocation($zip,F);

Default is Cel and if you need it in FARENHEIT only pass 'f' or 'F' as last parameter(second parameter) or else it defaults to Celsius.

getWeatherByLocation function needs either ZIPCODE or PLACENAME as mandate. Second Parameter is Optional. In none specified it defaults to CENTIGRADE.

Get GEOGRAPHICAL Sugestions based Zip Code or Place Name

  $obj->getSugestions($zip);
  $obj->getSugestions($loc);

Above 2 functions gives you GEO Details based on either ZIP or PLACE NAME.

getSugestions function takes only one ARG.

ALL above mentioned methods gives you a HASHREF as return value unless some thing goes wrong.

In case of exceptions, we get following

LOCATION_EMPTY = -1

INVALID_LOCATION = -2

INVALID_ZIP = -2

ZIP_EMPTY = -1

WEATHER_FORECAST_NOT_AVAILABLE = -3

INVALID_KEYWORD = -4  -For Getting Sugestions

SUGESTIONS_NOT_AVAILABLE = -4 For Getting Sugestions

=head2 EXPORT

None by default.

=head1 SEE ALSO

LWP::Simple (http://search.cpan.org/~gaas/libwww-perl-5.837/lib/LWP/Simple.pm)

XML::Simple (http://search.cpan.org/~grantm/XML-Simple-2.18/lib/XML/Simple.pm)

Please Go through YDN(http://developer.yahoo.com)  as it is built using it.

If you can't Find Weather for Particular Location , Please refer to http::/weather.yahoo.com

Weather Data Provider is Weather.com 

Weather Data Processor is YAHOO.com

This module needs to be extended further like getting temp of Today only and Forecast of NexDay only etc...When I have time I will defnetly extend it.

Please Note that curently if you give incorrect place name, this module will not give you weather Details or if that particular location(incorrect) is available in YAHOO'S 4.5 million locations it will end up giving those details. 

Also this module can't be used more than 1000 times an Hour, As it was the restriction from YDN. 

This can be overcome in next Release by adding a method to query the licenced URLS of YDN. This means that you will have to get license your self from YDN(http://developer.yahoo.com) and pass them as parametrs to subroutines.

=head1 AUTHOR

Krishna Chaitanya Averineni, E<lt>krishna_averineni@yahoo.co.inE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Krishna Chaitanya Averineni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
