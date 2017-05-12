#perl -w
use strict;
use Test::More;
BEGIN {
    if ($^O !~ /Win32/i) {
        plan skip_all => "Win32::Wlan only works on Win32";
    } else {
        plan 'tests' => 5;
    };
};

use Win32::Wlan::API;

my $handle;
ok eval {
    $handle = Win32::Wlan::API::WlanOpenHandle();
    1
};
is $@, '', "No error";
ok $handle, "We got a handle";

ok eval {
    Win32::Wlan::API::WlanCloseHandle($handle);
    1
}, "Released the handle";
is $@, '', "No error";
