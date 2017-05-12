#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('WebService::CityGrid::Search') };

can_ok( 'WebService::CityGrid::Search', qw( query ));

