use lib 'lib';

use Test::Most tests => 2;

eval '$foo = 1';
ok my $error = $@, 'evaling an undeclared variable should fail';
like $error, qr/Global symbol.*requires explicit package name/,
    '... and give us an appropriate error message';
