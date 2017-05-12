#!/usr/bin/env perl

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;

$imported_resource = $admin->imported_resource('OOK');
die "Resource OOK does not exist!\n" unless $imported_resource->exists();
print "Resource name: ", $imported_resource->dmresourcename(), "\n";
print "Local access point: ", $imported_resource->dmlaccesspoint(), "\n";
print "Remote access points: ", $imported_resource->dmraccesspointlist(), "\n";

$admin->print_status();


