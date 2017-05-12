#
#   $Id: 09_test_later_in_later.t,v 1.1 2007-01-23 14:09:56 erwan Exp $
#
#   test that using later a module that can't compile makes the code die
#

package main;

use strict;
use warnings;
use Test::More tests => 1;
use lib "../lib/",".";        # when run from t/
use lib "t/","lib/";          # when running from root 

use later "My::Module3", 'foo';

is(foo(),"yaph","right answer!");
