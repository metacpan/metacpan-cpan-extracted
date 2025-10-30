# t/03-advanced-api.t
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab', 'Module loads correctly');

# --- cfg__pop ---
subtest 'cfg__pop' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/list_keys' => { my_list => 1 } });
    $fab->cfg__set('my_list', ['a', 'b', 'c', 'd']);
    $fab->cfg__set('my_scalar', 'value');

    is($fab->cfg__pop('my_list'), 'd', 'Branch: pop with no count returns single last element');
    is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c'], '...and the list is modified correctly');

    is_deeply([$fab->cfg__pop('my_list', 2)], ['b', 'c'], 'Branch: pop with a count returns correct elements');
    is_deeply($fab->cfg__get('my_list'), ['a'], '...and the list is modified correctly');

    dies_ok { $fab->cfg__pop('my_list', 2) } 'Branch: pop dies if trying to pop more elements than exist';
    dies_ok { $fab->cfg__pop('my_scalar') } 'Branch: pop dies when called on a non-list key';
};

# --- cfg__prepend_elt ---
subtest 'cfg__prepend_elt' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/list_keys' => { my_list => 1 } });
    $fab->cfg__set('my_list', ['b', 'd']);

    $fab->cfg__prepend_elt('my_list', 0, 'a');
    is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'd'], 'Branch: offset 0 prepends to the beginning of the list');
    
    $fab->cfg__prepend_elt('my_list', -1, 'c');
    is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c', 'd'], 'Branch: offset -1 inserts before the last element');

    dies_ok { $fab->cfg__prepend_elt('my_scalar', 0, 'x') } 'Branch: prepend_elt dies when called on a non-list key';
};

# --- cfg__get_joined ---
subtest 'cfg__get_joined' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/list_keys' => { my_list => 1 } });
    $fab->cfg__set('my_list', ['k1', 'v1', 'k2', 'v2', 'k3']);
    
    is($fab->cfg__get_joined('my_list', ['=']), 'k1=v1=k2=v2=k3', 'Branch: works with a single joiner');

    is($fab->cfg__get_joined('my_list', ['=', '&']), 'k1=v1&k2=v2&k3', 'Branch: cycles through multiple joiners');

    my $options = { permitted_joiners_modulo => 2 };
    # 4 joiners used (5 elements - 1). 4 % 2 == 0. This should pass.
    lives_ok { $fab->cfg__get_joined('my_list', ['=', '&'], $options) } 'Branch: options permit an even number of joiners';

    # Now add an element. 5 joiners will be used. 5 % 2 != 0. This must die.
    $fab->cfg__append('my_list', 'v3');
    throws_ok { $fab->cfg__get_joined('my_list', ['=', '&'], $options) } qr/violates permitted_joiners_modulo/, 'Branch: options cause die on odd number of joiners';
    
    $fab->cfg__set('my_list', ['one']);
    is($fab->cfg__get_joined('my_list', [',']), 'one', 'Edge Case: returns single element with no joiners');

    $fab->cfg__set('my_list', []);
    is($fab->cfg__get_joined('my_list', [',']), '', 'Edge Case: returns empty string for empty list');

    dies_ok { $fab->cfg__get_joined('my_scalar', [',']) } 'Branch: get_joined dies when called on a non-list key';
};

# --- out__get_joined ---
subtest 'out__get_joined' => sub {
    my $fab = Text::Fab->new();
    $fab->out__target_section('body', 'TestNS');
    # Manually create a section with mixed content
    $fab->{sections}{TestNS}{body} = [
        ['text', 'Part 1'],
        ['embed', '_main', 'footer', {}],
        ['text', 'Part 2'],
        ['text', 'Part 3'],
    ];

    my $spec = 'TestNS:body';
    is($fab->out__get_joined($spec, [', ']), 'Part 1, Part 2, Part 3', 'Branch: joins text parts of a section, ignoring embeds');

    is($fab->out__get_joined($spec, [',', ';']), 'Part 1,Part 2;Part 3', 'Branch: cycles joiners correctly for section content');
};

done_testing();