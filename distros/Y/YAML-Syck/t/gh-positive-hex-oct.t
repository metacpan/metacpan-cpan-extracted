use strict;
use warnings;
use FindBin;
BEGIN { push @INC, $FindBin::Bin }
use TestYAML ();
use Test::More tests => 8;
use YAML::Syck qw(Load);

# GH: positive (+) sign on hex and octal integers returns 0 instead of the
# correct value.  The YAML 1.0 implicit typing regex for int#hex is
# [-+]?0x[0-9a-fA-F,]+ and int#oct is [-+]?0[0-7,]+, so a leading '+'
# must be stripped before parsing, just like '-' already is.

$YAML::Syck::ImplicitTyping = 1;

# --- positive hex ---
is( Load("--- +0xff\n"), 255,     "positive hex +0xff" );
is( Load("--- +0x1\n"),  1,       "positive hex +0x1" );
is( Load("--- +0x0\n"),  0,       "positive hex +0x0" );
is( Load("--- +0xDEAD\n"), 0xDEAD, "positive hex +0xDEAD" );

# --- positive octal ---
is( Load("--- +0777\n"), 511,  "positive octal +0777" );
is( Load("--- +0644\n"), 420,  "positive octal +0644" );
is( Load("--- +010\n"),  8,    "positive octal +010" );
is( Load("--- +00\n"),   0,    "positive octal +00" );
