#!perl -T
use strict;
use Test::More tests => 1;

use_ok "constant::tiny";

diag "Testing constant::tiny $constant::tiny::VERSION, Perl $], $^X" ;
