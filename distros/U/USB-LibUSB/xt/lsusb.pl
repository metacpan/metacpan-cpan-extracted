#!/usr/bin/env perl
use warnings;
use strict;
use 5.010;

use blib;
use USB::LibUSB;

my $ctx = USB::LibUSB->init();
my @devices = $ctx->get_device_list();

for my $dev (@devices) {
    my $bus_number = $dev->get_bus_number();
    my $device_address = $dev->get_device_address();
    my $desc = $dev->get_device_descriptor();
    my $idVendor = $desc->{idVendor};
    my $idProduct = $desc->{idProduct};
    
    printf("Bus %03d Device %03d: ID %04x:%04x\n", $bus_number,
           $device_address, $idVendor, $idProduct);
}
    
