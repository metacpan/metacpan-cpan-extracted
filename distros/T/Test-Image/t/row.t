#!/usr/bin/perl

####################################################################
# Description of what this test does:
# This tests the single line row_* functions
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
  [ $red,  $red,  $red,  $red,   $red,  $red  ],
  [ $blue, $blue, $blue, $green, $blue, $blue ],
]);
isa_ok($i, "Test::Image");

use Test::Builder::Tester;

##########################################################################
# ROW_ALL
##########################################################################

# single things

test_out("ok 1 - row test");
$i->row(0, $red);
test_test("ok row");

test_out("ok 1 - row test");
$i->row_all(0, $red);
test_test("ok row all");

test_out("not ok 1 - row test");
test_fail(+4);
test_diag("Pixel (3, 1):");
test_diag("       got: [0,255,0]");
test_diag("  expected: [0,0,255]");
$i->row(1, $blue);
test_test("row fail");

# multiple things

test_out("ok 1 - row test");
$i->row(0, [$red,$blue]);
test_test("ok row multiple 1/3");

test_out("ok 1 - row test");
$i->row(0, [$blue, $red]);
test_test("ok row multiple 2/3");

test_out("ok 1 - row test");
$i->row(1, [$green,$blue]);
test_test("ok row multiple 3/3");

test_out("ok 1 - row test");
$i->row(1, [$blue,$green]);
test_test("ok row multiple 4/4");

test_out("not ok 1 - row test");
test_fail(+5);
test_diag("Pixel (3, 1):");
test_diag("       got: [0,255,0]");
test_diag("  expected: [0,0,255] or");
test_diag("            [255,0,0]");
$i->row(1, [$blue, $red]);
test_test("row_all fail");

##########################################################################
# ROW_NONE
##########################################################################

# single things

test_out("ok 1 - row none test");
$i->row_none(0, $blue);
test_test("ok row none");

test_out("not ok 1 - row none test");
test_fail(+2);
test_diag("Pixel (0, 0) unexpectedly [255,0,0]");
$i->row_none(0, $red);
test_test("row none fail");

# multiple things

test_out("ok 1 - row none test");
$i->row_none(0, [$green, $blue]);
test_test("ok row none multiple 1/2");

test_out("ok 1 - row none test");
$i->row_none(0, [$blue, $green]);
test_test("ok row none multiple 2/2");

test_out("not ok 1 - row none test");
test_fail(+2);
test_diag("Pixel (0, 1) unexpectedly [0,0,255]");
$i->row_none(1, [$blue, $red]);
test_test("row_none multiple fail 1/2");

test_out("not ok 1 - row none test");
test_fail(+2);
test_diag("Pixel (0, 1) unexpectedly [0,0,255]");
$i->row_none(1, [$red, $blue]);
test_test("row_none multiple fail 2/2");

##########################################################################
# ROW_ANY
##########################################################################

# single things

test_out("ok 1 - row any test");
$i->row_any(1, $green);
test_test("ok row any");

test_out("not ok 1 - row any test");
test_fail(+2);
test_diag("No pixel correct color");
$i->row_any(0, $green);
test_diag("  expected: [0,255,0]");
test_test("row any fail");

# multiple things

test_out("ok 1 - row any test");
$i->row_any(1, [$blue, $green]);
test_test("ok row any multiple 1/2");

test_out("ok 1 - row any test");
$i->row_any(1, [$green, $blue]);
test_test("ok row any multiple 2/2");

test_out("not ok 1 - row any test");
test_fail(+4);
test_diag("No pixel correct color");
test_diag("  expected: [0,255,0] or");
test_diag("            [0,0,255]");
$i->row_any(0, [$green,$blue]);
test_test("fail row any multiple 1/2");

test_out("not ok 1 - row any test");
test_fail(+4);
test_diag("No pixel correct color");
test_diag("  expected: [0,0,255] or");
test_diag("            [0,255,0]");
$i->row_any(0, [$blue, $green]);
test_test("fail row any multiple 1/2");

########################################################################
# NEGATIVE TESTS
########################################################################

test_out("ok 1 - row test");
$i->row(-2, $red);
test_test("negative -2 is the same as 0 here");

test_out("ok 1 - row any test");
$i->row_any(-1, $green);
test_test("negative -1 is the same as 1 here");

########################################################################
# LT and GT tests (passing)
########################################################################

my $i2 = Test::Image->new([
  [ $red,  $red,  $red,  $red,   $red,  $red  ],
  [ $red,  $red,  $red,  $red,   $red,  $red  ],
  [ $green,  $green, $green, $green, $green, $green ],
  [ $blue,  $blue, $blue, $blue, $blue, $blue ],
  [ $blue,  $blue, $blue, $blue, $blue, $blue ],
]);
isa_ok($i, "Test::Image");

### first rows

test_out("ok 1 - row test");
$i2->row("<1", $red);
test_test("first row red");

test_out("ok 1 - row test");
$i2->row("<2", $red);
test_test("first two rows red");

test_out("ok 1 - row test");
$i2->row("<=1", $red);
test_test("first two rows red");

### last rows

test_out("ok 1 - row test");
$i2->row(">4", $blue);
test_test("last row blue");

test_out("ok 1 - row test");
$i2->row(">3", $blue);
test_test("last two rows blue");

test_out("ok 1 - row test");
$i2->row(">=4", $blue);
test_test("last two rows blue");

#### last rows negative

test_out("ok 1 - row test");
$i2->row("<-2", $blue);
test_test("last row blue");

test_out("ok 1 - row test");
$i2->row("<-3", $blue);
test_test("last two rows blue");

test_out("ok 1 - row test");
$i2->row("<=-2", $blue);
test_test("last two rows blue");

########################################################################
# LT and GT tests (failing)
########################################################################

test_out("not ok 1 - row test");
test_fail(+4);
test_diag("Pixel (0, 0):");
test_diag("       got: [255,0,0]");
test_diag("  expected: [0,255,0]");
$i2->row("<=2", $green);
test_test("failing, middle row, less than");

test_out("not ok 1 - row test");
test_fail(+4);
test_diag("Pixel (0, 3):");
test_diag("       got: [0,0,255]");
test_diag("  expected: [0,255,0]");
$i2->row(">=2", $green);
test_test("failing, middle row, more than");

