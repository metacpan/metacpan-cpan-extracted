# t/04-hash-api.t
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab', 'Module loads correctly');

# --- cfg__pop (on Hashes) ---
subtest 'cfg__pop on Hashes (multi-key delete)' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/hash_keys' => { my_hash => 1 } });
    $fab->cfg__set('my_hash', { a => 1, b => 2, c => 3, d => 4 });

    # Branch: delete a single key, testing scalar context return
    my $deleted_value = $fab->cfg__pop('my_hash', 'c');
    is($deleted_value, 3, 'Branch: returns value of single deleted key in scalar context');
    is_deeply($fab->cfg__get('my_hash'), { a => 1, b => 2, d => 4 }, '...and the hash is modified correctly');

    # Branch: delete multiple keys (including a non-existent one), testing list context return
    my @deleted_values = $fab->cfg__pop('my_hash', 'd', 'non_existent', 'a');
    is_deeply(\@deleted_values, [4, undef, 1], 'Branch: returns list of deleted values in list context');
    is_deeply($fab->cfg__get('my_hash'), { b => 2 }, '...and the hash is modified correctly after multiple deletes');

    # Branch: ensure original list behavior is unaffected
    my $fab_types = Text::Fab->new(config => { 'Fab/list_keys' => { my_list => 1 } });
    $fab_types->cfg__set('my_list', ['x', 'y', 'z']);
    $fab_types->cfg__set('my_scalar', 'value');
    is($fab_types->cfg__pop('my_list'), 'z', 'Branch: pop on list with no args still works');
    is($fab_types->cfg__pop('my_list', 1), 'y', 'Branch: pop on list with a count still works');
    dies_ok { $fab_types->cfg__pop('my_list', 1, 'extra_arg') } 'NEW: pop on list dies with more than one argument';
    dies_ok { $fab_types->cfg__pop('my_scalar', 'a_key') } 'NEW: pop with key arguments dies on a scalar';
};


# --- cfg__prepend_elt (on Hashes) ---
subtest 'cfg__prepend_elt on Hashes' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/hash_keys' => { my_hash => 1 } });
    $fab->cfg__set('my_hash', { b => 2 });

    # For hashes, offset is ignored, it's just an insertion/update.
    $fab->cfg__prepend_elt('my_hash', 0, ['a', 1]);
    is_deeply($fab->cfg__get('my_hash'), { a => 1, b => 2 }, 'Branch: prepends a key-value pair to the hash');
    
    # Test overwrite
    $fab->cfg__prepend_elt('my_hash', -1, ['a', 99]);
    is_deeply($fab->cfg__get('my_hash'), { a => 99, b => 2 }, 'Branch: overwrites an existing key correctly');
    
    dies_ok { $fab->cfg__prepend_elt('my_hash', 0, 'just_a_string') } 'Branch: dies if value is not an array reference';
    dies_ok { $fab->cfg__prepend_elt('my_hash', 0, ['key_only']) } 'Branch: dies if value is not a pair (odd number)';
    dies_ok { $fab->cfg__prepend_elt('my_hash', 0, ['k','v','extra']) } 'Branch: dies if value is not a pair (too many)';
};

# --- cfg__get_joined (on Hashes) ---
subtest 'cfg__get_joined on Hashes' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/hash_keys' => { my_hash => 1, num_hash => 1 } });
    $fab->cfg__set('my_hash', { c => 3, a => 1, b => 2 });

    # Branch 1: Default sort (string cmp) with cycling joiners
    is($fab->cfg__get_joined('my_hash', ['=', ' & ']), 'a=1 & b=2 & c=3', 'Branch: joins hash using default string sort on keys');
    
    # Branch 2: Custom sort (numeric)
    $fab->cfg__set('num_hash', { 10 => 'ten', 2 => 'two', 1 => 'one' });
    $fab->cfg__set('Fab/hash_key_sort_order', sub { $_[0] <=> $_[1] });
    is($fab->cfg__get_joined('num_hash', [' => ', ', ']), '1 => one, 2 => two, 10 => ten', 'Branch: joins hash using custom numeric sort');
    
    # Branch 3: Custom sort (reverse string)
    $fab->cfg__set('Fab/hash_key_sort_order', sub { $_[1] cmp $_[0] });
    is($fab->cfg__get_joined('my_hash', [':', ' ']), 'c:3 b:2 a:1', 'Branch: joins hash using custom reverse sort');
    
    # Test modulo option, which now applies to inter-pair joiners
    # 3 pairs => 2 inter-pair joiners. 2 % 2 == 0. Lives.
    lives_ok { $fab->cfg__get_joined('my_hash', ['='], { permitted_joiners_modulo => 2 }) } 'Branch: modulo option lives for valid number of pairs';
    
    # 2 pairs => 1 inter-pair joiner. 1 % 2 != 0. Dies.
    $fab->cfg__set('my_hash', { a => 1, b => 2 });
    dies_ok { $fab->cfg__get_joined('my_hash', ['='], { permitted_joiners_modulo => 2 }) } 'Branch: modulo option dies for invalid number of pairs';
    
    # Edge cases
    $fab->cfg__set('my_hash', { key => 'val' });
    is($fab->cfg__get_joined('my_hash', ['=']), 'key=val', 'Edge case: single-pair hash still uses intra-pair joiner');
    $fab->cfg__set('my_hash', {});
    is($fab->cfg__get_joined('my_hash', ['=']), '', 'Edge case: empty hash gives empty string');
};

done_testing();