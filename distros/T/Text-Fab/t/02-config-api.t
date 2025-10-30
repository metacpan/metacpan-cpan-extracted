use strict;
use warnings;
use Test::More tests => 13; # Explicit, top-level plan
use Text::Fab;

use_ok('Text::Fab', 'Module loads correctly');

my $fab = Text::Fab->new();
isa_ok($fab, 'Text::Fab', 'new() returns a valid object');

# --- cfg__set and cfg__get ---
my $fab_set = Text::Fab->new();
$fab_set->cfg__set('scalar_key', 'a value');
is($fab_set->cfg__get('scalar_key'), 'a value', 'cfg__set/get: Can set and get a simple scalar');
$fab_set->cfg__set('scalar_key', 'a new value');
is($fab_set->cfg__get('scalar_key'), 'a new value', 'cfg__set/get: Can overwrite an existing scalar');
is($fab_set->cfg__get('non_existent_key'), undef, 'cfg__set/get: Non-existent key returns undef');

# --- cfg__append ---
# Branch 1: Appending to a scalar key
my $fab_scalar = Text::Fab->new();
$fab_scalar->cfg__set('my_scalar', 'start.');
$fab_scalar->cfg__append('my_scalar', 'middle.', 'end');
is($fab_scalar->cfg__get('my_scalar'), 'start.middle.end', 'cfg__append: Appends correctly to an existing scalar');

# Branch 1 Edge Case: Appending to a non-existent scalar
my $fab_new_scalar = Text::Fab->new();
$fab_new_scalar->cfg__append('new_scalar', 'value');
is($fab_new_scalar->cfg__get('new_scalar'), 'value', 'cfg__append: Appends correctly to a non-existent scalar');

# Branch 2: Appending to a list key
my $fab_list = Text::Fab->new();
$fab_list->cfg__get('Fab/list_keys')->{my_list} = 1;
$fab_list->cfg__set('my_list', ['a']);
$fab_list->cfg__append('my_list', 'b', 'c');
is_deeply($fab_list->cfg__get('my_list'), ['a', 'b', 'c'], 'cfg__append: Appends correctly to an existing list');

# Branch 2 Edge Case: Appending to a non-existent list
my $fab_new_list = Text::Fab->new();
$fab_new_list->cfg__get('Fab/list_keys')->{new_list} = 1;
$fab_new_list->cfg__append('new_list', 'value');
is_deeply($fab_new_list->cfg__get('new_list'), ['value'], 'cfg__append: Appends correctly to a non-existent list');

# --- cfg__get_prefixed ---
my $fab_prefixed = Text::Fab->new();
$fab_prefixed->cfg__set('my_var', 'base_value');
$fab_prefixed->cfg__set('Fab/level1/my_var', 'level1_value');
$fab_prefixed->cfg__set('Fab/level2/my_var', 'level2_value');

# Branch 1: Finds the most recently pushed prefixed value
$fab_prefixed->cfg__set('Fab/call_stack_prefixes', ['Fab/', 'Fab/level1/', 'Fab/level2/']);
is($fab_prefixed->cfg__get_prefixed('my_var'), 'level2_value', 'cfg__get_prefixed: Finds the most recent prefixed value');

# Test that it finds an intermediate prefix if the most recent is removed
pop @{$fab_prefixed->cfg__get('Fab/call_stack_prefixes')}; # Remove 'Fab/level2/'
is($fab_prefixed->cfg__get_prefixed('my_var'), 'level1_value', 'cfg__get_prefixed: Finds an intermediate prefixed value');

# Branch 2: Falls back to the base key if no prefixed versions are found
my $fab_fallback = Text::Fab->new();
$fab_fallback->cfg__set('my_var', 'base_only');
$fab_fallback->cfg__set('Fab/call_stack_prefixes', ['Fab/', 'Fab/other/']); # No matching prefix
is($fab_fallback->cfg__get_prefixed('my_var'), 'base_only', 'cfg__get_prefixed: Falls back to base key');

# Branch 3: Returns undef if no key is found at all
my $fab_nothing = Text::Fab->new();
$fab_nothing->cfg__set('Fab/call_stack_prefixes', ['Fab/', 'Fab/other/']);
is($fab_nothing->cfg__get_prefixed('non_existent'), undef, 'cfg__get_prefixed: Returns undef when no key is found');