#!/usr/bin/perl

####################################################################
# Description of what this test does:
# This just checks to see if the RGB function works
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
use Test::More tests => 12;

# load the module
use_ok("Test::Image");

# just an array

is_deeply([Test::Image::_rgb([255,128,64])],[255,128,64], "array works");

# using a hex thingy

is_deeply([Test::Image::_rgb("fF0000")],[255,0,0], "hex 1");
is_deeply([Test::Image::_rgb("00Ff00")],[0,255,0], "hex 2");
is_deeply([Test::Image::_rgb("0000fF")],[0,0,255], "hex 3");

is_deeply([Test::Image::_rgb("#fF0000")],[255,0,0], "hex 1#");
is_deeply([Test::Image::_rgb("#00FF00")],[0,255,0], "hex 2#");
is_deeply([Test::Image::_rgb("#0000Ff")],[0,0,255], "hex 3#");

SKIP: {
  skip "No Graphics::ColorNames", 4 unless $INC{"Graphics/ColorNames.pm"};

  # using a named colour
  is_deeply([Test::Image::_rgb("red")],[255,0,0], "name 1");
  is_deeply([Test::Image::_rgb("green")],[0,255,0], "name 2");
  is_deeply([Test::Image::_rgb("blue")],[0,0,255], "name 3");
  
  
  # I should use Test::Exception, but I'm skipping the dependancy
  eval {
    Test::Image::_rgb("Really Horrible Yellow");  # not a real colour
  };
  ok($@, "threw an error with a bad color");
}