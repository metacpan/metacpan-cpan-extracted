#
#   $Id: 05_test_unknown_module.t,v 1.1 2007-01-09 17:18:28 erwan Exp $
#
#   test using later a module that does not exist
#

package main;

use strict;
use warnings;
use Test::More tests => 1;
use lib "../lib/",".";        # when run from t/
use lib "t/","lib/";          # when running from root 

use later 'Flfdjlkrk::Dadlfjha';

# calling undefine sub
eval { foo(); };
ok( (defined $@ && $@ =~ /failed to use package .* inside package main/i), "unkown module causes exception" );

