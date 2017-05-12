#
#   $Id: 04_test_invalid_module.t,v 1.1 2007-01-09 17:18:28 erwan Exp $
#
#   test that using later a module that can't compile makes the code die
#

package main;

use strict;
use warnings;
use Test::More tests => 1;
use lib "../lib/",".";        # when run from t/
use lib "t/","lib/";          # when running from root 

use later 'test4';

# calling undefine sub
eval { foo(); };
ok( (defined $@ && $@ =~ /failed to use package test4 inside package main/i), "not compilable module cause exception" );

