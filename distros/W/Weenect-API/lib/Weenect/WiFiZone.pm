#! perl

use v5.36;
use Object::Pad;
use Class::JSON_Object;
use utf8;

=head1 NAME

Weenect::WiFiZone - powersave zone info

=head1 DESCRIPTION

Weenect::WiFiZone describes a user defined powersave area.

=cut

=head1 METHODS

Supported methods include:

=head2 id

=head2 name

=head2 mac_address

=head2 created_at

=head2 updated_at

=head2 tracker_id

=head2 latitude

=head2 longitude

=head2 radius

=head2 is_active

=head2 enable_notifications

=cut

class Weenect::WiFiZone :does(Class::JSON_Object) {
    field $id;
    field $name;
    field $mac_address;
    field $created_at;
    field $updated_at;
    field $tracker_id;
    field $latitude;
    field $longitude;
    field $radius;
    field $is_active;
    field $enable_notifications;
}

class Weenect::WiFiZones :does(Class::JSON_Object) {
    field $total;
    field @items :Class(Weenect::WiFiZone);
}

1;
