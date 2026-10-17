use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

my $fab = Text::Fab->new();
$fab->cfg__set('Fab/call_stack_prefixes', ['Fab/', 'Fab/level1/', 'Fab/level2/']);

$fab->cfg__set('my_var', 'base_value');
$fab->cfg__set('Fab/my_var', 'root_value');
$fab->cfg__set('Fab/level1/my_var', 'level1_value');

is($fab->cfg__get_prefixed('my_var'), undef,
   'cfg__get_prefixed returns undef when key is missing at current prefix (no scan)');

$fab->cfg__set('Fab/level2/my_var', 'current_value');
is($fab->cfg__get_prefixed('my_var'), 'current_value',
   'cfg__get_prefixed finds key when defined at current prefix');

is($fab->cfg__get_prefixed_scan('my_var'), 'current_value',
   'cfg__get_prefixed_scan finds current prefix first');

$fab->cfg__set('Fab/level2/my_var', undef);
delete $fab->{config}{'Fab/level2/my_var'};

is($fab->cfg__get_prefixed_scan('my_var'), 'level1_value',
   'cfg__get_prefixed_scan falls back to level1 when missing at current');

delete $fab->{config}{'Fab/level1/my_var'};
is($fab->cfg__get_prefixed_scan('my_var'), 'root_value',
   'cfg__get_prefixed_scan falls back to root prefix');

delete $fab->{config}{'Fab/my_var'};
is($fab->cfg__get_prefixed_scan('my_var'), 'base_value',
   'cfg__get_prefixed_scan falls back to base key');

is($fab->cfg__get_prefixed_scan('nonexistent'), undef,
   'cfg__get_prefixed_scan returns undef if missing everywhere');

$fab->cfg__set('Fab/my_var', 'root_value');
$fab->cfg__set('Fab/level1/my_var', 'level1_value');
$fab->cfg__set('Fab/level2/my_var', 'current_value');

is($fab->cfg__get_uplevel_scan(0, 'my_var'), 'current_value',
   'cfg__get_uplevel_scan(0) starts at current level');
is($fab->cfg__get_uplevel_scan(1, 'my_var'), 'level1_value',
   'cfg__get_uplevel_scan(1) skips current level');
is($fab->cfg__get_uplevel_scan(2, 'my_var'), 'root_value',
   'cfg__get_uplevel_scan(2) reaches root prefix');

throws_ok { $fab->cfg__get_uplevel_scan(3, 'my_var') } qr/E_UPLEVEL_TOO_DEEP/,
   'cfg__get_uplevel_scan beyond stack depth dies with E_UPLEVEL_TOO_DEEP';

$fab->cfg__set_prefixed('new_key', 'set_at_current');
is($fab->cfg__get('Fab/level2/new_key'), 'set_at_current',
   'cfg__set_prefixed writes to current prefix');

$fab->cfg__set_prefixed_uplevel(1, 'new_key', 'set_at_level1');
is($fab->cfg__get('Fab/level1/new_key'), 'set_at_level1',
   'cfg__set_prefixed_uplevel(1) writes to parent prefix');

throws_ok { $fab->cfg__set_prefixed_uplevel(5, 'k', 'v') } qr/E_UPLEVEL_TOO_DEEP/,
   'cfg__set_prefixed_uplevel beyond stack depth dies with E_UPLEVEL_TOO_DEEP';

$fab->cfg__set('Fab/fixup_key', 'orig_root_val');
delete $fab->{config}{'Fab/level1/fixup_key'};
delete $fab->{config}{'Fab/level2/fixup_key'};

$fab->cfg__set_prefixed_uplevel_fixup(2, 'fixup_key', 'new_root_val');
is($fab->cfg__get('Fab/fixup_key'), 'new_root_val', 'fixup updated target level');
is($fab->cfg__get('Fab/level1/fixup_key'), 'orig_root_val', 'fixup copied old value to level 1');
is($fab->cfg__get('Fab/level2/fixup_key'), 'orig_root_val', 'fixup copied old value to level 2');

$fab->cfg__set('Fab/stop_key', 'root_orig');
$fab->cfg__set('Fab/level1/stop_key', 'level1_custom');
delete $fab->{config}{'Fab/level2/stop_key'};

$fab->cfg__set_prefixed_uplevel_fixup(2, 'stop_key', 'root_new');
is($fab->cfg__get('Fab/level1/stop_key'), 'level1_custom', 'fixup stopped before existing value at level 1');
is($fab->cfg__get('Fab/level2/stop_key'), undef, 'fixup halted before reaching level 2');

done_testing();
