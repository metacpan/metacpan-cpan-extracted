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
use Tree::Ternary qw( :attrib );

BEGIN { plan tests => 18 }

ok($ref = new Tree::Ternary);
ok(ref($ref), 'Tree::Ternary');

ok(defined(SPLIT_CHAR));
ok(defined(LO_KID));
ok(defined(EQ_KID));
ok(defined(HI_KID));
ok(defined(PAYLOAD));
ok(defined(NODE_COUNT));
ok(defined(TERMINAL_COUNT));

ok(! defined($ref->[SPLIT_CHAR]));
ok(! defined($ref->[LO_KID]));
ok(! defined($ref->[EQ_KID]));
ok(! defined($ref->[HI_KID]));
ok(! defined($ref->[PAYLOAD]));
ok($ref->[NODE_COUNT], 0);
ok($ref->[TERMINAL_COUNT], 0);

ok($ref->nodes(), 0);
ok($ref->terminals(), 0);

