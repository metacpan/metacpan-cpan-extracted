#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

isnt($ENV{VSPHERE_HOST}, undef, "environment 'VSPHERE_HOST' set");
isnt($ENV{VSPHERE_USER}, undef, "environment 'VSPHERE_USER' set");
isnt($ENV{VSPHERE_PASS}, undef, "environment 'VSPHERE_PASS' set");

done_testing;