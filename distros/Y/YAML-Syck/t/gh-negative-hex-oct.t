use strict;
use warnings;
use Test::More;
use YAML::Syck;

# Negative hex and octal values should parse correctly with ImplicitTyping.
# Previously, grok_hex() and grok_oct() received the leading '-' sign which
# they don't handle, silently returning 0.

local $YAML::Syck::ImplicitTyping = 1;

# Hex
is( Load("--- 0xff\n"),  255,  "hex 0xff" );
is( Load("--- 0x0\n"),   0,    "hex 0x0" );
is( Load("--- 0x1\n"),   1,    "hex 0x1" );
is( Load("--- -0xff\n"), -255, "negative hex -0xff" );
is( Load("--- -0x1\n"),  -1,   "negative hex -0x1" );
is( Load("--- -0x0\n"),  0,    "negative hex -0x0" );

# Octal
is( Load("--- 0777\n"),  511,  "octal 0777" );
is( Load("--- 0644\n"),  420,  "octal 0644" );
is( Load("--- -0777\n"), -511, "negative octal -0777" );
is( Load("--- -0644\n"), -420, "negative octal -0644" );
is( Load("--- -010\n"),  -8,   "negative octal -010" );

# Positive values still work
is( Load("--- 0xDEAD\n"), 0xDEAD, "hex 0xDEAD" );
is( Load("--- -0xDEAD\n"), -0xDEAD, "negative hex -0xDEAD" );

done_testing;
