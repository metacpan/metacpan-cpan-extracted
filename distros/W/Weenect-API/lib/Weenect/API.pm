#! perl

use v5.36;
use Object::Pad;
use utf8;

=head1 NAME

Weenect::API - API interaction

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

class Weenect::API;

use Weenect::Connect;

field $api :accessor;
field $acct;
field $debug :mutator;

=head1 METHODS

The Weenect::API class supports the following methods:

=cut

=head2 login( $user, $pass )

Connects to the Weenect server by loggin in.

Returns a user object, suitable for further operations.

=cut

method login( $user = "", $pass = "" ) {
    $api = Weenect::Connect->new;
    $api->debug = $debug;
    my $acct = $self->get_acct( $user, $pass );
    my $res = $api->request( "user/login",
			     Content => $acct->json );
    return unless $res;
    $api->auth = Weenect::Auth->create($res);
}

method get_acct( $user, $pass ) {
    return $acct if $acct;
    if ( $user && $pass ) {
	return $acct =
	  Weenect::Login->new( username => $user, password => $pass );
    }

    require ResInfo;
    my $passwd = { password => 'ddjc8c*@!eqe6' };
    $acct = Weenect::Login->new
      ( username => ResInfo::resinfo( "weenect.username", $passwd ),
	password => ResInfo::resinfo( "weenect.password", $passwd ),
      );
}

=head2 get_trackers

Returns a list of trackers associated with this account, in the form
of Weenect::Tracker objects

=cut

method get_trackers {
    require Weenect::Tracker;

    my $res = $api->request("mytracker"); # same as "mytracker-userspace"?
    return unless $res;

    return Weenect::Trackers->create_with_api( $res, $api );
}

=head2 get_preferences

Returns the current set of preferences in the form of a
Weenect::Preferences object.

=cut

method get_preferences {
    require Weenect::Preferences;

    my $res = $api->request("myuser");
    return unless $res;

    return Weenect::Preferences->create($res);
}

=head2 set_preferences( %prefs )

Sets one or more preferences.

E.g.

    language => "nl"
    preferred_metric_system => "km"
    option => 0
    mail_pref => { offers => 0,
                   company_news => 0,
                   new_features => 0,
                   surveys_and_tests => 0 }

Returns the current set of preferences in the form of a
Weenect::Preferences object.

=cut

method set_preferences( %prefs ) {
    require Weenect::Preferences;
    my $res = $api->request( "myuser", Content => \%prefs );
    return unless $res;

    return Weenect::Preferences->create($res);
}

=head2 get_animals( $imei )

Returns a list of animals associated with a given tracked, identified by its IMEI number (as a string).

The animals info is in the form of a Weenect::Animal object.

=cut

method get_animals( $imei ) {
    require Weenect::Animal;
    my $res = $api->request( sprintf("animal?imei=%s", $imei) );
    return unless $res;

    my $animals = Weenect::Animals->create($res);

    return $animals->items;
}

=head2 logout

Disconnect.

=cut

method logout {
    return $api->request("logout");
}

=head2 kindex

Get the planetary magnetic field disturbance.

Mostly returns nothing.

=cut

method kindex {
    return $api->request("kindex");
}

=head2 wifi-zone( $zid )

Returns a WiFiZone object for the requested wifi zone.

=cut

method wifi_zone( $zid ) {
    return $api->request( sprintf("wifi-zone/%d", $zid ) );
}

=head2 wifi_zone_active( $zid, $active )

Enables/disables a WiFi zone.

=cut

method wifi_zone_active( $zid, $active = 1 ) {

    my $z = $api->wifi_zone($zid);
    require Weenect::WiFiZone;
    my $zone = Weenect::WiFiZone->create($z)->hash;
    $zone->{is_active} = $active;
    return $api->request( sprintf("wifi-zone/%d", $zid ),
			  Content => $zone,
			  OP => 'PUT' );
}

=head2 remove_wifi_zone( $zid )

Returns a WiFiZone object for the requested wifi zone.

=cut

method remove_wifi_zone( $zid ) {
    $zid = $zid->id if $zid isa Weenect::WiFiZone;
    return $api->request( sprintf("wifi-zone/%d", $zid), OP => 'DELETE' );
}

=head2 add_wifi_zone( %atts )

Adds a new WiFi zone and returns the WiFiZone object for the hew zone.

%atts may contain _zone => WiFiZone object.

=cut

#   name                 : "Oh Denneboom"
#   mac_address          : "cc:ce:1e:1c:7c:46"
#   latitude             : 52.8849946
#   longitude            : 6.85922149999999
#   radius               : 15
#   is_active            : true
#   enable_notifications : true


method add_wifi_zone( %atts ) {
    %atts = ( delete($atts{_zone})->hash->%*, %atts ) if $atts{_zone};
    return $api->request( "wifi-zone", Content => \%atts );
}

################ Classes ################

class Weenect::Login :does(Class::JSON_Object) {
    field $username :param;
    field $password :param;
}

class Weenect::Auth :does(Class::JSON_Object) {
    field $access_token;
    field $expires_in;
    field $refresh_token;
    field $token_type;
}

1;

# android
# android/token device_uuid site
# auth/external-id
# mailtoken
# myaccountoptions
# mysubscription/$subscriptionid
# mytracker/$tid/activity
# mytracker/register
# mytracker/$tid/buttons
# mytracker/$tid/imei
# mytracker/$tid/wifi-zones/suggest
# oauth/token
# subscriptionoffer
# user/$uid
# user/forgotpassword mail
# user/register

