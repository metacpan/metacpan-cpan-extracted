#perl -w
use strict;
use Test::More;
BEGIN {
    if ($^O !~ /Win32/i) {
        plan skip_all => "Win32::Wlan only works on Win32";
    } else {
        plan 'tests' => 5;
    };
}

use Win32::Wlan::API;
use Data::Dumper;

my $handle;
ok eval {
    $handle = Win32::Wlan::API::WlanOpenHandle();
    1
};
is $@, '', "No error";
ok $handle, "We got a handle";

my @interfaces = Win32::Wlan::API::WlanEnumInterfaces($handle);

diag Dumper \@interfaces;

for my $i (@interfaces) {
    diag "Querying interface $i->{name}";
    my $ih = $i->{guuid};
    
    diag Dumper Win32::Wlan::API::WlanGetAvailableNetworkList($handle,$ih);
};

ok eval {
    Win32::Wlan::API::WlanCloseHandle($handle);
    1
}, "Released the handle";
is $@, '', "No error";
