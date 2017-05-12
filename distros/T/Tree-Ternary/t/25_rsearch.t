#!/usr/local/bin/perl
###########################################################################
#
#  Tree::Ternary
#
#  Copyright (C) 1999, Mark Rogaski; all rights reserved.
#
#  This module is free software.  You can redistribute it and/or
#  modify it under the terms of the Artistic License 2.0.
#
#  This program is distributed in the hope that it will be useful,
#  but without any warranty; without even the implied warranty of
#  merchantability or fitness for a particular purpose.
#
###########################################################################

use Test;
use Tree::Ternary;

BEGIN { plan tests => 13 }

$ref = new Tree::Ternary;

${$ref->rinsert("foobar")} = "HNB";
${$ref->rinsert("bloodhound")} = "gang";

ok(ref($ref->rsearch("foobar")), 'SCALAR');
ok(${$ref->rsearch("foobar")}, 'HNB');

ok(ref($ref->rsearch("foo")), '');

ok(ref($ref->rsearch("foobaz")), '');

ok(ref($ref->rsearch("pianosaurus")), '');

ok(ref($ref->rsearch("blood")), '');

ok(ref($ref->rsearch("bloodhound")), 'SCALAR');
ok(${$ref->rsearch("bloodhound")}, 'gang');

${$ref->rinsert("blood")} = "sausage";

ok(ref($ref->rsearch("blood")), 'SCALAR');
ok(${$ref->rsearch("blood")}, 'sausage');

ok(ref($ref->rsearch("")), '');

${$ref->rinsert("")} = "NULL";

ok(ref($ref->rsearch("")), 'SCALAR');
ok(${$ref->rsearch("")}, 'NULL');

