#!/usr/local/bin/perl
###########################################################################
# $Id: 10_insert.t,v 1.2 1999/09/21 05:42:22 wendigo Exp $
###########################################################################
#
# Author: Mark Rogaski <wendigo@pobox.com>
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 1999/09/21 05:42:22 $
#
###########################################################################
#
# See README for license information.
#
###########################################################################

use Test;
use Tree::Ternary_XS;

BEGIN { plan tests => 38 }

$ref = new Tree::Ternary_XS;

ok($ref->nodes(), 0);
ok($ref->terminals(), 0);

ok($ref->insert("firewater"));
ok($ref->nodes(), 9);
ok($ref->terminals(), 1);

ok($ref->insert("firewater"));
ok($ref->nodes(), 9);
ok($ref->terminals(), 1);

ok($ref->insert("stereolab"));
ok($ref->nodes(), 18);
ok($ref->terminals(), 2);

ok($ref->insert("tirewater"));
ok($ref->nodes(), 27);
ok($ref->terminals(), 3);

ok($ref->insert("tidewater"));
ok($ref->nodes(), 34);
ok($ref->terminals(), 4);

ok($ref->insert("tidewader"));
ok($ref->nodes(), 37);
ok($ref->terminals(), 5);

ok($ref->insert("firewater"));
ok($ref->nodes(), 37);
ok($ref->terminals(), 5);

ok($ref->insert(""));
ok($ref->nodes(), 37);
ok($ref->terminals(), 6);

ok($ref->insert("stereo"));
ok($ref->nodes(), 37);
ok($ref->terminals(), 7);

ok($ref->insert(""));
ok($ref->nodes(), 37);
ok($ref->terminals(), 7);

for ($i = 1;$i < 256;$i++) { $big .= chr($i); }
ok($ref->insert($big));
ok($ref->nodes(), 292);
ok($ref->terminals(), 8);

ok($ref->insert($big));
ok($ref->nodes(), 292);
ok($ref->terminals(), 8);


