# t/05-api-robustness.t
use strict;
use warnings;
use Test::More tests => 11; # Explicit plan for a flat test file
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

# --- cfg__pop robustness ---
my $fab_pop = Text::Fab->new();
$fab_pop->cfg__set('my_scalar', 'value');
dies_ok { $fab_pop->cfg__pop('my_scalar') } 'pop dies when called on a scalar key';

# --- cfg__prepend_elt robustness ---
my $fab_prepend = Text::Fab->new(config => {
    'Fab/list_keys' => { my_list => 1 },
    'Fab/hash_keys' => { my_hash => 1 },
});
$fab_prepend->cfg__set('my_scalar', 'value');

dies_ok { $fab_prepend->cfg__prepend_elt('my_scalar', 0, 'x') } 'prepend_elt dies when called on a scalar key';

dies_ok { $fab_prepend->cfg__prepend_elt('my_hash', 0, 'not a pair') }
    'prepend_elt on hash dies if value is not an arrayref pair';

lives_ok { $fab_prepend->cfg__prepend_elt('my_list', 0, ['a', 1]) }
    'prepend_elt on list LIVES when value is an arrayref (valid list element)';
is_deeply($fab_prepend->cfg__get('my_list'), [ ['a', 1] ], '...and the arrayref is inserted correctly');

# --- cfg__get_joined robustness ---
my $fab_join = Text::Fab->new(config => {
    'Fab/list_keys' => { my_list => 1 },
});
$fab_join->cfg__set('my_scalar', 'value');

dies_ok { $fab_join->cfg__get_joined('my_scalar', [',']) } 'get_joined dies when called on a scalar key';

throws_ok { $fab_join->cfg__get_joined('my_list', undef) } qr/requires an array reference for joiners/,
    'get_joined dies if joiners argument is undef';

throws_ok { $fab_join->cfg__get_joined('my_list', 'not_an_aref') } qr/requires an array reference for joiners/,
    'get_joined dies if joiners argument is not an array reference';

# --- out__get_joined robustness ---
my $fab_out_join = Text::Fab->new();

throws_ok { $fab_out_join->out__get_joined('spec', undef) } qr/requires an array reference for joiners/,
    'out__get_joined dies if joiners argument is undef';

throws_ok { $fab_out_join->out__get_joined('spec', 'not_an_aref') } qr/requires an array reference for joiners/,
    'out__get_joined dies if joiners argument is not an array reference';