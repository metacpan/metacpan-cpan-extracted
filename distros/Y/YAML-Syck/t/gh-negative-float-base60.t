use strict;
use warnings;
use Test::More;
use YAML::Syck;

# Negative float#base60 values were incorrect because the sign was not
# stripped before the right-to-left accumulation loop.  Atof("-1") applied
# the negation to only the highest segment, producing a wrong total.
# The fix mirrors the int#base60 pattern: strip sign, accumulate unsigned,
# then negate.

local $YAML::Syck::ImplicitTyping = 1;

# Positive float base60 (sanity check)
is( Load("--- 1:30:30.5\n"), 5430.5, "float base60 1:30:30.5 = 5430.5" );
is( Load("--- 0:30.5\n"),    30.5,   "float base60 0:30.5 = 30.5" );
is( Load("--- 1:0:0.25\n"),  3600.25,"float base60 1:0:0.25 = 3600.25" );

# Negative float base60
is( Load("--- -1:30:30.5\n"), -5430.5, "negative float base60 -1:30:30.5 = -5430.5" );
is( Load("--- -0:30.5\n"),    -30.5,   "negative float base60 -0:30.5 = -30.5" );
is( Load("--- -1:0:0.25\n"),  -3600.25,"negative float base60 -1:0:0.25 = -3600.25" );
is( Load("--- -0:0.0\n"),     0,       "negative float base60 -0:0.0 = 0" );

# Positive sign (explicit +)
is( Load("--- +1:30:30.5\n"), 5430.5, "explicit + float base60 +1:30:30.5 = 5430.5" );

done_testing;
