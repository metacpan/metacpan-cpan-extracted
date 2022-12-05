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

BEGIN {
    use_ok "Win32::Wlan";
}