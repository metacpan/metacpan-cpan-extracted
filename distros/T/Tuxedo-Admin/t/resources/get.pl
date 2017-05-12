#!/usr/bin/env perl

use lib '/home/keith/perl/TuxedoAdmin/lib';

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;

$resources = $admin->resources();

$\ = "\n";

print "Max services: ", $resources->maxservices();
print "Max servers: ", $resources->maxservers();

