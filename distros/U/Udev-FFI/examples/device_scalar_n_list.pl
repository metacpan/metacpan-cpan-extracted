#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Udev::FFI;



die("Usage: device_scalar_n_list.pl NETWORK_INTERFACE_NAME")
    unless (defined($ARGV[0]));

my $udev = Udev::FFI->new() or
    die("Can't create Udev::FFI object: $@.\n");

my $device = $udev->new_device_from_syspath('/sys/class/net/'.$ARGV[0]);
if (defined($device)) {
    # scalar context
    my $href = $device->get_properties_list_entries();
    print(Dumper($href)."\n");

    # list context
    my @a = $device->get_properties_list_entries();
    print(Dumper(@a)."\n");
}
