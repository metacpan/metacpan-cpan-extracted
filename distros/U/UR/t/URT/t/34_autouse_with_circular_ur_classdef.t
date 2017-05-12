#!/usr/bin/env perl

use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; 
use strict;
use warnings;

plan skip_all => "known broken - if a parent class has a property of a type which is a subclass of itself, the subclass must explicitly 'use' its parent instead of relying on autoloading";
#plan tests => 2;

# KNOWN SOLUTION:
# class definition happens in two phases: the minimal phase, then building the detailed meta objects
# when one definition triggers loading of other classes, the minimal phase should complete for everything, then the final should run on everythign
# this is much like we do when bootstrapping, and if it were in place special boostrapping logic might not be needed
# until then: if you do a bunch of cirucular crap with your classes explicitly have them "use" each other :)

# make sure things being associated with objects
# are not being copied in the constructor

use_ok("URT::34Subclass");

my $st = URT::34Subclass->create();

ok($st,"made subclass");

