package WebService::ADSBExchange;

# ABSTRACT: Interface with the ADSBExchange API

=head1 NAME 
  
WebService::ADSBExchange
  
=head1 SYNOPSIS
 
 use WebService::ADSBExchange;
 
 my $adsb = WebService::ADSBExchange->new( key => $key );
 
 my $registration = 'N161UW';
 my $position  = $adsb->single_aircraft_position_by_registration($registration);
 my $latitude  = $position->{ac}[0]->{lat};
 my $longitude = $position->{ac}[0]->{lon};
 my $flight    = $position->{ac}[0]->{flight};
 say "$registration is flight $flight and its current position is $latitude by $longitude";

=head1 DESCRIPTION

This interface helps the user to communicate with the API at adsbexchange.com to track aircraft 
information.  The API could be used, for example, to alert you when an aircraft is within four 
miles and flying under 5000 feet, or when an aircraft squawks 7700.  To use the API you need to 
register at https://rapidapi.com/adsbx/api/adsbexchange-com1 and buy a subscription.

To use the module, you first create a WebService::ADSBExchange object.  The new() function takes 
one parameter: your API Key.   

 my $adsb = WebService::ADSBExchange->new( key => $key );
 
... and then you are ready to use the methods on your $adsb object.  If you send no key you will 
get an error message from the module.  If you send an invalid key, the module will use it and  
you'll get an error from the API.

The API URL is fixed in the module, but if it changes you can also pass the new one to the new()  
function:

 my $adsb = WebService::ADSBExchange->new( key => $key, api_url => 'new_api_url.com' );

=head1 METHODS

Each method returns the full API response in a hash. The API responds with JSON, and this interface  
parses it into a hash for you to read.   A complete example of accessing the information is in the 
synopsis.  If you want to mess with the "raw" JSON response, just call get_json_response().  This 
could be useful if you want to inspect the result to determine which pieces of data you want.  You 
could also use Data::Dumper on the hash to see everything formatted nice and pretty, but that's 
no fun.

=head2 single_aircraft_position_by_registration

 $adsb->single_aircraft_position_by_registration('N161UW');

=head2 single_aircraft_position_by_hex_id

 $adsb->single_aircraft_position_by_hex_id('A0F73C');

=head2 aircraft_live_position_by_hex_id

 $adsb->aircraft_live_position_by_hex_id('A0F73C');
 
This call appears to be the same as single_aircraft_position_by_hex_id

=head2 aircraft_last_position_by_hex_id

 $adsb->aircraft_last_position_by_hex_id("A0F73C");

=head2 aircraft_by_callsign

 $adsb->aircraft_by_callsign('AAL2630');

=head2 aircraft_by_squawk

 $adsb->aircraft_by_squawk('2025');

=head2 tagged_military_aircraft

 $adsb->tagged_military_aircraft();
 
Note this method takes no parameters.

=head2 aircraft_within_n_mile_radius

 $adsb->aircraft_within_n_mile_radius( '45.09634', '-94.41019',	'30' );
 
Latitude, Longitude, and miles

=head2 do_call

do_call is not meant to be accessed directly, but if additional API calls are implemented before this
interface is updated to use them, you could still use this interface and make the API call like this:

 $adsb->do_call('new_api_call_example/new_api_call_parameters');
 
For example, if there was a new API call that returned aircraft by country of registration, it might 
look something like this:

 $adsb->do_call('country/Austria'); 

=head2 get_json_response

This is the only method that doesn't make an API call; it returns the full JSON response 
from the previous call.  This is useful if you wish to see what information is available from the 
call or wish to parse it in a different way.

=cut

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use strict;
use warnings;
use Moose;
use Types::Standard qw(Str);
use Carp            qw(croak);
use JSON::Parse     qw(parse_json);

sub BUILD {
	my $self = shift;

	croak
'You did not specify your API key. <WebService::ADSBExchange->new( key => $key );> To get a key, visit https://rapidapi.com/adsbx/api/adsbexchange-com1'
	  if ( !defined $self->key );

	return;
}

has 'api_url' => (
	is      => 'rw',
	isa     => Str,
	default => 'adsbexchange-com1.p.rapidapi.com',
);

has 'key' => (
	is  => 'rw',
	isa => Str
);

has 'json_response' => (
	is  => 'rw',
	isa => Str
);

sub do_call {
	my ( $self, $callrequest ) = @_;

	my $full_api_url   = 'https://' . $self->api_url;
	my $obj_user_agent = LWP::UserAgent->new( timeout => 15 );
	my $header         = HTTP::Headers->new;

	$header->push_header( 'X-RapidAPI-Key'  => $self->key );
	$header->push_header( 'X-RapidAPI-Host' => $self->api_url );
	my $obj_request =
	  HTTP::Request->new( 'GET', $full_api_url . "/v2/$callrequest/", $header );
	my $obj_response = $obj_user_agent->request($obj_request);

	if ( $obj_response->is_error ) {
		warn "HTTP request error: "
		  . $obj_response->error_as_HTML
		  . " on API Call $callrequest";

	}
	else {
		$self->json_response( $obj_response->content );
		return parse_json( $obj_response->content );
	}
}

sub get_json_response {
	my $self = shift;
	return $self->json_response;
}

sub single_aircraft_position_by_registration {
	my $self         = shift;
	my $registration = shift;
	return $self->do_call("registration/$registration");
}

sub single_aircraft_position_by_hex_id {
	my $self   = shift;
	my $hex_id = shift;
	return $self->do_call("icao/$hex_id");
}

sub aircraft_live_position_by_hex_id {
	my $self   = shift;
	my $hex_id = shift;
	return $self->do_call("icao/$hex_id");
}

sub aircraft_last_position_by_hex_id {
	my $self   = shift;
	my $hex_id = shift;
	return $self->do_call("hex/$hex_id");
}

sub aircraft_by_callsign {
	my $self     = shift;
	my $callsign = shift;
	return $self->do_call("callsign/$callsign");
}

sub aircraft_by_squawk {
	my $self   = shift;
	my $squawk = shift;
	return $self->do_call("sqk/$squawk");
}

sub tagged_military_aircraft {
	my $self = shift;
	return $self->do_call('mil');
}

sub aircraft_within_n_mile_radius {
	my ( $self, $lat, $lon, $dist ) = @_;
	return $self->do_call("lat/$lat/lon/$lon/dist/$dist");
}

1;
