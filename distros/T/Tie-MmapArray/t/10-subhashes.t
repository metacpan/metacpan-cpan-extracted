#!/usr/bin/perl

use Test;
use strict;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);
use Data::Dumper;

BEGIN { plan tests => 2 };

use Tie::MmapArray;

my $file = "testfile";

my @strings = ( "ABC", "DEF", "GHI", pack("ii", 42, 43),
		"ZYX", "WVU", "TSR", pack("ii", 123, 456) );
my @array;
my $failed;


open(FILE, ">$file") or die "cannot create testfile\n";
print FILE join "", @strings;
close FILE;

tie @array, 'Tie::MmapArray', $file, { template => [ f1 => 'A3', 
						     f2 => 'A3A3',
						     f3 => [ i1 => "i",
							     i2 => "i" ] ],
				       nels     => 3 };

#print Dumper(\@array);

ok($array[0]->{f1}       eq 'ABC' &&
   $array[0]->{f2}->[0]  eq 'DEF' &&
   $array[0]->{f2}->[1]  eq 'GHI' &&
   $array[0]->{f3}->{i1} == 42    && 
   $array[0]->{f3}->{i2} == 43);

ok($array[1]->{f1}       eq 'ZYX' &&
   $array[1]->{f2}->[0]  eq 'WVU' &&
   $array[1]->{f2}->[1]  eq 'TSR' &&
   $array[1]->{f3}->{i1} == 123   && 
   $array[1]->{f3}->{i2} == 456);
