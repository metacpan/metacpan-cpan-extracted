use strict; use warnings;

use Text::ZPL;

my $struct = +{
  foo => 'bar',
  bar => 'baz',
  hash => +{
    x => 1, y => 2, z => 3,
    list => [ 1 .. 100 ],
  },
  hash2 => +{
    a => 1, b => 2, c => 3,
    list => [ 1 .. 100 ],
  },
};

decode_zpl( encode_zpl $struct ) for 1 .. 10_000;

