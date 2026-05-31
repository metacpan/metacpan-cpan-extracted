#! perl

use v5.36;
use Object::Pad;
use Class::JSON_Object;
use utf8;

=head1 NAME

Weenect::Position - position data

=cut

=head1 DESCRIPTION

Weenect::Position describes a position.

=head1 METHODS

Supported methods include:

=head2 latitude

=head2 longitude

=head2 battery_text

=head2 gsm_text

=head2 accuracy_text

=head2 geofence_name

=head2 wifi_zone_id

=head2 date_tracker

=head2 distance( $other )

Returns the distance (in meters) between the position and $other.

=cut

class Weenect::Position :does(Class::JSON_Object) {
    field $latitude;
    field $longitude;
    field $battery_text;
    field $gsm_text;
    field $accuracy_text;
    field $geofence_name;
    field $wifi_zone_id;
    field $date_tracker;

    method distance($other) {
	$other = Weenect::Point->new( longitude => $other->longitude,
				      latitude  => $other->latitude )
	  unless $other isa Weenect::Point;
	Weenect::Point->new( longitude => $longitude,
			     latitude  => $latitude )->distance($other);
    }
}

class Weenect::Point {
    field $latitude  :param;
    field $longitude :param;

    use constant PI_D => atan2(1,1) / 45;
    sub d2r($d) { $d * PI_D } # degrees to radians

    method distance($other) {
	my $longitude1 = d2r($longitude);
	my $latitude1 = d2r($latitude);
	my $longitude2 = d2r($other->longitude);
	my $latitude2 = d2r($other->latitude);
	my $dlon = $longitude2 - $longitude1;
	my $dlat = $latitude2 - $latitude1;
	my $a = (sin($dlat/2))**2 + cos($latitude1) * cos($latitude2) * (sin($dlon/2))**2;
	my $c = 2 * atan2( sqrt($a), sqrt(1-$a) );
	return 6371640 * $c;	# meters
    }
}

1;
