use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
use Test::More;

plan tests => 5;

use Tie::Handle::SkipHeader;

local *FH;

tie *FH, 'Tie::Handle::SkipHeader', "<", "t/data/header.txt";

ok( tied(*FH), "handle is tied" );
is( tell(*FH), 0, "tell() reports 0" );
is( scalar<FH>, "The quick brown fox jumped over the lazy dog.\n", "readline correct" );
ok( seek(*FH,0,0), "seek() 0 from start" );
is( scalar<FH>, "The quick brown fox jumped over the lazy dog.\n", "readline correct" );

#
# This file is part of Tie-Handle-Offset
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
