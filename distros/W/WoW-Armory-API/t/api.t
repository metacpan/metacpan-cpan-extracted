#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

use WoW::Armory::API;

my $api;

ok($api = WoW::Armory::API->new);

1;
