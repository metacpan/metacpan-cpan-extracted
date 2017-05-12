#!/usr/bin/perl -w

# This test suite tests for the integrity of the distribution.

use strict;

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 1;

# TEST
my $readme_exists = (-e "README");

ok($readme_exists, "README exists");


