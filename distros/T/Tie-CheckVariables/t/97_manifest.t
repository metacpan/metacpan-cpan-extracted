#!/usr/bin/perl

use strict;
use warnings;
use FindBin ();
use Test::More;

eval "use Test::CheckManifest 1.38";
plan skip_all => "Test::CheckManifest 1.38 required" if $@;
ok_manifest({ filter => [ qr/MYMETA/ ], exclude => ['/.build', '/cover_db'] });

