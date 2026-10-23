use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

my $fab = Text::Fab->new(config => {
    'Fab/list_keys' => { my_list => 1, multi_list => 1 },
});

$fab->cfg__set('my_scalar', 'initial');
is($fab->cfg__get('my_scalar'), 'initial', 'cfg__set/get: scalar single value');

throws_ok { $fab->cfg__set('my_scalar', 'val1', 'val2', 'val3') } qr/E_TYPE_MISMATCH/,
    'cfg__set with multiple values on scalar dies with E_TYPE_MISMATCH';

is($fab->cfg__get('nonexistent'), undef, 'cfg__get: nonexistent key returns undef');

throws_ok { $fab->cfg__get('my_scalar', 0) } qr/E_TYPE_MISMATCH/,
    'cfg__get with $offset on scalar dies with E_TYPE_MISMATCH';

$fab->cfg__set('my_list', 'a', 'b', 'c');
is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c'], 'cfg__set: list key accepts @values as element list');

is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c'], 'cfg__get returns ARRAY ref when no offset');

$fab->cfg__set('my_list', ['x', 'y']);
is_deeply($fab->cfg__get('my_list'), ['x', 'y'], 'cfg__set: list key accepts arrayref');

is($fab->cfg__get('my_list', 0), 'x', 'cfg__get with $offset retrieves first element');
is($fab->cfg__get('my_list', 1), 'y', 'cfg__get with $offset retrieves second element');
is($fab->cfg__get('my_list', -1), 'y', 'cfg__get with negative $offset works');
is($fab->cfg__get('my_list', 99), undef, 'cfg__get with out-of-bounds $offset returns undef');

$fab->cfg__set('my_scalar', 'foo');
$fab->cfg__append('my_scalar', 'bar', 'baz');
is($fab->cfg__get('my_scalar'), 'foobarbaz', 'cfg__append: scalar appends all values');

$fab->cfg__set('my_list', ['a']);
$fab->cfg__append('my_list', 'b', 'c');
is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c'], 'cfg__append: list appends multiple values');

$fab->cfg__append('new_scalar', 'hello', ' world');
is($fab->cfg__get('new_scalar'), 'hello world', 'cfg__append: nonexistent scalar initialized');

$fab->cfg__append('multi_list', 'first', 'second');
is_deeply($fab->cfg__get('multi_list'), ['first', 'second'], 'cfg__append: nonexistent list initialized');

$fab->cfg__set('my_scalar', 'end');
$fab->cfg__prepend('my_scalar', 'start', 'middle');
is($fab->cfg__get('my_scalar'), 'startmiddleend', 'cfg__prepend: scalar prepends values in order');

$fab->cfg__set('my_list', ['c']);
$fab->cfg__prepend('my_list', 'a', 'b');
is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c'], 'cfg__prepend: list unshifts values preserving order');

$fab->cfg__prepend('prep_scalar', 'init');
is($fab->cfg__get('prep_scalar'), 'init', 'cfg__prepend: nonexistent scalar initialized');

my $fab_empty = Text::Fab->new(config => { 'Fab/list_keys' => { empty_list => 1 } });
$fab_empty->cfg__prepend('empty_list', 'x', 'y');
is_deeply($fab_empty->cfg__get('empty_list'), ['x', 'y'], 'cfg__prepend: nonexistent list initialized');

my $fab_hash = Text::Fab->new(config => { 'Fab/hash_keys' => { h => 1 } });
throws_ok { $fab_hash->cfg__prepend('h', 'foo') } qr/E_TYPE_MISMATCH/,
    'cfg__prepend on hash dies with E_TYPE_MISMATCH';

done_testing();
