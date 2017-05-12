#!/usr/bin/perl -w
## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl P.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;


use Test::More tests => 2;

our @ISA;
use Xporter qw(import);


ok(main->can('import'), "main can import");


ok((0 == grep m{Xporter}, @ISA), "ISA doesn't have Xporter");



