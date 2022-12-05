#perl -w
use strict;
use Test::More;
BEGIN {
    if ($^O !~ /Win32/i) {
        plan skip_all => "Win32::Wlan only works on Win32";
    } else {
        plan 'tests' => 1;
    };
};

use Win32::Wlan::API qw(WlanOpenHandle WlanEnumInterfaces WlanQueryCurrentConnection);
if ($Win32::Wlan::API::wlan_available) {
    my $handle = eval { WlanOpenHandle() };
    if ($Win32::Wlan::API::wlan_available) {
        my @interfaces = WlanEnumInterfaces($handle);
        if (@interfaces) {
            my $ih = $interfaces[0]->{guuid};
            diag "Interface name '$interfaces[0]->{name}'";
            my %info = WlanQueryCurrentConnection($handle,$ih);
            diag "Connected to $info{ profile_name }\n";        
        }
    }
} else {
    diag "No Wlan detected (or switched off)\n";
}

ok 1, "Synopsis does not crash";
