#!/usr/bin/env perl

use Modern::Perl;

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use Data::Dump 'pp';
use Carp;
use URL::Encode qw/url_encode/;


my $config = {
  debug => 0,
  key => $ENV{GOOGLE_MAPS_KEY},  
  input_address  =>  url_encode($ARGV[0]) || undef,
  get_nearby_places => 0,
};

###
### VALIDATE CLI PARAMS AND ENV 
###
croak(
    'The Geo-coding API requires an API key and cannot be accessed with OAUTH keys - create a key and set $ENV{GOOGLE_MAPS_KEY} - "export GOOGLE_MAPS_KEY=<YOUR_API_KEY>'
) unless defined $ENV{GOOGLE_MAPS_KEY};

croak( "you must pass an address as a parameter") unless @ARGV>0;



=head1 geocoding_api.pl

Perform an address lookup on the CLI paassed parameter - assumes $ENV{GOOGLE_MAPS_KEY}

    perl geocoding_api.pl 'Short Street, Southport, QLD 4215 Australia'

=head2 PRE-REQUISITES


Setup a Google Project in the Google Console and add the Translate API Library. 

An API Key is required with permission to access the GeoCode API and if required the Places API.
  

=head2 OTHER RELATED PERL MODULES

=over 2

=item  L<WWW::Google::Places> 

=back


=head2 RELEVANT GOOGLE API LINKS

=over 2

=item L<https://developers.google.com/places/web-service/search>

=item L<https://console.cloud.google.com/apis/credentials>

=item L<https://developers.google.com/places/web-service/details>

=back 

=cut



####
####
####            SET UP THE CLIENT AS THE DEFAULT USER 
####
####
## assumes gapi.json configuration in working directory with scoped project and user authorization
## manunally sets the client user email to be the first in the gapi.json file
my $gapi_client = WebService::GoogleAPI::Client->new( debug => $config->{debug}, gapi_json => 'gapi.json' );
my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_client->user( $user );
say 'x' x 180;
# say $gapi_client->{ua}{credentials}{access_token};
#my $key = $gapi_client->{ua}{credentials}{access_token}; - can't use this :\

####
####
####            GEOCODE ADDRESS PASSED AS PARAMETER USING API KEY 
####            AND DISPLAY RESULT(s)
####
## https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=YOUR_API_KEY

my $ret = $gapi_client->api_query( {
                                path => 'https://maps.googleapis.com/maps/api/geocode/json',# . $key  ,
                                method => 'GET',
                                options => {
                                    key => $config->{key},
                                    address => $config->{input_address}, # '1600+Amphitheatre+Parkway,+Mountain+View,+CA'
                                 }
                            })->json;

if ( $ret->{status} eq 'OK')
{
    my $latlng = display_place_results_and_return_first_latlng( $ret->{results}  );
    get_nearby_places( $gapi_client, $latlng, 'Software' ) if ( $config->{get_nearby_places} );


}
else 
{
    say qq{REQUEST NOT OK - $ret->{status} };
}
say 'x' x 180;
exit;





############# HELPER SUBS ###############

sub display_place_results_and_return_first_latlng
{
    my ( $results ) = @_; ## expects the results list from response->{results}
    my $ret = "";
    foreach my $r ( @$results ) 
    {
        #say  Dumper $r;
        say qq{$r->{formatted_address}};
        say qq{$r->{geometry}{location}{lat} , $r->{geometry}{location}{lng} };
        $ret = "$r->{geometry}{location}{lat},$r->{geometry}{location}{lng}" unless $ret; ## set return value as string containg first lat,lng pair 
    }
  return $ret;
}

sub get_nearby_places 
{
    # https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670522,151.1957362&radius=1500&type=restaurant&keyword=cruise&key=YOUR_API_KEY
    my ( $client, $latlng, $search_term ) = @_;
    
    # place types - why so restrictive? 
    # https://developers.google.com/places/web-service/supported_types#table1

    my $resp = $client->api_query( {
                                    path => 'https://maps.googleapis.com/maps/api/place/nearbysearch/json',# . $key  ,
                                    method => 'GET',
                                    options => {
                                        key => $config->{key},
                                        location => $latlng, 
                                        keyword => $search_term,
                                        radius => 1500,
                                        type => 'establishment', #'store'
                                    }
                                });
    my $result = $resp->json;
    croak( Dumper $result ) unless $result->{status} eq 'OK';

    foreach my $place ( @{$result->{results}} )
    {
        say "\n";
        say '--------------------';
        say "Name: $place->{name}";
        say "Types: " . join(',', @{$place->{types}});
        say "Vicinity $place->{vicinity}";
        say "Location: $place->{geometry}{location}{lat} , $place->{geometry}{location}{lng}";
        say "Rating: $place->{rating}";
        say "Place ID $place->{place_id}";
        
        get_place_id_detail( $client,$place->{place_id} );
        say '--------------------';
        #croak('stop 1');
    }
}


sub get_place_id_detail
{
    my ( $client, $placeid ) = @_;
    # https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJN1t_tDeuEmsRUsoyG83frY4&fields=name,rating,formatted_phone_number&key=YOUR_API_KEY
    my $resp = $client->api_query( {
                                    path => 'https://maps.googleapis.com/maps/api/place/details/json',# . $key  ,
                                    method => 'GET',
                                    options => {
                                        placeid => $placeid,
                                        key => $config->{key}
                                    }
                                });
    my $result = $resp->json;
    croak( Dumper $result ) unless $result->{status} eq 'OK';
    #say pp $result;
    say "Website: $result->{result}{website}";
    say "Map URL: $result->{result}{url}";
    say "Phone: $result->{result}{formatted_phone_number}";

}
