use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

subtest 'cfg__get with offset (as key) on Hashes' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/hash_keys' => { my_hash => 1 } });
    $fab->cfg__set('my_hash', { name => 'Alice', role => 'Admin' });

    is($fab->cfg__get('my_hash', 'name'), 'Alice', 'cfg__get with offset returns value for key');
    is($fab->cfg__get('my_hash', 'role'), 'Admin', 'cfg__get with offset returns value for second key');
    is($fab->cfg__get('my_hash', 'missing'), undef, 'cfg__get with missing key returns undef');

    my $href = $fab->cfg__get('my_hash');
    is_deeply($href, { name => 'Alice', role => 'Admin' }, 'cfg__get returns HASH ref when no offset');
};

subtest 'cfg__append on Hashes with key/value semantics' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/hash_keys' => { params => 1, new_hash => 1 } });
    $fab->cfg__set('params', { host => 'localhost' });

    $fab->cfg__append('params', port => 8080, user => 'root');
    is_deeply($fab->cfg__get('params'), { host => 'localhost', port => 8080, user => 'root' },
        'append key-value pairs merges into hash');

    $fab->cfg__append('params', { env => 'prod', port => 443 });
    is_deeply($fab->cfg__get('params'), { host => 'localhost', port => 443, user => 'root', env => 'prod' },
        'append hashref merges and overwrites existing keys');

    $fab->cfg__append('new_hash', k1 => 'v1');
    is($fab->cfg__get('new_hash', 'k1'), 'v1', 'append to nonexistent hash autovivifies');

    throws_ok { $fab->cfg__append('params', 'orphan_key') } qr/E_TYPE_MISMATCH/,
        'append odd number of elements to hash dies with E_TYPE_MISMATCH';

    throws_ok { $fab->cfg__prepend('params', k => 'v') } qr/E_TYPE_MISMATCH/,
        'cfg__prepend on hash dies with E_TYPE_MISMATCH';
};

subtest '#append directive on Hashes' => sub {
    my $fab = Text::Fab->new();
    $fab->process_string("#append Fab/hash_keys app_cfg 1");
    is($fab->cfg__get('Fab/hash_keys', 'app_cfg'), 1, '#append on Fab/hash_keys succeeds with key val');

    $fab->process_string("#append app_cfg timeout 30 retries 3");
    is($fab->cfg__get('app_cfg', 'timeout'), 30, 'app_cfg timeout parsed and appended');
    is($fab->cfg__get('app_cfg', 'retries'), 3, 'app_cfg retries parsed and appended');

    $fab->process_string("#append app_cfg debug 1");
    is($fab->cfg__get('app_cfg', 'debug'), 1, 'app_cfg debug parsed and appended');
};

subtest 'cfg__pop on Hashes (multi-key delete)' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/hash_keys' => { my_hash => 1 } });
    $fab->cfg__set('my_hash', { a => 1, b => 2, c => 3, d => 4 });

    my $val = $fab->cfg__pop('my_hash', 'c');
    is($val, 3, 'pop single key in scalar context returns deleted value');
    is_deeply($fab->cfg__get('my_hash'), { a => 1, b => 2, d => 4 }, 'hash reflects single deletion');

    my @vals = $fab->cfg__pop('my_hash', 'd', 'non_existent', 'a');
    is_deeply(\@vals, [4, undef, 1], 'pop multiple keys in list context returns slice');
    is_deeply($fab->cfg__get('my_hash'), { b => 2 }, 'hash reflects multiple deletions');

    my @empty = $fab->cfg__pop('my_hash');
    is_deeply(\@empty, [], 'pop on hash with no keys returns empty list');
};

subtest 'cfg__prepend_elt on Hashes' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/hash_keys' => { my_hash => 1 } });
    $fab->cfg__set('my_hash', { b => 2 });

    $fab->cfg__prepend_elt('my_hash', 0, ['a', 1]);
    is_deeply($fab->cfg__get('my_hash'), { a => 1, b => 2 }, 'inserts key-value pair');

    $fab->cfg__prepend_elt('my_hash', -1, ['a', 99]);
    is_deeply($fab->cfg__get('my_hash'), { a => 99, b => 2 }, 'overwrites existing key');

    throws_ok { $fab->cfg__prepend_elt('my_hash', 0, 'scalar') } qr/E_TYPE_MISMATCH/,
        'prepend_elt on hash dies with E_TYPE_MISMATCH if value is not an arrayref';
    throws_ok { $fab->cfg__prepend_elt('my_hash', 0, ['key_only']) } qr/E_TYPE_MISMATCH/,
        'prepend_elt on hash dies with E_TYPE_MISMATCH if arrayref length != 2';
};

subtest 'cfg__get_joined on Hashes with sorting' => sub {
    my $fab = Text::Fab->new(config => {
        'Fab/hash_keys' => { my_hash => 1, num_hash => 1 }
    });
    $fab->cfg__set('my_hash', { c => 3, a => 1, b => 2 });

    is($fab->cfg__get_joined('my_hash', ['=', ' & ']), 'a=1 & b=2 & c=3',
       'joins hash with default sort');

    $fab->cfg__set('num_hash', { 10 => 'ten', 2 => 'two', 1 => 'one' });
    $fab->cfg__set('Fab/hash_key_sort_order', sub { $_[0] <=> $_[1] });
    is($fab->cfg__get_joined('num_hash', [' => ', ', ']), '1 => one, 2 => two, 10 => ten',
       'joins hash with custom numeric sorter receiving keys in @_');

    $fab->cfg__set('my_hash', { k => 'v' });
    is($fab->cfg__get_joined('my_hash', ['=']), 'k=v', 'single-pair hash joins correctly');

    $fab->cfg__set('my_hash', {});
    is($fab->cfg__get_joined('my_hash', ['=']), '', 'empty hash returns empty string');
};

subtest 'out__create_section and out__target_section' => sub {
    my $fab = Text::Fab->new();
    $fab->out__target_section('sec1', 'NS');
    push @{$fab->{sections}{NS}{sec1}}, ['text', 'initial_content'];
    is($fab->out__get_joined('NS:sec1', [', ']), 'initial_content', 'target_section accumulated text');

    $fab->out__create_section('sec1', 'NS');
    is_deeply($fab->{sections}{NS}{sec1}, [], 'out__create_section cleared existing section content');
};

done_testing();
