use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
use Test::More;

plan tests => 18;

use Tie::Handle::Offset;

local *FH;

tie *FH, 'Tie::Handle::Offset', "<", "t/data/test.txt", {offset => 1};

ok( tied(*FH), "handle is tied with offset 1" );
is( tell(*FH), 0, "tell() reports 0" );
is( scalar<FH>, "ine one\n", "readline correct" );
ok( seek(*FH,8,0), "seek() 8 from start" );
is( scalar<FH>, "Line two\n", "readline correct" );
my $cur = tell(*FH);
is( seek(*FH,-100,2), '', "seek past start of file fails to seek" );
is( tell(*FH), $cur, "tell() reports seek() didn't move" );
seek(*FH,0,2);
my $size = tell(*FH);
seek(*FH,$cur,0);
is( seek(*FH,-($size+1),2), '', "seek into offset fails to seek" );
is( tell(*FH), $cur, "tell() reports seek() didn't move" ) or diag <FH>;
is( seek(*FH,-10,2), 1, "seek back from end" );
is( scalar<FH>, "Line four\n", "readline correct" );

untie *FH;
tie *FH, 'Tie::Handle::Offset', "<", "t/data/test.txt", {offset => 1000};
ok( tied(*FH), "handle is tied with offset 1000 (too big)" );
is( tell(*FH), 0, "tell() reports 0" );
is( scalar<FH>, undef, "readline correct (undef)" );
is( seek(*FH,0,0), 1, "seek to start" );
is( scalar<FH>, undef, "readline correct (undef)" );
is( seek(*FH,-$size,2), '', "seek into offset fails to seek" );
is( scalar<FH>, undef, "readline correct (undef)" );

#
# This file is part of Tie-Handle-Offset
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
