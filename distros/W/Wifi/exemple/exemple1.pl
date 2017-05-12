#!/usr/bin/perl

use strict;
use Wifi::Manage;

my $manager = Wifi::Manage->new("exemple.config");
$manager->start;
