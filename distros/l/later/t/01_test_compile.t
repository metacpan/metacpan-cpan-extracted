#
#   $Id: 01_test_compile.t,v 1.2 2007-01-09 17:18:28 erwan Exp $
#
#   test that 'later' compiles
#

package main;

use strict;
use warnings;
use Test::More tests => 3;
use lib "../lib/";

eval "use later 'test1';";
ok( (!defined $@ || $@ eq ""), "use later succeeds on existing module");

eval "use later 'whatever';";
ok( (!defined $@ || $@ eq ""), "use later succeeds on non existing module");

# error if no module name provided
eval "use later;";
ok( (defined $@ && $@ =~ /must be followed by a module name/), "use later fails if no module name");
