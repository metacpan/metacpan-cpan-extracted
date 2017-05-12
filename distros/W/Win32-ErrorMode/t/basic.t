use strict;
use warnings;
use Test::More tests => 5;
use Win32::ErrorMode qw( :all );

my $mode = GetErrorMode();

note "mode = $mode\n";

like $mode, qr{^[0-9]+$}, "mode looks like an integer";

is $ErrorMode, $mode, "tie interface get ($mode)";

SetErrorMode(0);

is GetErrorMode(), 0, "SetErrorMode() updates ErrorMode";

is $ErrorMode, 0, "tie interface get (0)";

$ErrorMode = 0x3;

is GetErrorMode(), 0x3, "tie interface set(3)";

