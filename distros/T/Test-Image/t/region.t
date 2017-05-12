#!/usr/bin/perl

####################################################################
# Description of what this test does:
# This tests the region command
####################################################################

use strict;
use warnings;

# use the local directory.  Note that this doesn't work
# with prove.  Darn!
use File::Spec::Functions qw(:ALL);
use FindBin;
use lib catdir($FindBin::Bin, "lib");

# lots of standard helper modules that I like to have
# loaded for all test scripts
use Cwd;
use File::Copy qw(move copy);
use File::Path qw(mkpath rmtree);

# useful diagnostic modules that's good to have loaded
use Data::Dumper;
use Devel::Peek;

# colourising the output if we want to
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

###################################
# user editable parts

# start the tests
use Test::More tests => 5;
use Test::Builder::Tester;

use_ok("Test::Image");

my $r = [255,0,0];
my $g = [0,255,0];
my $b = [0,0,255];

my $i = Test::Image->new([
  [ $r, $r, $r, $r, $r, $r ],
  [ $r, $g, $g, $r, $r, $r ],
  [ $r, $g, $g, $b, $b, $r ],
  [ $r, $g, $g, $b, $b, $r ],
  [ $r, $g, $g, $b, $b, $r ],
  [ $r, $r, $r, $b, $b, $r ],
  [ $r, $r, $r, $r, $r, $r ],  
]);

############################################
# passing tests
############################################

test_out("ok 1 - image region");
$i->region(1,1,2,4,$g);
test_test("basic test");

test_out("ok 1 - image region");
$i->region(2,4,1,1,$g);
test_test("basic reversed");

test_out("ok 1 - image region");
$i->region(-2,-2,-3,-5,$b);
test_test("negative numbers");

test_out("ok 1 - image region");
$i->region(-3,-5,-2,-2,$b);
test_test("negative numbers reversed");

