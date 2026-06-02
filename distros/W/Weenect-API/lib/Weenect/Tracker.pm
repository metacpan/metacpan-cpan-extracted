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
    foreach my $tracker ( $trackers->items->@* ) {
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

use Weenect::Position;

#### Instanciate via Weenect::Trackers only.

field $api :Optional :mutator;
field $id;
field $active;
field $name;
field @position :Class(Weenect::Position);
field $geofence_number :Optional;
field @features;
field $sos_phone;

=head1 METHODS

The Weenect::Tracker class supports the following methods:

=cut

=head2 get_zones

Returns a Weenect::Zones object, that has a list of zones (geofence
areas) in the form of Weenect::Zone objects.

Use the items method to get at the list.

=cut

method get_zones {
    require Weenect::Zone;
    my $res = $api->request( sprintf( "mytracker/%d/zones", $id ) );
    return unless $res;
    return Weenect::Zones->create($res);
}

=head2 get_zone( $zid )

Returns a Weenect::Zone object representing a zone (geofence area).

=cut

method get_zone( $zid ) {
    require Weenect::Zone;
    my $res = $api->request( sprintf( "mytracker/%d/zones/%s", $id, $zid ) );
    return unless $res;
    return Weenect::Zone->create($res);
}

=head2 remove_zone( $zid )

Removes a zone (geofence areas).

=cut

method remove_zone( $zid ) {
    my $res = $api->request( sprintf( "mytracker/%d/zones/%s", $id, $zid ),
			     OP => 'DELETE' );
    return $res;
}

# name	      => "NewHaven",
# latitude    => 52.85,
# longitude   => 6.87,
# distance    => 25,
# address     => '',
# is_outside  => 1, # if yes this increases enter/exit detection precision.
# mode	      => 3,

method add_zone( %args ) {
    my $res = $api->request( sprintf( "mytracker/%d/zones", $id ),
			     Content => \%args );
    return $res;
}

=head2 get_wifizones

Returns a Weenect::WiFiZones object that has a list of WiFi zones
(powersave areas) in the form of Weenect::WiFiZone objects.

Use its item method to get at the list.

=cut

method get_wifizones {
    require Weenect::WiFiZone;
    my $res = $api->request( sprintf( "mytracker/%d/wifi-zones", $id ) );
    return unless $res;
    return Weenect::WiFiZones->create($res);
}

=head2 get_wifizone( $zid )

Returns a Weenect::WiFiZone object representing a WiFi zone (powersave area).

=cut

method get_wifizone( $zid ) {
    require Weenect::WiFiZone;
    my $res = $api->request( sprintf( "mytracker/%d/wifi-zones/%s", $id, $zid ) );
    return unless $res;
    return Weenect::WiFiZone->create($res);
}

#### "mytracker/%d/wifi-zones" only allows HEAD GET OPTIONS. Use "wifi-zone" in API.
#
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

=head2 has_feature( $feat )

Checks if the tracker has a certain feature.

Common features include:

      activity_tracking
      has_flash
      has_wifi
      limited_buttons
      ringing
      super_tracking
      vibrate

=cut

# My tracker has:
#   activity_tracking
#   has_flash
#   has_flash_stop
#   has_wifi
#   limited_buttons
#   mode_gsensor
#   mode_selection
#   ringing
#   ringing_stop
#   super_tracking
#   super_tracking_interval_1
#   super_tracking_stop
#   super_tracking_ttl_cmd_hms
#   vibrate
#   vibrate_sequence
#   vibrate_stop

method has_feature( $feat ) {
    require List::Util;
    return List::Util::any { $_ eq $feat } @features;
}

=head2 flash

Initiates the flash light of the tracker.

Default is 100ms on, 100ms off, for 5 minutes.

=cut

method flash( $on = 1 ) {
    my %content =
        ( duration_minutes => 1,
          intermittent_duration_ms_on => $on ? 100 : 0,
          intermittent_duration_ms_off => $on ? 100 : 0,
        );
    return $api->request( sprintf( "mytracker/%d/flash", $id ),
    	                  Content => \%content );
}

=head2 flash_stop

    {
      data          = {
          intermittent_duration_off = 1,
          intermittent_duration_on  = 1
      },
      duration      = 60,
      end_at        = undef,
      sent_start_at = '2026-06-01T09:47:26.822271' (dualvar: 2026),
      sent_stop_at  = undef,
      started_at    = undef
    }

=cut

method flash_stop {
    return $api->request( sprintf( "mytracker/%d/flash/stop", $id ) );
}

=head2 ring

Initiates the ringer of the tracker.

=cut

method ring {
    my $res = $api->request( sprintf( "mytracker/%d/ring", $id ),
			     OP => 'POST' );
    # return unless $res;
    return $res;
}

=head2 ring_stop

Stops the ringer.

=cut

method ring_stop {
    return $api->request( sprintf( "mytracker/%d/ring/stop", $id ) );
}

=head2 vibrate

Initiates the buzzer of the tracker.

=cut

method vibrate {
    my $res = $api->request( sprintf( "mytracker/%d/vibrate", $id ),
			     OP => 'POST' );
    # return unless $res;
    return $res;
}

=head2 vibrate_stop

Stops the buzzer.

=cut

method vibrate_stop {
    return $api->request( sprintf( "mytracker/%d/vibrate/stop", $id ) );
}

=head2 position_refresh

Force position update of the tracker.

=cut

method position_refresh {
    my $res = $api->request( sprintf( "mytracker/%d/position/refresh", $id ),
			     OP => 'POST' );
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
			     OP => 'POST' );
    # return unless $res;
    return $res;		# {"interval":10}
}

=head2 get_super_live

Gets the current super_live status.

    {
      active    = 0,
      duration  = undef,
      freq_mode = undef,
      interval  = undef,
      ttl       = -2
    }

=cut

method get_super_live {
    my $res = $api->request( sprintf( "mytracker/%d/superlive", $id ) );
    # return unless $res;
    return $res;		# {}
}

=head2 stop_super_live {

Stops super_live tracking.

    {
      data          = undef,
      duration      = undef,
      end_at        = undef,
      sent_start_at = undef,
      sent_stop_at  = undef,
      started_at    = undef
    }

=cut

method stop_super_live {
    my $res = $api->request( sprintf( "mytracker/%d/superlive/stop", $id ) );
    # return unless $res;
    return $res;		# {}
}

# "mytracker/%d/sos"
# "mytracker/%d/full-sos"
# "mytracker/%d/full-sos/ack"

method sos_call {
    my $res = $api->request( sprintf( "mytracker/%d/sos", $id ),
			     Content => { phone_number => $sos_phone } );
    return $res;		# {}
}

=head2 set_mode

Sets the mode (update interval).

Valid values are '30S', '1M', '2M', '3M', '5M' and 'OFF'.

Additional subscription fees are required for '10s' interval.

=cut

method set_mode( $mode ) {
    my $res = $api->request( sprintf( "mytracker/%d/mode", $id ),
			     Content => { mode => uc $mode } );
    return $res;		# {}
}

=head2 detect_hotspots

Initiate WiFi hotspot detecting.

=cut

method detect_hotspots {
    my $res = $api->request( sprintf( "mytracker/%d/detect-hotspots", $id ), OP => 'POST' );
    return $res;		# {}
}

=head2 list_hotspots

List detected hotspots.

    {
      completed = 0 (JSON::PP::Boolean),
      items     = [],
      total     = 0
    }

=cut

method list_hotspots {
    my $res = $api->request( sprintf( "mytracker/%d/list-hotspots", $id ) );
    return $res;		# {}
}

=head2 deep-sleep-wifi

=cut

method deep_sleep_wifi {
    my $res = $api->request( sprintf( "mytracker/%d/deep-sleep-wifi", $id ) );
    return $res;		# {"enable_deep_sleep_wifi":false}
}

=head2 wifizones_suggest

    {
      size        = 0,
      zone_status = 'new',
      zone_wifi   = []
    }

=cut

method wifizones_suggest {
    my $res = $api->request( sprintf( "mytracker/%d/wifi-zones/suggest", $id ) );
    return $res;		# {}
}

=head2 remove_picture

Removes the tracker picture, if any.

=cut

method remove_picture {
    my $res = $api->request( sprintf( "mytracker/%d/picture", $id ), OP => 'DELETE' );
    return $res;		# {}
}

1;

# "mytracker/{trackerId}/activity/v2" start end metric_system
