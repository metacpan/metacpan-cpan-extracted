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

BEGIN { plan tests => 38 }

$ref = new Tree::Ternary;

ok($ref->nodes(), 0);
ok($ref->terminals(), 0);

ok(ref($a = $ref->insert("firewater")), 'SCALAR');
ok($ref->nodes(), 9);
ok($ref->terminals(), 1);

ok(ref($a = $ref->insert("firewater")), '');
ok($ref->nodes(), 9);
ok($ref->terminals(), 1);

ok(ref($a = $ref->insert("stereolab")), 'SCALAR');
ok($ref->nodes(), 18);
ok($ref->terminals(), 2);

ok(ref($a = $ref->insert("tirewater")), 'SCALAR');
ok($ref->nodes(), 27);
ok($ref->terminals(), 3);

ok(ref($a = $ref->insert("tidewater")), 'SCALAR');
ok($ref->nodes(), 34);
ok($ref->terminals(), 4);

ok(ref($a = $ref->insert("tidewader")), 'SCALAR');
ok($ref->nodes(), 37);
ok($ref->terminals(), 5);

ok(ref($a = $ref->insert("firewater")), '');
ok($ref->nodes(), 37);
ok($ref->terminals(), 5);

ok(ref($a = $ref->insert("")), 'SCALAR');
ok($ref->nodes(), 37);
ok($ref->terminals(), 6);

ok(ref($a = $ref->insert("stereo")), 'SCALAR');
ok($ref->nodes(), 37);
ok($ref->terminals(), 7);

ok(ref($a = $ref->insert("")), '');
ok($ref->nodes(), 37);
ok($ref->terminals(), 7);

for ($i = 0;$i < 256;$i++) { $big .= chr($i); }
ok(ref($a = $ref->insert($big)), 'SCALAR');
ok($ref->nodes(), 293);
ok($ref->terminals(), 8);

ok(ref($a = $ref->insert($big)), '');
ok($ref->nodes(), 293);
ok($ref->terminals(), 8);


