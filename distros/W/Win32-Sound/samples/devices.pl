use strict;
use warnings;

use Win32::Sound;

my %order = qw(
    name                1
    driver_version      2
    manufacturer_id     3
    product_id          4
);

my @devs = Win32::Sound::Devices();

foreach my $dev (@devs) {
    print "$dev:\n";
    my %inf = Win32::Sound::DeviceInfo($dev);
    foreach my $key (
    sort { 
        ($order{$a} or 99) <=> ($order{$b} or 99)
    } keys %inf) {
        print "\t$key => $inf{$key}\n";
    }
}

