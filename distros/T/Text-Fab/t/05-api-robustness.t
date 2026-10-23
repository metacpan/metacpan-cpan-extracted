use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

my $fab = Text::Fab->new(config => {
    'Fab/list_keys' => { my_list => 1 },
    'Fab/hash_keys' => { my_hash => 1 },
});
$fab->cfg__set('my_scalar', 'val');

throws_ok { $fab->cfg__pop('my_scalar') } qr/E_TYPE_MISMATCH/,
    'cfg__pop on scalar dies with E_TYPE_MISMATCH';

throws_ok { $fab->cfg__prepend_elt('my_scalar', 0, 'x') } qr/E_TYPE_MISMATCH/,
    'cfg__prepend_elt on scalar dies with E_TYPE_MISMATCH';

throws_ok { $fab->cfg__prepend_elt('my_hash', 0, 'not_an_aref') } qr/E_TYPE_MISMATCH/,
    'cfg__prepend_elt on hash with non-arrayref dies with E_TYPE_MISMATCH';

lives_ok { $fab->cfg__prepend_elt('my_list', 0, ['nested', 'array']) }
    'cfg__prepend_elt on list accepts arrayref element';
is_deeply($fab->cfg__get('my_list'), [['nested', 'array']], 'nested element inserted intact');

throws_ok { $fab->cfg__get_joined('my_scalar', [',']) } qr/E_TYPE_MISMATCH/,
    'cfg__get_joined on scalar dies with E_TYPE_MISMATCH';

throws_ok { $fab->cfg__get_joined('my_list', 'not_aref') } qr/E_TYPE_MISMATCH/,
    'cfg__get_joined with non-arrayref joiners dies with E_TYPE_MISMATCH';

throws_ok { $fab->cfg__get_joined('my_list', undef) } qr/E_TYPE_MISMATCH/,
    'cfg__get_joined with undef joiners dies with E_TYPE_MISMATCH';

throws_ok { $fab->out__get_joined('spec', 'not_aref') } qr/E_TYPE_MISMATCH/,
    'out__get_joined with non-arrayref joiners dies with E_TYPE_MISMATCH';

throws_ok { $fab->out__get_joined('spec', undef) } qr/E_TYPE_MISMATCH/,
    'out__get_joined with undef joiners dies with E_TYPE_MISMATCH';

done_testing();
