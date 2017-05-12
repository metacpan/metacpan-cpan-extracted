#!/usr/bin/perl -w
## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl P.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;


use Test::More tests => 4;

our @ISA;
use Xporter;

ok(Xporter->can('import'), "Xporter can import");


ok(main->can('import'), "main can import");


ok((1 == grep m{Xporter}, @ISA), "ISA has Xporter" );


@ISA=();
ok(!main->can('import'), "undefining ISA=> main can't import");

