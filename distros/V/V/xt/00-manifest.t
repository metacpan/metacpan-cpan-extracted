#!/usr/bin/perl -I.

use strict;
use warnings;

use t::Test::abeltje;

use ExtUtils::Manifest qw/ manicheck filecheck /;
$ExtUtils::Manifest::Quiet = 1;

my @missing = filecheck ();
   @missing and diag ("Files missing from MANIFEST: @missing");
is (scalar @missing, 0, "No files missing from MANIFEST");

my @extra = manicheck ();
   @extra   and diag ("Files in MANIFEST but not here: @extra");
is (scalar @extra,   0, "No extra files in MANIFEST");

@missing || @extra and BAIL_OUT ("FIX MANIFEST FIRST!");

abeltje_done_testing ();
