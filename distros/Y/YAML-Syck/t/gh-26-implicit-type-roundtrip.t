use strict;
use warnings;

use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use Test::More tests => 18;
use YAML::Syck qw(Dump Load);

# GH #26: Strings matching YAML implicit types (hex, float specials,
# sexagesimal) must be quoted on dump so they roundtrip correctly.

$YAML::Syck::ImplicitTyping = 1;

# --- Hex integers: 0x10 was dumped unquoted, loaded back as decimal 16 ---
is( Load(Dump("0x10")),  "0x10",  "roundtrip hex string 0x10" );
is( Load(Dump("0x1A")),  "0x1A",  "roundtrip hex string 0x1A" );
is( Load(Dump("0xDEAD")), "0xDEAD", "roundtrip hex string 0xDEAD" );

# --- Float specials: .inf/.nan were dumped unquoted ---
is( Load(Dump(".inf")),   ".inf",   "roundtrip string .inf" );
is( Load(Dump("-.inf")),  "-.inf",  "roundtrip string -.inf" );
is( Load(Dump("+.inf")),  "+.inf",  "roundtrip string +.inf" );
is( Load(Dump(".nan")),   ".nan",   "roundtrip string .nan" );
is( Load(Dump(".Inf")),   ".Inf",   "roundtrip string .Inf" );
is( Load(Dump(".NaN")),   ".NaN",   "roundtrip string .NaN" );
is( Load(Dump(".INF")),   ".INF",   "roundtrip string .INF" );

# --- Sexagesimal (base-60): 1:30 was dumped unquoted, loaded as 90 ---
is( Load(Dump("1:30")),    "1:30",    "roundtrip sexagesimal string 1:30" );
is( Load(Dump("1:30:00")), "1:30:00", "roundtrip sexagesimal string 1:30:00" );

# --- Plus-prefixed integers: +1 was dumped unquoted, loaded as 1 ---
is( Load(Dump("+1")),  "+1",  "roundtrip string +1" );
is( Load(Dump("+42")), "+42", "roundtrip string +42" );

# --- Verify these strings are quoted in the YAML output ---
like( Dump("0x10"),  qr/['"]0x10['"]/, "0x10 is quoted in dump output" );
like( Dump(".inf"),  qr/['"]\.inf['"]/, ".inf is quoted in dump output" );
like( Dump("1:30"),  qr/['"]1:30['"]/, "1:30 is quoted in dump output" );
like( Dump("+1"),    qr/['"][+]1['"]/, "+1 is quoted in dump output" );
