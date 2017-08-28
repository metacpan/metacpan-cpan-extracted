#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use blib;
use USB::LibUSB::XS;
use Data::Dumper;

my $rv;
my $ctx;
my @dev_list;

sub handle_error {
    my ($rv, $msg) = @_;
    return if $rv >= 0;
    die "in $msg: rv: $rv, error_name: ", libusb_error_name($rv),", error string: ", libusb_strerror($rv);
}

($rv, $ctx) = USB::LibUSB::XS->init();
handle_error($rv, "init");

($rv,  @dev_list) = $ctx->get_device_list();
handle_error($rv, "get_device_list");

say "number of devices on the USB: ", (@dev_list + 0);

for my $dev (@dev_list) {
    my ($rv, $desc) = $dev->get_device_descriptor();
    print Dumper $desc;
}
