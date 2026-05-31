#! perl

use v5.36;
use Object::Pad;
use Class::JSON_Object;
use utf8;

=head1 NAME

Weenect::Zone - geofence zone data

=cut

=head1 DESCRIPTION

Weenect::Zone describes a user defined geofence area.

=head1 METHODS

Supported methods include:

=head2 id

=head2 number

=head2 name

=head2 address

=head2 active

=head2 tracker_id

=head2 latitude

=head2 longitude

=head2 mode

Notifications: 0 = No, 1 = Enter, 2 = Exit, 3 = Enter+Exit.

=head2 distance

=head2 is_outside

=cut

class Weenect::Zone :does(Class::JSON_Object) {
    field $id;
    field $number;
    field $name;
    field $address;
    field $active;
    field $tracker_id;
    field $latitude;
    field $longitude;
    field $mode;
    field $distance;
    field $is_outside;
}

class Weenect::Zones :does(Class::JSON_Object) {
    field $total;
    field @items :Class(Weenect::Zone);
}

1;
