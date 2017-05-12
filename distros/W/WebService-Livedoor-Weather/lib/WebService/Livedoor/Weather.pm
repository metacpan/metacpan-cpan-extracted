package WebService::Livedoor::Weather;

use strict;
use warnings;
use utf8;
use Carp;
use Encode;
use URI::Fetch;
use XML::Simple; 
use JSON 2;
our $VERSION = '0.10';

use constant BASE_URI        => $ENV{LDWEATHER_BASE_URI} || 'http://weather.livedoor.com';
use constant ENDPOINT_URI    => $ENV{LDWEATHER_ENDPOINT_URI} || BASE_URI. '/forecast/webservice/json/v1';
use constant FORECASTMAP_URI => $ENV{LDWEATHER_FORECASTMAP_URI} || BASE_URI. '/forecast/rss/primary_area.xml';

sub new {
    my ( $class, %args ) = @_;
    $args{fetch} ||= {};
    $args{fetch} = {
        %{$args{fetch}},
        UserAgent => LWP::UserAgent->new( agent => __PACKAGE__.'/'.$VERSION )
    };
    bless \%args,$class;
}

sub get {
    my ($self, $city) = @_;
    croak('city is required') unless $city;
    my $cityid = $self->__get_cityid($city);

    my $res = URI::Fetch->fetch(ENDPOINT_URI. "?city=$cityid", %{$self->{fetch}});
    croak("Cannot get weather information : " . URI::Fetch->errstr) unless $res;

    return $self->__parse_forecast($res->content);
}

sub __parse_forecast {
    my ($self, $json) = @_;
    my $ref;
    eval{$ref = decode_json($json)};
    croak('Oops! failed reading weather information : ' . $@) if $@;

    ### temperature fixing for null case
    for ( @{$ref->{forecasts}} ) {
        ref $_->{temperature}{max}{celsius} and $_->{temperature}{max}{celsius} = undef;
        ref $_->{temperature}{min}{celsius} and $_->{temperature}{min}{celsius} = undef;
        ref $_->{temperature}{max}{fahrenheit} and $_->{temperature}{max}{fahrenheit} = undef;
        ref $_->{temperature}{min}{fahrenheit} and $_->{temperature}{min}{fahrenheit} = undef;
    }

    return $ref;
}

sub __get_cityid {
    my ($self,$city) = @_;
    $city =~ /^\d+$/ ? $city : $self->__forecastmap->{$city} or croak('Invalid city name. cannot find city id with '. $city);
}

sub __forecastmap {
    my $self = shift;
    unless ($self->{forecastmap}) {
        my $res = URI::Fetch->fetch(FORECASTMAP_URI, %{$self->{fetch}});
        croak("Couldn't get forecastmap: " . URI::Fetch->errstr) unless $res;
        $self->{forecastmap} = $self->__parse_forecastmap($res->content);
    }
    return $self->{forecastmap};
}

sub __parse_forecastmap {
    my ($self, $str) = @_;

    my $ref = eval { 
        local $XML::Simple::PREFERRED_PARSER = 'XML::Parser';
        XMLin($str, ForceArray => [qw[pref area city]]);
    };
    if ($@) {
        local $Carp::CarpLevel = 1;
        croak('Oops! failed reading forecastmap: '. $@);
    }
    my %forecastmap;
    foreach my $pref ( @{$ref->{channel}{'ldWeather:source'}{pref}} ){
        $forecastmap{$pref->{city}{$_}{title}} = $_ for keys %{$pref->{city}};
    }
    return \%forecastmap;
}

1;
__END__

=encoding utf8

=head1 NAME

WebService::Livedoor::Weather - Perl interface to Livedoor Weather Web Service

=head1 SYNOPSIS

  use strict;
  use utf8;
  use WebService::Livedoor::Weather;

  binmode STDOUT, ':utf8';

  my $lwws = WebService::Livedoor::Weather->new;

  my $ret = $lwws->get('東京'); # forecast data for Tokyo.
  ### or ...
  $ret = $lwws->get('130010'); # '130010' is Tokyo's city_id.

  printf "%s\n---\n%s\n", $ret->{title}, $ret->{description}{text};

=head1 DESCRIPTION

WebService::Livedoor::Weather is a simple interface to Livedoor Weather Web Service (LWWS)

=head1 METHODS

=over

=item new

    $lwws = WebService::Livedoor::Weather->new;
    $lwws = WebService::Livedoor::Weather->new(fetch=>{
        Cache=>$c
    });

creates an instance of WebService::Livedoor::Weather.

C<fetch> is option for URI::Fetch that used for fetching weather information.

=item get(cityid or name)

    my $ret = $lwws->get('63'); #63 is tokyo
    my $ret = $lwws->get('cityname');

retrieve weather.
You can get a city id from http://weather.livedoor.com/forecast/rss/primary_area.xml

=back

=head1 SEE ALSO

L<URI::Fetch>
http://weather.livedoor.com/weather_hacks/webservice.html (Japanese)

=head1 AUTHOR

Original version by Masahiro Nagano, E<lt>kazeburo@nomadscafe.jpE<gt>

Latest version by Satoshi Azuma, E<lt>ytnobody@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
