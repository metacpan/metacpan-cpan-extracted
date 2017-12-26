#!/usr/bin/perl

use strict;
use warnings;

use FindBin; # only for this example - load local Udev::FFI module
use lib "$FindBin::Bin/../lib"; # only for this example - load local Udev::FFI module

use Udev::FFI;
use Udev::FFI::Devnum qw(:all); #import major, minor and makedev



my $udev = Udev::FFI->new() or
    die "Can't create Udev::FFI object: $@.\n";

my $enumerate = $udev->new_enumerate() or
    die "Can't create enumerate context: $@.\n";

$enumerate->add_match_subsystem('block');
$enumerate->scan_devices();

my @a = $enumerate->get_list_entries();
if(@a) {
    my $device = $udev->new_device_from_syspath($a[0]);
    if(defined $device) {
        print "Device: ".$device->get_sysname(), "\n";

        my $devnum = $device->get_devnum();
        my ($ma, $mi) = (major($devnum), minor($devnum));

        print "Major: $ma\n";
        print "Minor: $mi\n";

        $devnum = undef;

        $devnum = makedev($ma, $mi);
        print "Devnum: $devnum\n";
    }
}