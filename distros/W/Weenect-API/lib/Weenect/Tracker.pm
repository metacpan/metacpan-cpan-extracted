#! perl

use v5.36;
use Object::Pad;
use utf8;

=head1 NAME

Weenect::Tracker - Tracker data

=head1 SYNOPSIS

    use Weenect::API;
    my $api = Weenect::API->new;

    # Connect to the server
    $api->login( "me@example.com", "password" );

    # Get the trackers.
    my $trackers = $api->get_trackers;

    # Process tracker data.
    foreach my $tracker ( @$trackers ) {
	printf("Tracker %s [%d%s]\n", $tracker->name, $tracker->id,
	      $tracker->active ? "" : ",inactive" );
    }

=cut

use Class::JSON_Object;

# Collection class for Weenect::Tracker objects.

class Weenect::Trackers :does(Class::JSON_Object) {

    field $total;
    field @items :Class(Weenect::Tracker);

    # Constructor that connects the items to the api.
    sub create_with_api ( $class, $data, $api ) {
	my $s = $class->create_sparse($data);
	for ( @{$s->items} ) {
	    $_->api = $api;
	}
	return $s;
    }
}

class Weenect::Tracker :does(Class::JSON_Object);

#### Instanciate via Weenect::Trackers only.

field $api :Optional :mutator;
field $id;
field $active;
field $name;
field @position :Class(Weenect::Position);
field $geofence_number :Optional;

=head1 METHODS

The Weenect::Tracker class supports the following methods:

=cut

=head2 get_zones

Returns a list of zones (geofence areas) in the form of Weenect::Zone
objects.

=cut

method get_zones {
    require Weenect::Zone;
    my $res = $api->request( sprintf( "mytracker/%d/zones", $id ) );
    return unless $res;
    my $zones = Weenect::Zones->create($res);
    return [ $zones->items ];
}

=head2 get_wifizones

Returns a list of WiFi zones (powersave areas) in the form of
Weenect::WiFiZone objects.

=cut

method get_wifizones {
    require Weenect::WiFiZone;
    my $res = $api->request( sprintf( "mytracker/%d/wifi-zones", $id ) );
    return unless $res;
    my $zones = Weenect::WiFiZones->create($res);
    return [ $zones->items ];
}

=head2 get_history( $start, $end )

Returns a list of positions as tracked between $start and $end.

$start and $end are UTC timestamps in ISO8601 format, e.g.
C<2021-07-17T13:57:43.773Z>

Positions are in the form of Weenect::Position objects.

=cut

method get_history( $start, $end ) {
    # https://apiv4.weenect.com/v4/mytracker/135076/activity/v2?metric_system=miles&start=2021-07-17T13:57:43.773Z&end=2021-07-18T13:57:43.773Z
    my $res = $api->request( sprintf( "mytracker/%d/activity/v2?start=%s&end=%s",
				      $id, $start, $end ) );
    return unless $res;
    return $res;
}

=head2 flash

Initiates the flash light of the tracker.

Default is 100ms on, 100ms off, for 5 minutes.

=cut

method flash {
    my $res = $api->request( sprintf( "mytracker/%d/flash", $id ),
			     { Content => q({"intermittent_duration_ms_on":100,"intermittent_duration_ms_off":100,"duration_minutes":1}) } );
    # return unless $res;
    return $res;
}

=head2 ring

Initiates the ringer of the tracker.

=cut

method ring {
    my $res = $api->request( sprintf( "mytracker/%d/ring", $id ),
			     { Content => {} } );
    # return unless $res;
    return $res;
}

=head2 vibrate

Initiates the buzzer of the tracker.

=cut

method vibrate {
    my $res = $api->request( sprintf( "mytracker/%d/vibrate", $id ),
			     { Content => {} } );
    # return unless $res;
    return $res;
}

=head2 super_live

Initiates super live tracking (1 second interval reporting) for 5 minutes.

Additional subscription fees are required for longer periods of super
live tracking.

=cut

method super_live {
    my $res = $api->request( sprintf( "mytracker/%d/st-mode", $id ),
			     { Content => {} } );
    # return unless $res;
    return $res;		# {"interval":10}
}

1;
