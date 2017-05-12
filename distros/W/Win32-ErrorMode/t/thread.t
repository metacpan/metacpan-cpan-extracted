use strict;
use warnings;
use Test::More;
use Win32::ErrorMode qw( :all );

plan skip_all => 'test requires working GetThreadErrorMode and SetThreadErrorMode'
  unless Win32::ErrorMode::_has_thread();
plan tests => 5;

my $mode = GetThreadErrorMode();

note "mode = $mode\n";

like $mode, qr{^[0-9]+$}, "mode looks like an integer";

is $ThreadErrorMode, $mode, "tie interface get ($mode)";

SetThreadErrorMode(0);

is GetThreadErrorMode(), 0, "SetThreadErrorMode() updates ThreadErrorMode";

is $ThreadErrorMode, 0, "tie interface get (0)";

$ThreadErrorMode = 0x3;

is GetThreadErrorMode(), 0x3, "tie interface set(3)";
