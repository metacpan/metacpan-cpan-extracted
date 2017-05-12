#!/usr/bin/perl

####################################################################
# Description of what this test does:
# This tests the col_* functions
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
use Test::More tests => 36;

use_ok "Test::Image";

my $red   = [255,0,0];
my $green = [0,255,0];
my $blue  = [0,0,255];
my $white = [255,255,255];

my $i = Test::Image->new([
  [ $red, $blue ],
  [ $red, $blue ],
  [ $red, $blue ],
  [ $red, $green ],
  [ $red, $blue ],
  [ $red, $blue ],
]);
isa_ok($i, "Test::Image");

use Test::Builder::Tester;

##########################################################################
# col_ALL
##########################################################################

# single thingscol

test_out("ok 1 - column test");
$i->col(0, $red);
test_test("ok col");

test_out("ok 1 - column test");
$i->col_all(0, $red);
test_test("ok col all");

test_out("not ok 1 - column test");
test_fail(+4);
test_diag("Pixel (1, 3):");
test_diag("       got: [0,255,0]");
test_diag("  expected: [0,0,255]");
$i->col(1, $blue);
test_test("col fail");

# multiple things

test_out("ok 1 - column test");
$i->col(0, [$red,$blue]);
test_test("ok col multiple 1/3");

test_out("ok 1 - column test");
$i->col(0, [$blue, $red]);
test_test("ok col multiple 2/3");

test_out("ok 1 - column test");
$i->col(1, [$green,$blue]);
test_test("ok col multiple 3/3");

test_out("ok 1 - column test");
$i->col(1, [$blue,$green]);
test_test("ok col multiple 4/4");

test_out("not ok 1 - column test");
test_fail(+5);
test_diag("Pixel (1, 3):");
test_diag("       got: [0,255,0]");
test_diag("  expected: [0,0,255] or");
test_diag("            [255,0,0]");
$i->col(1, [$blue, $red]);
test_test("col_all fail");

##########################################################################
# col_NONE
##########################################################################

# single things

test_out("ok 1 - column none test");
$i->col_none(0, $blue);
test_test("ok col none");

test_out("not ok 1 - column none test");
test_fail(+2);
test_diag("Pixel (0, 0) unexpectedly [255,0,0]");
$i->col_none(0, $red);
test_test("col none fail");

# multiple things

test_out("ok 1 - column none test");
$i->col_none(0, [$green, $blue]);
test_test("ok col none multiple 1/2");

test_out("ok 1 - column none test");
$i->col_none(0, [$blue, $green]);
test_test("ok col none multiple 2/2");

test_out("not ok 1 - column none test");
test_fail(+2);
test_diag("Pixel (1, 0) unexpectedly [0,0,255]");
$i->col_none(1, [$blue, $red]);
test_test("col_none multiple fail 1/2");

test_out("not ok 1 - column none test");
test_fail(+2);
test_diag("Pixel (1, 0) unexpectedly [0,0,255]");
$i->col_none(1, [$red, $blue]);
test_test("col_none multiple fail 2/2");

##########################################################################
# col_ANY
##########################################################################

# single things

test_out("ok 1 - column any test");
$i->col_any(1, $green);
test_test("ok col any");

test_out("not ok 1 - column any test");
test_fail(+2);
test_diag("No pixel correct color");
$i->col_any(0, $green);
test_diag("  expected: [0,255,0]");
test_test("col any fail");

# multiple things

test_out("ok 1 - column any test");
$i->col_any(1, [$blue, $green]);
test_test("ok col any multiple 1/2");

test_out("ok 1 - column any test");
$i->col_any(1, [$green, $blue]);
test_test("ok col any multiple 2/2");

test_out("not ok 1 - column any test");
test_fail(+4);
test_diag("No pixel correct color");
test_diag("  expected: [0,255,0] or");
test_diag("            [0,0,255]");
$i->col_any(0, [$green,$blue]);
test_test("fail col any multiple 1/2");

test_out("not ok 1 - column any test");
test_fail(+4);
test_diag("No pixel correct color");
test_diag("  expected: [0,0,255] or");
test_diag("            [0,255,0]");
$i->col_any(0, [$blue, $green]);
test_test("fail col any multiple 1/2");

########################################################################
# NEGATIVE TESTS
########################################################################

test_out("ok 1 - column test");
$i->col(-2, $red);
test_test("negative -2 is the same as 0 here");

test_out("ok 1 - column any test");
$i->col_any(-1, $green);
test_test("negative -1 is the same as 1 here");

########################################################################
# LT and GT tests (passing)
########################################################################

my $i2 = Test::Image->new([
  
  [ $red, $red, $green, $blue, $blue ],
  [ $red, $red, $green, $blue, $blue ],
  [ $red, $red, $green, $blue, $blue ],
  [ $red, $red, $green, $blue, $blue ],
  [ $red, $red, $green, $blue, $blue ],
  [ $red, $red, $green, $blue, $blue ],        

]);
isa_ok($i, "Test::Image");

### first cols

test_out("ok 1 - column test");
$i2->col("<1", $red);
test_test("first column red");

test_out("ok 1 - column test");
$i2->col("<2", $red);
test_test("first two columns red");

test_out("ok 1 - column test");
$i2->col("<=1", $red);
test_test("first two columns red");

### last cols

test_out("ok 1 - column test");
$i2->col(">4", $blue);
test_test("last column blue");

test_out("ok 1 - column test");
$i2->col(">3", $blue);
test_test("last two columns blue");

test_out("ok 1 - column test");
$i2->col(">=4", $blue);
test_test("last two columns blue");

#### last cols negative

test_out("ok 1 - column test");
$i2->col("<-2", $blue);
test_test("last column blue");

test_out("ok 1 - column test");
$i2->col("<-3", $blue);
test_test("last two columns blue");

test_out("ok 1 - column test");
$i2->col("<=-2", $blue);
test_test("last two colulms blue");

########################################################################
# LT and GT tests (failing)
########################################################################

test_out("not ok 1 - column test");
test_fail(+4);
test_diag("Pixel (0, 0):");
test_diag("       got: [255,0,0]");
test_diag("  expected: [0,255,0]");
$i2->col("<=2", $green);
test_test("failing, middle columns, less than");

test_out("not ok 1 - column test");
test_fail(+4);
test_diag("Pixel (3, 0):");
test_diag("       got: [0,0,255]");
test_diag("  expected: [0,255,0]");
$i2->col(">=2", $green);
test_test("failing, middle columns, more than");

