#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec   ();
use File::Remove ();
use Test::XT     'WriteXT';

# Write the generated file
my $file = File::Spec->catfile('t', '12_pod._t');
File::Remove::clear($file);
WriteXT( 'Test::Pod' => $file );

# Execute the generated file
$ENV{AUTOMATED_TESTING} = 1;
$ENV{RELEASE_TESTING}   = 0;
require $file;
