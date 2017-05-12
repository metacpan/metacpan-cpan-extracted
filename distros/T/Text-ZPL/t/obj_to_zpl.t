use Test::More;
use strict; use warnings FATAL => 'all';

use Text::ZPL;


{ package Foo;
  use strict; use warnings FATAL => 'all';
  sub new { bless +{ @_[1 .. $#_] }, $_[0] }
  sub TO_ZPL { +{ %{ $_[0] } } }
}

{ package FooArray;
  use strict; use warnings FATAL => 'all';
  sub new { bless [@_[1 .. $#_]], $_[0] }
  sub TO_ZPL { [ @{ $_[0] } ] }
}

my $obj = Foo->new(foo => 1, bar => 2);
my $zpl = encode_zpl($obj);
my $data = decode_zpl($zpl);
is_deeply $data, +{ foo => 1, bar => 2 },
  'shallow TO_ZPL ok';


$zpl = encode_zpl(
  +{
    baz  => $obj,
    quux => 'weeble',
    fwee => FooArray->new(1 .. 3),
  },
);

is_deeply decode_zpl($zpl),
  +{
    fwee => [ 1 .. 3 ],
    baz => +{ foo => 1, bar => 2 }, 
    quux => 'weeble',
  },
  'deeper hash + array TO_ZPL ok';

eval {; encode_zpl(FooArray->new) };
ok $@, 'trying to serialize top-lev ARRAY dies';

eval {; encode_zpl(bless +{}, 'Dies') };
like $@, qr/Dies/, 'trying to serialize obj without TO_ZPL dies';

done_testing
