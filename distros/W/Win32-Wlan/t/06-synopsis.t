#perl -w
use strict;
use Test::More;
BEGIN {
    if ($^O !~ /Win32/i) {
        plan skip_all => "Win32::Wlan only works on Win32";
    } else {
        plan 'tests' => 4;
    };
}

use Win32::Wlan;

my $wlan = Win32::Wlan->new( available => 0 );
isa_ok $wlan, 'Win32::Wlan';
ok ! $wlan->available, "If we say it's unavailable, it is";

$wlan = Win32::Wlan->new();
SKIP: {
    if ($wlan->available) {
        diag "We have the Wlan API";
        if (! $wlan->interface) {
            skip "We have no Wlan interface", 2;
        };
        ok $wlan->interface->{name}, "We have a name for the interface";
        if ($wlan->connected) {
            my $connection = $wlan->connection;
            ok $connection->{profile_name}, "We have a profile name";
        } else {
            skip "... but we have no connection", 1;
        };
    } else {
        skip "Wlan is unavailable", 2;
    };
}