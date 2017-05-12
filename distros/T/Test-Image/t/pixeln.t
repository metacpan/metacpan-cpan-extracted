#!/usr/bin/perl

####################################################################
# Description of what this test does:
# this tests the "pixel_not" routine
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
use Test::More tests => 9;

use_ok "Test::Image";

my $red   = [255,0,0];
my $green = [0,255,0];
my $blue  = [0,0,255];
my $white = [255,255,255];

# this is a slighty corrupted version of the italian flag
# it's done this way because I don't want something where all
# the rows are the same.
my $i = Test::Image->new([
  [ $red, $red, $white, $white, $green, $green ],
  [ $red, $red, $white, $white, $green, $blue ],
  [ $blue, $red, $white, $white, $green, $green ],
]);
isa_ok($i, "Test::Image");

##########################################################################

use Test::Builder::Tester;

test_out("ok 1 - pixel not test");
$i->pixel_not(5,1,$green);
test_test("ok");

test_out("not ok 1 - pixel not test");
test_fail(+2);
test_diag("Coords (1, 6) outside of image");
$i->pixel_not(1,6,$blue);
test_test("outside");

test_out("not ok 1 - pixel not test");
test_fail(+2);
test_diag("Pixel (5, 1) unexpectedly [0,0,255]");
$i->pixel_not(5,1,$blue);
test_test("wrong color");

##########################################################################

test_out("ok 1 - pixel not test");
$i->pixel_not(5,1,[$green, $red]);
test_test("ok, multiple, 1/2");

test_out("ok 1 - pixel not test");
$i->pixel_not(5,1,[$red, $green]);
test_test("ok, multiple, 2/2");

test_out("not ok 1 - pixel not test");
test_fail(+2);
test_diag("Pixel (5, 1) unexpectedly [0,0,255]");
$i->pixel_not(5,1,[$red,$blue]);
test_test("wrong color, multiple, 1/2");

test_out("not ok 1 - pixel not test");
test_fail(+2);
test_diag("Pixel (5, 1) unexpectedly [0,0,255]");
$i->pixel_not(5,1,[$blue,$red]);
test_test("wrong color, multiple, 1/2");
