#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval "use Test::CheckManifest 1.22";
plan skip_all => "Test::CheckManifest 1.22 required" if $@;
ok_manifest({filter => [qr/\.git/] });
