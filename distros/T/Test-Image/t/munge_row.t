#!/usr/bin/perl

####################################################################
# Description of what this test does:
# testing of the _munge_row function
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
use Test::More tests => 19;

use_ok "Test::Image";

my $red   = [255,0,0];
my $green = [0,255,0];
my $blue  = [0,0,255];
my $white = [255,255,255];

my $i = Test::Image->new([
  [ $red,  $red,  $red,  $red,   $red,  $red  ],
  [ $red,  $red,  $red,  $red,   $red,  $red  ],
  [ $green,  $green, $green, $green, $green, $green ],
  [ $blue,  $blue, $blue, $blue, $blue, $blue ],
  [ $blue,  $blue, $blue, $blue, $blue, $blue ],
]);

#################################

is_deeply([$i->_munge_value("height", 42)], [42,42], "basic numbers not munged");

is_deeply([$i->_munge_value("height", -1)], [4,4], "negative numbers 1/4");
is_deeply([$i->_munge_value("height", -2)], [3,3], "negative numbers 2/4");
is_deeply([$i->_munge_value("height", -3)], [2,2], "negative numbers 3/4");
is_deeply([$i->_munge_value("height", -4)], [1,1], "negative numbers 4/4");

is_deeply([$i->_munge_value("height", "<3") ], [0,2], "<");
is_deeply([$i->_munge_value("height", "<=3")], [0,3], "<=");
is_deeply([$i->_munge_value("height", ">3") ], [4,4], ">");
is_deeply([$i->_munge_value("height", ">=3")], [3,4], ">=");

is_deeply([$i->_munge_value("width", 42)], [42,42], "basic numbers not munged");

is_deeply([$i->_munge_value("width", -1)], [5,5], "negative numbers 1/4");
is_deeply([$i->_munge_value("width", -2)], [4,4], "negative numbers 2/4");
is_deeply([$i->_munge_value("width", -3)], [3,3], "negative numbers 3/4");
is_deeply([$i->_munge_value("width", -4)], [2,2], "negative numbers 4/4");

is_deeply([$i->_munge_value("width", "<3") ], [0,2], "<");
is_deeply([$i->_munge_value("width", "<=3")], [0,3], "<=");
is_deeply([$i->_munge_value("width", ">3") ], [4,5], ">");
is_deeply([$i->_munge_value("width", ">=3")], [3,5], ">=");




