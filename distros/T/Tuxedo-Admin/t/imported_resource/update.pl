#!/usr/bin/env perl

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;
$admin->debug(1);

$imported_resource = $admin->imported_resource('OOK');
$imported_resource->dmload('100');
$imported_resource->update();

$admin->print_status();


