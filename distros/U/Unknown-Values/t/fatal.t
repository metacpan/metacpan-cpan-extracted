
use Test::Most;

use lib 'lib';
use Unknown::Values 'fatal';

throws_ok { 1 == unknown }
qr/Comparison operations not allowed with 'fatal unknown' objects/,
  'Equality checks with fatal unknown values should be fatal';
throws_ok { !unknown }
qr/Boolean operations not allowed with 'fatal unknown' objects/,
  '... as should boolean operations';

# note that sort in void context is optimized away in modern Perls, so you
# have to assign it to *something*
throws_ok { my @foo = sort ( 1, unknown, 2 ) }
qr/Sorting operations not allowed with 'fatal unknown' objects/,
  '... or sorting operations';
throws_ok { print unknown }
qr/Printing not allowed with 'fatal unknown' objects/,
  '... or printing unknown values';

done_testing;
