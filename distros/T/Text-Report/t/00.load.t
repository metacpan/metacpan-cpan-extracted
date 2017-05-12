#!perl
use strict;
use warnings;
use Test::More tests => 1;

# use lib '../../../lib';
BEGIN {use_ok('Text::Report');}

diag( "$Text::Report::VERSION" );
