use strict;
use warnings;

use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use Test::More tests => 10;
use YAML::Syck qw(Load);

# GH #132 - base60 (sexagesimal) parsing safety
# The parser walked a pointer before the start of the buffer when
# processing the leftmost segment of a base-60 value.  Verify that
# int#base60 and float#base60 produce correct results and do not
# crash or read out-of-bounds.

$YAML::Syck::ImplicitTyping = 1;

# --- int#base60 ---
is( Load("--- 1:0:0\n"),    3600,  "int base60: 1:0:0 = 3600" );
is( Load("--- 1:30:45\n"),  5445,  "int base60: 1:30:45 = 5445" );
is( Load("--- 0:30\n"),     30,    "int base60: 0:30 = 30" );
is( Load("--- 0:0\n"),      0,     "int base60: 0:0 = 0" );

# --- float#base60 ---
is( Load("--- 1:30:45.5\n"),  5445.5,  "float base60: 1:30:45.5 = 5445.5" );
is( Load("--- 0:0.5\n"),      0.5,     "float base60: 0:0.5 = 0.5" );

# --- edge cases: single-colon values ---
is( Load("--- 59:59\n"),    3599,  "int base60: 59:59 = 3599" );

# --- multi-segment ---
is( Load("--- 1:2:3:4\n"),  223384, "int base60: 1:2:3:4 = 1*216000+2*3600+3*60+4" );

# --- negative base60 (parsed as string, not base60 - verify no crash) ---
my $neg = Load("--- -1:30\n");
ok( defined $neg, "negative sexagesimal loads without crash" );

# --- large segment count (stress the loop) ---
is( Load("--- 1:0:0:0\n"), 216000, "int base60: 1:0:0:0 = 216000" );
