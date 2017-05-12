#
#   $Id: 06_test_default_modules.t,v 1.2 2007-01-22 15:58:27 erwan Exp $
#
#   test that using later a module that can't compile makes the code die
#

package main;

use strict;
use warnings;
use Test::More tests => 2;
use lib "../lib/",".";        # when run from t/
use lib "t/","lib/";          # when running from root 

use later "Data::Dumper";

my $var;

# calling undefine sub
eval { $var = Dumper(1,"blou",[]); };
ok( (!defined $@ || $@ eq ""), "loaded Data::Dumper" );

my $expect = "".
    "\$VAR1 = 1;\n".
    "\$VAR2 = 'blou';\n".
    "\$VAR3 = [];\n";

is($var,$expect,"Dumper returned the expected result");

