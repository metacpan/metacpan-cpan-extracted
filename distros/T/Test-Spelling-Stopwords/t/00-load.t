#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('Test::Spelling::Stopwords') || print "Bail out!\n"; }
diag( "Testing Test::Spelling::Stopwords $Test::Spelling::Stopwords::VERSION, Perl $], $^X" );

done_testing;
