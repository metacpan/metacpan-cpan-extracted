#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use blib;
use jsFind;

BEGIN { use_ok('jsFind'); }

my $t = new jsFind B => 4;

isa_ok($t,'jsFind');
isa_ok($t->root,'jsFind::Node');

cmp_ok($t->B, '==', 4, "B is 4");

