#!/usr/bin/perl -w

use strict;
use v5.010;
use Test::More;
use Test::Warnings;

use_ok('experimental', 'switch');

use_ok('WebService::Strava');

done_testing();
