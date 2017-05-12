#!perl -w
use strict;
use Win32::Wlan;
use Data::Dumper;

my $wlan = Win32::Wlan->new;
die "No Wlan available"
    unless $wlan->available;
    
while (1) {
    if ($wlan->connected) {
        printf "Connected to %s\n", $wlan->connection->{profile_name};
    };
    print "--- Visible networks\n";
    for ($wlan->visible_networks) {
        printf "%s\t-%d dbm\n", $_->{ssid}, $_->{signal_quality};
    };
    sleep 10;
};