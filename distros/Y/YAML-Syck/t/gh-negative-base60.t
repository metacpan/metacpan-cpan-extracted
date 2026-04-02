use strict;
use warnings;
use Test::More;
use YAML::Syck;

# Negative int#base60 values wrapped around as unsigned integers because
# the total was computed as UV. The sign must be stripped before parsing
# and re-applied afterward.

local $YAML::Syck::ImplicitTyping = 1;

# Positive base60 (sanity check)
is( Load("--- 1:30:00\n"), 5400,  "base60 1:30:00 = 5400" );
is( Load("--- 0:30\n"),    30,    "base60 0:30 = 30" );
is( Load("--- 1:0:0\n"),   3600,  "base60 1:0:0 = 3600" );

# Negative base60
is( Load("--- -1:30:00\n"), -5400, "negative base60 -1:30:00 = -5400" );
is( Load("--- -0:30\n"),    -30,   "negative base60 -0:30 = -30" );
is( Load("--- -1:0:0\n"),   -3600, "negative base60 -1:0:0 = -3600" );
is( Load("--- -0:0\n"),     0,     "negative base60 -0:0 = 0" );

done_testing;
