#perl -w
use strict;
use Test::More;
BEGIN {
    if ($^O !~ /Win32/i) {
        plan skip_all => "Win32::Wlan only works on Win32";
    } else {
        plan 'tests' => 3;
    };
};

use Win32::Wlan::API;
use Data::Dumper;

my $handle = eval { Win32::Wlan::API::WlanOpenHandle() };

SKIP: {
    skip "WLAN not available", 3 unless $Win32::Wlan::API::wlan_available;

    ok $handle, "We got a handle";

    my @interfaces = Win32::Wlan::API::WlanEnumInterfaces($handle);

    diag Dumper \@interfaces;

    for my $i (@interfaces) {
        diag "Querying interface $i->{name}";
        my $ih = $i->{guuid};
        my %info = Win32::Wlan::API::WlanQueryCurrentConnection($handle,$ih);
    
        diag Dumper \%info;
    };

    ok eval {
        Win32::Wlan::API::WlanCloseHandle($handle);
        1
    }, "Released the handle";
    is $@, '', "No error";
}
