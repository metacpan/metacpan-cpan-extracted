package Mojolicious::Plugin::GeoCoder;

use strict;
use warnings FATAL => 'all';
use Mojo::Base 'Mojolicious::Plugin';
use Geo::Coder::Google;

our $VERSION = '0.05';

sub register {
    my ($self,$app,$rh_conf) = @_;
    $app->helper(geocode => sub {
        my ($self,$rh_args) = @_;
        
        return { } unless($rh_args->{location});

        my $geocoder = Geo::Coder::Google->new(
                apiver      => 3,
                ( $rh_args->{country_code} || $rh_conf->{country_code} ?
                    (gl     => $rh_args->{country_code} || $rh_conf->{country_code}) : ()),
                language    => $rh_args->{language_code} || $rh_conf->{language_code}  || 'en',
                );

        my $rh_response = $geocoder->geocode(location=> $rh_args->{location});

        return $rh_response if($rh_conf->{raw_response} || $rh_conf->{raw_response});

        return {
                address => $rh_response->{formatted_address},
                lat     => $rh_response->{geometry}{location}{lat},
                lng     => $rh_response->{geometry}{location}{lng},
            };
    });

    $app->helper(reverse_geocode=> sub {
        my ($self,$rh_args) =@_;

        return { } unless($rh_args->{latlng});

        my $geocoder = Geo::Coder::Google->new(
                apiver      => 3,
                ( $rh_args->{country_code} || $rh_conf->{country_code} ?
                    (gl     => $rh_args->{country_code} || $rh_conf->{country_code}) : ()),
                language    => $rh_args->{language_code} || $rh_conf->{language_code}  || 'en',
        );
        my $rh_response = $geocoder->reverse_geocode(latlng => $rh_args->{latlng});

        return $rh_response if($rh_conf->{raw_response} || $rh_conf->{raw_response});

        return {
                address => $rh_response->{formatted_address},
                lat     => $rh_response->{geometry}{location}{lat},
                lng     => $rh_response->{geometry}{location}{lng},
            }
    });
}
=head1 GeoCoder

Mojolicious::Plugin::GeoCoder - Plugin for geocoding and reverse geocoding features!

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS


    #Mojolicious lite

    plugin 'GeoCoder' => { language_code=> 'es' }; #by default language code 'en'

    #or you could do

    my $rh_conf = {
            language_code   => 'en',
            encoding        => 'latin1' #by default its utf-8
        };

    plugin 'GeoCoder' => $rh_conf;

    #in controller
    my $rh_location = $self->geocode({location=> 'London'});

    my $rh_location = $self->reverse_geocode({latlng=> '18.234686,73.446444'});

    #to get raw response from geocoder
    my $rh_location = $self->geocode({location=> 'London',raw_response => 1 });

    #To change language to fr and country to canada only for one request
    #Now following will return London from Canada instead of real London from UK
    my $rh_location = $self->geocode({location=> 'London',language_code=>'fr',country_code => 'ca' });

    #default response 
        {
            'lat'       => '51.5073509',
            'address'   => 'London, UK',
            'lng'       => '-0.1277583'
        };
    
=cut


=head1 AUTHOR

Rohit Deshmukh, C<< <raigad1630 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to https://github.com/raigad/mojolicious-plugin-geocoder/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::GeoCoder


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Rohit Deshmukh.

=cut

1; # End of Mojolicious::Plugin::GeoCoder
