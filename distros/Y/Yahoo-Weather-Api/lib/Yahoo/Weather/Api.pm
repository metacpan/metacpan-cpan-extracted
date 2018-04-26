package Yahoo::Weather::Api;

use 5.006;
use strict;
use warnings;

=head1 NAME

Yahoo::Weather::Api - The great new 2018 Yahoo::Weather::Api 

=head1 VERSION

Version 1.10

=cut
our $VERSION = '1.10';

use URL::Builder qw (build_url);
use Carp;
use LWP::UserAgent;

=head1 SYNOPSIS

Yahoo::Weather::Api fetches the Weather information as provided by the Yahoo's weather API.

B<Access is limited to 2,000 signed calls per day>

Refer more here L<https://developer.yahoo.com/weather/>

    use Yahoo::Weather::Api;

    my $api = Yahoo::Weather::Api->new();
    print  $api->get_weather_data({ 'search' => 'Palo Alto, CA, US' });

                            or

    use Yahoo::Weather::Api;

    my $api = Yahoo::Weather::Api->new({ 'unit' => 'F', 'format' => 'xml'});
    print  $api->get_weather_data_by_geo({'long' => '74.932999', 'lat' => '31.7276', 'only'=>1});

=head1 SUBROUTINES/METHODS

new()

get_weather_data()

get_weather_data_by_geo()

get_woeid()

get_woeid_alternate()


=cut

use constant {
    WOEID_BASE      => 'https://www.yahoo.com/news/_td/api/resource/WeatherSearch;text=',
    WOEID_QUERY     => 'SELECT woeid FROM geo.places WHERE text=',
    YQL_BASE        => 'https://query.yahooapis.com',
    YQL_PUBLIC      => '/v1/public/yql',
    YQL_QUERY       => 'select * from weather.forecast where woeid in (SELECT woeid FROM geo.places(1) WHERE text=',
    YQL_QUERY_ALL   => 'select * from weather.forecast where woeid in (SELECT woeid FROM geo.places WHERE text=',
    WOEID_QUERY     => 'SELECT woeid FROM geo.places WHERE text=',
    WOEID_QUERY_ALL => 'SELECT * FROM geo.places WHERE text=',
};

my $ua = LWP::UserAgent->new();

=head2 new

constructor for the class  Yahoo::Weather::Api

hash ref of options supported B<(OPTIONAL)>.

    my $api = Yahoo::Weather::Api->new({ 'unit' => 'F', 'format' => 'xml'});

B<unit> can be either celcius B<c> or farenheit  B<f>
Default is B<c>

    my $api = Yahoo::Weather::Api->new({ 'unit' => 'F'});
    my $api = Yahoo::Weather::Api->new({ 'unit' => 'C'});

B<Format> return data type from api JSON B<json> or XML B<xml> 
Default is B<json>

    my $api = Yahoo::Weather::Api->new({ 'format' => 'xml' , 'unit' => 'F'});

=cut

sub new {
    my ($class, $args) = (@_);
    bless(my $self = {}, $class);

    $self->_validate_set_args ($args);
    $self->{_ua} = $ua;

    croak 'Unable to connect to internet' unless ($ua->is_online);
    return $self;
}

=head2 get_weather_data

Fetch data for a place using (zip, city name)

Need search parameter eg. { search => '<STRING>' }

Mandatory param hashref B<search> => '<SEARCH_STRING>' 

Needless to say, enclose within single quotes

B<Optional Param only> {'only' => 1 } will return only best matching result as per the Yahoo api

B<Default is 0> i.e B<{'only' => 0}> sub will return all the results fetched.

B<will return all the results from API>

     $api->get_weather_data({ 'search' => 'Palo Alto, CA, US' });

or 

B<will return all the results from API>

     $api->get_weather_data({ 'search' => '555512' });

or

B<will return only best matching single result from API>

     $api->get_weather_data({ 'search' => '555512' ,'only' => 1 ,});

=cut

sub get_weather_data {
    my ($self , $args) = (@_);

    croak  "Need search parameter eg. { search => '<STRING>' } " unless ($args->{search});
    my $url = $self->_generate_endpoint($args);

    return $self->_get_data($url);
}


=head2 get_weather_data_by_geo

Fetch data for a place using (geolocation by  latitude and longitude)

Need search parameter eg. { lat => '<latitude>', long => 'longitude' }

Mandatory param hashref B<lat> => '<latitude>'  and B<long> => '<longitude>'

B<Optional Param only> {'only' => 1 } will return only best matching result as per the Yahoo api

B<Default is 0> i.e {B<'only' => 0>} sub will return all the results fetched.

B<will return all the results from API>

     $api->get_weather_data_by_geo({'long' => '74.932999','lat' => '31.7276',});

or

B<will return only best matching single result from API>

     $api->get_weather_data_by_geo({'long' => '74.932999','lat' => '31.7276','only' => 1 ,});

B<NOTE> method do not support 'search' parameter

=cut
sub get_weather_data_by_geo {
    my ($self , $args) = (@_);
    croak "need lat and long { lat => 'XX', long=>'YY' } " unless ($args->{lat} || $args->{long});

    if (defined $args->{lat} && defined $args->{long}) {
        #let the YAHOO api handle the rest of the cases
        croak "Invalid value format for latitude "  if ($args->{lat} =~ /[a-zA-z]/i);
        croak "Invalid value format for latitude "  if ($args->{long} =~ /[a-zA-z]/i);
    }

    my $url = $self->_generate_endpoint($args);
    return $self->_get_data($url);
}

=head2 get_woeid

Fetch woeid for a place using (geolocation by latitude-longitude, zip, city/location name)

Yahoo has given a unique id for all the places present in their Database

this method will help to fetch the woeid related data via API

Need search parameter eg. { lat => '<latitude>', long => 'longitude' }

Mandatory param hashref B<lat> => '<latitude>'  and B<long> => '<longitude>'

B<Optional Param only> {'only' => 1 } will return only best matching result as per the Yahoo api

B<Default is 0> i.e {B<'only' => 0>} sub will return all the results fetched.

B<will return all the results from API>

     $api->get_woeid({ 'search' => 'Palo Alto, CA, US' });

or 

B<will return all the results from API>

     $api->get_woeid({'long' => '74.932999','lat' => '31.7276',});

or

B<will return only best matching single result from API>

     $api->get_woeid({'long' => '74.932999','lat' => '31.7276','only' => 1 ,});

=cut

sub get_woeid {
    my ($self , $args) = (@_);
    my $url = $self->_generate_woeid_url($args);
    return $self->_get_data($url);
}

=head2 get_woeid_alternate

Fetch woeid for a place using alternate method (zip,city/location name) B<Stricty JSON return type data>

get_woeid_alternate uses unexposed Yahoo's api so no API call caping

this method will help to fetch the woied related data via API

This implementation is purely experimental.

B<Only Mandatory 'search' parameter>

I<lati,longi,unit,only.format not supported>

     $api->get_woeid_alternate({'search '=> '<STRING>'});

=cut

sub get_woeid_alternate {
    my ($self , $args) = (@_);
    croak  "Need search parameter eg. { search => '<STRING>' } " unless ($args->{search});
    $args->{alt} = 1;

    my $url = $self->_generate_woeid_url($args);
    return $self->_get_data($url);
}

sub _generate_endpoint {
    my ($self , $args) = (@_);

    $args->{only} ||= 0;

    my $part = exists $args->{lat} ? "\"($args->{lat},$args->{long})\") " : "\"$args->{search}\") " ;
    $part   .= "and u='".$self->{unit}."'";

    return build_url(
        base_uri => YQL_BASE,
        path => YQL_PUBLIC,
        query => [
        'q'      => $args->{only} ?  YQL_QUERY.$part : YQL_QUERY_ALL.$part ,
        'format' => $self->{format},
    ]);
}

sub _generate_woeid_url {
    my ($self , $args) = (@_);

    my $part = exists $args->{lat} ? "\"($args->{lat},$args->{long})\"" : "\"$args->{search}\"" ;
    $part = exists $args->{alt} ? "$args->{search}" : $part;
    #Default
    $args->{only} ||= 0;

    my $query = [
        'q'      => $args->{only} ?  WOEID_QUERY.$part : WOEID_QUERY_ALL.$part,
        'format' => $self->{format},
    ];

    my $url = build_url (
        base_uri => YQL_BASE,
        path => YQL_PUBLIC,
        query => $query,
    );
    return exists $args->{alt} ? WOEID_BASE.$part : $url;
}

sub _get_data {
    my ($self , $url) = (@_);
    my $res = $ua->get($url);

    if ($res->is_success) {
        return $res->decoded_content;
    }

    croak "Error while fetching $url \n". $res->status_line;
}

sub _validate_set_args {
    my ($self ,$args) = (@_);

    $args->{format} = $args->{format} || 'json';
    $args->{unit}  = $args->{unit} || 'c';

    croak "Invalid format use json or xml " unless ($args->{format} =~ /^(json|xml)/i);
    croak "Invalid format use c|celcius or f|farenheit " unless ($args->{unit} =~ /^(c|f)/i);

    $self->{format} = lc ($args->{format});
    $self->{unit} = uc (substr($args->{unit},0,1));

    return;
}

=head1 NOTE

the unit test will not run if no internet connection is detected.

=head1 AUTHOR

Sushrut Pajai, C<< <spajai at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yahoo-weather-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Yahoo-Weather-Api>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yahoo::Weather::Api


You can also look for information at:

=over 4

=head1 ACK

Module internally uses following module

Thanks to the creator of these modules

URL::Builder L<http://search.cpan.org/~tokuhirom/URL-Builder-0.06/lib/URL/Builder.pm>

LWP::UserAgent L<http://search.cpan.org/~oalders/libwww-perl-6.33/lib/LWP/UserAgent.pm>

=item * Git Hub repo 

L<https://github.com/spajai/Yahoo-Weather-Api>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Yahoo-Weather-Api>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Yahoo-Weather-Api>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Yahoo-Weather-Api>

=item * Search CPAN

L<http://search.cpan.org/dist/Yahoo-Weather-Api/>

=back


=head1 YAHOO's API USAGE Agreement 

Rate Limits
Use of the Yahoo Weather API should not exceed reasonable request volume. Access is limited to 2,000 signed calls per day.

Terms of Use
The above feeds are provided free of charge for use by individuals and non-profit organizations for personal, non-commercial uses.
We reserve all rights in and to the Yahoo logo, and your right to use the Yahoo logo is limited to providing attribution in connection with these RSS feeds.
Yahoo also reserves the right to require you to cease distributing these feeds at any time for any reason. Usage of these feeds is subject to YDN terms of use.
Your use of weather feeds is subject to the Yahoo APIs Terms of Use.


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Sushrut Pajai.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Yahoo::Weather::Api