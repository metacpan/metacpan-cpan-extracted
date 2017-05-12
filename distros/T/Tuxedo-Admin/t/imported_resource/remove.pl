#!/usr/bin/env perl

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;
$admin->debug(1);

$imported_resource = $admin->imported_resource('OOK');
$imported_resource->dmlaccesspoint('SYSTEM1');
$imported_resource->dmraccesspointlist('SYSTEM2');
$imported_resource->remove() if $imported_resource->exists();

$admin->print_status();


