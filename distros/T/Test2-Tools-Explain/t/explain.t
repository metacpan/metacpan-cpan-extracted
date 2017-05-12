#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;
plan 2;

use Test2::Tools::Explain;

imported_ok( 'explain' );


is(
    [ explain( 42, [ 2112, 5150, 90125 ], { fish => 'paste', bingo => \'bongo' } ) ],
    [ '42',
<<'EOF',
[
  2112,
  5150,
  90125
]
EOF
<<'EOF'
{
  'bingo' => \'bongo',
  'fish' => 'paste'
}
EOF
] );
