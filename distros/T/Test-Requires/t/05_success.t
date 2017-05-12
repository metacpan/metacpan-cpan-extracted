use strict;
use warnings;
use Test::More tests => 1;
use Test::Requires;

test_requires 'Scalar::Util';
test_requires 'Data::Dumper';
test_requires 'Devel::Peek';

like Dumper("HOGE"), qr/\$VAR/;

