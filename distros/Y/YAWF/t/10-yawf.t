#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

use_ok('YAWF');

my $yawf = YAWF->new();
ok(defined($yawf),'Create empty YAWF object');

is ($yawf->SINGLETON,$yawf,'SINGLETON');

# Check child objects
ok(defined($yawf->config),'config object');
ok(defined($yawf->reply),'reply object');
