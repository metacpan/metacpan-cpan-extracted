#!/usr/bin/perl

####################################################################
# Description of what this test does:
# This tests the TestingImage class
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
use Test::More tests => 30;

use_ok("Test::Image::Plugin::TestingImage");

my $red   = [255,0,0];
my $green = [0,255,0];
my $blue  = [0,0,255];
my $white = [255,255,255];

# this is a slighty corrupted version of the italian flag
# it's done this way because I don't want something where all
# the rows are the same.
my $image = Test::Image::Plugin::TestingImage->new([
  [ $red, $red, $white, $white, $green, $green ],
  [ $red, $red, $white, $white, $green, $blue ],
  [ $blue, $red, $white, $white, $green, $green ],
]);
isa_ok($image, "Test::Image::Plugin::TestingImage");

# white box testing, let's check that's the right thing inside
is_deeply($image->{image}, [
  [ $red, $red, $white, $white, $green, $green ],
  [ $red, $red, $white, $white, $green, $blue ],
  [ $blue, $red, $white, $white, $green, $green ],  
], "internal strucure test");

ok(!defined(Test::Image::Plugin::TestingImage->new()), "bad not defined");
ok(!defined(Test::Image::Plugin::TestingImage->new("foo")), "bad not defined");
ok(!defined(Test::Image::Plugin::TestingImage->new(bless {}, "bar")), "bad not defined");

is($image->width, 6, "width");
is($image->height, 3, "height");

is_deeply([$image->color_at(0,0)], $red);
is_deeply([$image->color_at(1,0)], $red);
is_deeply([$image->color_at(2,0)], $white);
is_deeply([$image->color_at(3,0)], $white);
is_deeply([$image->color_at(4,0)], $green);
is_deeply([$image->color_at(5,0)], $green);

is_deeply([$image->color_at(0,1)], $red);
is_deeply([$image->color_at(1,1)], $red);
is_deeply([$image->color_at(2,1)], $white);
is_deeply([$image->color_at(3,1)], $white);
is_deeply([$image->color_at(4,1)], $green);
is_deeply([$image->color_at(5,1)], $blue);

is_deeply([$image->color_at(0,2)], $blue);
is_deeply([$image->color_at(1,2)], $red);
is_deeply([$image->color_at(2,2)], $white);
is_deeply([$image->color_at(3,2)], $white);
is_deeply([$image->color_at(4,2)], $green);
is_deeply([$image->color_at(5,2)], $green);

is_deeply([$image->color_at(6,0)], [])
  or diag(Dumper [$image->color_at(6,0)]);
is_deeply([$image->color_at(1,3)], [])
  or diag(Dumper [$image->color_at(1,3)]);

########################################
# breaking enapsulation test!

# check that instanciating one of these works
use_ok("Test::Image");
my $ti = Test::Image->new([
  [ $red, $red, $white, $white, $green, $green ],
  [ $red, $red, $white, $white, $green, $blue ],
  [ $blue, $red, $white, $white, $green, $green ],
]);

# look inside the black box!
is_deeply($ti->{image}->{image}, [
  [ $red, $red, $white, $white, $green, $green ],
  [ $red, $red, $white, $white, $green, $blue ],
  [ $blue, $red, $white, $white, $green, $green ],
], "breaking encapsulation");
