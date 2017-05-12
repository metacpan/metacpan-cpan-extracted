#!/usr/bin/perl

####################################################################
# Description of what this test does:
# Tests the width and heigth testing functions
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
use Test::More tests => 11;

use Test::Builder::Tester;
use_ok "Test::Image";

# you know, these don't really matter

my $red   = [255,0,0];
my $green = [0,255,0];
my $blue  = [0,0,255];

my $i = Test::Image->new([
  [ $red, $green, ],
  [ $blue, $green ],
  [ $red, $blue ],
]);

isa_ok($i, "Test::Image");

#################################################################
# width
#################################################################

test_out("ok 1 - image width");
$i->width(2);
test_test("width ok");

test_out("not ok 1 - image width");
test_fail(+2);
test_diag("Image 2 pixels wide, not 3 pixels as expected");
$i->width(3);
test_test("width fail");

#################################################################
# heigth
#################################################################

test_out("ok 1 - image height");
$i->height(3);
test_test("height ok");

test_out("not ok 1 - image height");
test_fail(+2);
test_diag("Image 3 pixels tall, not 99 pixels as expected");
$i->height(99);
test_test("height fail");

#################################################################
# total size
#################################################################

test_out("ok 1 - image total size");
$i->total_size(6);
test_test("total size ok");

test_out("not ok 1 - image total size");
test_fail(+2);
test_diag("Image 6 pixels in total, not 99 pixels as expected");
$i->total_size(99);
test_test("total size fail");

#################################################################
# size
#################################################################

test_out("ok 1 - image size");
$i->size(2,3);
test_test("size ok");

test_out("not ok 1 - image size");
test_fail(+2);
test_diag("Image size (2,3) not (2,99) as expected");
$i->size(2,99);
test_test("size fail 1/2");

test_out("not ok 1 - image size");
test_fail(+2);
test_diag("Image size (2,3) not (99,3) as expected");
$i->size(99,3);
test_test("size fail 1/2");

