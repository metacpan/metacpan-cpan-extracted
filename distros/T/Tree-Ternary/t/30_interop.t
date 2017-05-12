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

BEGIN { plan tests => 10 }

$ref = new Tree::Ternary;

${$ref->insert("darling")} = "buds";;
ok(${$ref->rsearch("darling")}, "buds");
ok($ref->rsearch("buds"), undef);

${$ref->rinsert("tom")} = "waits";;
ok(${$ref->search("tom")}, "waits");
ok($ref->search("waits"), undef);

ok($ref->rinsert("darling"), undef);
ok(${$ref->search("darling")}, "buds");

ok($ref->insert("tom"), undef);
ok(${$ref->rsearch("tom")}, "waits");

for ($i = 0;$i < 90;$i++) { $big .= chr($i); }
${$ref->insert($big)} = "chief";;
ok(${$ref->rsearch($big)}, "chief");

for ($i = 90;$i >= 0;$i--) { $gib .= chr($i); }
${$ref->rinsert($gib)} = "black";;
ok(${$ref->search($gib)}, "black");


