use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

subtest 'cfg__pop on lists' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/list_keys' => { my_list => 1 } });
    $fab->cfg__set('my_list', ['a', 'b', 'c', 'd']);
    $fab->cfg__set('my_scalar', 'val');

    is($fab->cfg__pop('my_list'), 'd', 'pop() returns single last element');
    is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c'], 'list modified after single pop');

    my @popped = $fab->cfg__pop('my_list', 2);
    is_deeply(\@popped, ['b', 'c'], 'pop($count) in list context returns correct slice');
    is_deeply($fab->cfg__get('my_list'), ['a'], 'list modified after count pop');

    throws_ok { $fab->cfg__pop('my_list', 5) } qr/E_LONG_POP/,
        'popping more elements than exist dies with E_LONG_POP';

    throws_ok { $fab->cfg__pop('my_scalar') } qr/E_TYPE_MISMATCH/,
        'pop on scalar dies with E_TYPE_MISMATCH';
    throws_ok { $fab->cfg__pop('my_list', 1, 2) } qr/E_TYPE_MISMATCH/,
        'pop on list with multiple args dies with E_TYPE_MISMATCH';
};

subtest 'cfg__prepend_elt on lists' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/list_keys' => { my_list => 1 } });
    $fab->cfg__set('my_list', ['b', 'd']);

    $fab->cfg__prepend_elt('my_list', 0, 'a');
    is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'd'], 'offset 0 inserts at beginning');

    $fab->cfg__prepend_elt('my_list', -1, 'c');
    is_deeply($fab->cfg__get('my_list'), ['a', 'b', 'c', 'd'], 'offset -1 inserts before last element');

    $fab->cfg__set('my_scalar', 'val');
    throws_ok { $fab->cfg__prepend_elt('my_scalar', 0, 'x') } qr/E_TYPE_MISMATCH/,
        'prepend_elt on scalar dies with E_TYPE_MISMATCH';
};

subtest 'cfg__get_joined on lists' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/list_keys' => { my_list => 1 } });
    $fab->cfg__set('my_list', ['k1', 'v1', 'k2', 'v2', 'k3']);

    is($fab->cfg__get_joined('my_list', ['=']), 'k1=v1=k2=v2=k3', 'single joiner joins list');
    is($fab->cfg__get_joined('my_list', ['=', '&']), 'k1=v1&k2=v2&k3', 'multiple joiners cycle');

    my $opt = { permitted_joiners_modulo => 2 };
    lives_ok { $fab->cfg__get_joined('my_list', ['=', '&'], $opt) }
        'permitted_joiners_modulo lives when (N-1) % mod == 0';

    $fab->cfg__append('my_list', 'v3');
    throws_ok { $fab->cfg__get_joined('my_list', ['=', '&'], $opt) } qr/permitted_joiners_modulo/,
        'permitted_joiners_modulo dies when (N-1) % mod != 0';

    $fab->cfg__set('my_scalar', 'val');
    throws_ok { $fab->cfg__get_joined('my_scalar', [',']) } qr/E_TYPE_MISMATCH/,
        'get_joined on scalar dies with E_TYPE_MISMATCH';
};

done_testing();
