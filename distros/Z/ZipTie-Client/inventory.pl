#!/usr/bin/perl
#
# Displays a summary of the inventory
#

use strict;
use warnings;

use ZipTie::Client;


my $client = ZipTie::Client->new(username => 'admin', password => 'password', host => 'localhost:8080', );

my $page = ();
$page->{pageSize} = 100;

print("IP, Adapter ID, Serial Number, Backup Status, Make, Hostname, Managed Network, Model, OS Version, OS Vendor\n");

my $offset = 0;
do
{
    $page->{offset} = $offset;

    $page = $client->devicesearch()->search(scheme => "ipAddress",
                                            query => "",
                                            pageData => $page);

    my $devices = $page->{devices};
    foreach my $device (ref($devices) eq 'HASH' ? $devices : @$devices)
    {
        my $ip = $device->{ipAddress};
        my $network = $device->{managedNetwork};
        my $adapter = $device->{adapterId};
        my $hostname = $device->{hostname} || "";
        my $serial = $device->{assetIdentity} || "";
        my $status = $device->{backupStatus} || "";
        my $make = $device->{hardwareVendor} || "";
        my $model = $device->{model} || "";
        my $os_ver = $device->{osVersion} || "";
        my $os_vendor = $device->{softwareVendor} || "";

        print("$ip, $adapter, $serial, $status, $make, $hostname, $network, $model, $os_ver, $os_vendor\n");
    }

    $offset += $page->{pageSize};
}
while ($page->{total} > $offset);
