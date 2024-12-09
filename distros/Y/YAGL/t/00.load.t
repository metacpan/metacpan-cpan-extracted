#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 1;

BEGIN { use_ok 'YAGL' }

diag("Testing YAGL $YAGL::VERSION");
