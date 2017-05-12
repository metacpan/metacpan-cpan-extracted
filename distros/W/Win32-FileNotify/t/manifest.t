#!/usr/bin/perl

use strict;
use warnings;
use FindBin ();
use Test::More;

eval "use Test::CheckManifest 1.01";
plan skip_all => "Test::CheckManifest 1.01 required" if $@;
ok_manifest({filter => [qr/\.git/]});

