use Test::Most 'die';

use lib 'lib';
use Unknown::Values;

my $value = unknown;
throws_ok { $value & 1 }
qr/Bit manipulation cannot be performed on unknown values/,
  'Bitwise & should be illegal';
throws_ok { $value | 1 }
qr/Bit manipulation cannot be performed on unknown values/,
  'Bitwise | should be illegal';
throws_ok { ~$value }
qr/Bit manipulation cannot be performed on unknown values/,
  'Bitwise ~ should be illegal';
throws_ok { $value ^ 1 }
qr/Bit manipulation cannot be performed on unknown values/,
  'Bitwise ^ should be illegal';

#use 5.12.0;
#diag $value ~~ 3;

done_testing;
