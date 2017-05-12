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

${$ref->insert("foobar")} = "HNB";
${$ref->insert("bloodhound")} = "gang";

ok(ref($ref->search("foobar")), 'SCALAR');
ok(${$ref->search("foobar")}, 'HNB');

ok(ref($ref->search("foo")), '');

ok(ref($ref->search("foobaz")), '');

ok(ref($ref->search("pianosaurus")), '');

ok(ref($ref->search("blood")), '');

ok(ref($ref->search("bloodhound")), 'SCALAR');
ok(${$ref->search("bloodhound")}, 'gang');

${$ref->insert("blood")} = "sausage";

ok(ref($ref->search("blood")), 'SCALAR');
ok(${$ref->search("blood")}, 'sausage');

ok(ref($ref->search("")), '');

${$ref->insert("")} = "NULL";

ok(ref($ref->search("")), 'SCALAR');
ok(${$ref->search("")}, 'NULL');

