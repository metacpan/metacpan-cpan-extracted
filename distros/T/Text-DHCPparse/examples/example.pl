#!/usr/bin/perl

use Text::DHCPparse;

$return = leaseparse('/tmp/dhcpd.leases');

foreach (keys %$return) {
   print "$return->{$_}\n";
}

