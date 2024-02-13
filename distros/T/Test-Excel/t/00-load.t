#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Test::Excel') || print "Bail out!\n"; }
diag( "Testing Test::Excel $Test::Excel::VERSION, Perl $], $^X" );
