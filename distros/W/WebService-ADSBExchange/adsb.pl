use strict;
use warnings;
use lib 'lib';
use WebService::ADSBExchange;
use Data::Dumper;
use feature 'say';

open( my $keyfile, '<', "/home/david/adsbx_key" ) or die $!;
my $key = <$keyfile>;

my $adsb = WebService::ADSBExchange->new( key => $key );

say Dumper $adsb->aircraft_within_n_mile_radius( '45.09634', '-94.41019',
	'5' );

die;
$adsb->single_aircraft_position_by_hex_id("a0f73c");
say $adsb->get_json_response;
$adsb->aircraft_live_position_by_hex_id("a0f73c");
say $adsb->get_json_response;
die;

my $registration = 'N161UW';
my $position  = $adsb->single_aircraft_position_by_registration($registration);
my $latitude  = $position->{ac}[0]->{lat};
my $longitude = $position->{ac}[0]->{lon};
my $flight    = $position->{ac}[0]->{flight};
say
"$registration is flight $flight and its current position is $latitude by $longitude";

say $adsb->get_json_response();

say Dumper $adsb->aircraft_last_position_by_hex_id("a0f73c");
say Dumper $adsb->aircraft_by_callsign('AAL2630');
say Dumper $adsb->aircraft_by_squawk('2025');

my $mil = $adsb->tagged_military_aircraft();
foreach my $aircraft ( @{ $mil->{ac} } ) {
	if ( defined $aircraft->{flight} && defined $aircraft->{r} ) {
		say $aircraft->{r} . "|" . $aircraft->{flight};
	}
}
