#!/usr/bin/perl

use warnings;
use strict;

use Test::Most "bail";
use Test::Exports;

my $pkg = new_import_pkg;

like $pkg, qr/Test::Exports::Test[A-Z]{5}/, 
    "test pkg created under T::E";

my ($c) = $pkg =~ /([A-Z]{5})$/;
$c++;
is new_import_pkg, "Test::Exports::Test$c",
    "new_import_pkg increments pkg name";

done_testing;
