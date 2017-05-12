#!/usr/bin/perl

use strict;
use Wifi::Manage;

my $manager = Wifi::Manage->new("exemple_mod.config");
$manager->stop_with_module;
