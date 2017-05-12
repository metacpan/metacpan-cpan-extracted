#!/usr/bin/perl

use Test;
use strict;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN { plan tests => 2 };

use Tie::MmapArray;

my $file = "testfile";

my @strings = ( "ABC", "DEF", "XYZ" );
my @array;
my $failed;


open(FILE, ">$file") or die "cannot create testfile\n";
print FILE join "", @strings;
close FILE;

eval { tie @array, 'Tie::MmapArray', $file, { template => 'A0', nels => 3 }; };
ok ($@ =~ /invalid/);


tie @array, 'Tie::MmapArray', $file, { template => 'A3', nels => 3 };

for (my $i = 0; $i < @strings; $i++) {
    $failed++ if $strings[$i] ne $array[$i];
}

ok(!$failed);

