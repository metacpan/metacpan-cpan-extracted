#!/usr/bin/perl

# This script can be run from anywhere, disrespecting cwd.
# this script calls module1 and module1 also uses lib::abs
# to use 'relative' as libdir.
# Also, after importing required modules it unimports relative,
# so this path will not stay in inc

use lib '../../lib';
use lib::abs 'lib';
use module1;
print STDERR "\@INC=\n".join "\n",@INC,"";