use 5.010001;
use Test2::V0;

{
  package Foo;
  use Moo;
  use Types::Standard qw( Int );
  use Types::TypedCodeRef -types;

  my $type = TypedCodeRef[ [ Int, Int ] => Int ];

  has adder => (
    is     => 'ro',
    isa    => $type,
    coerce => $type->coercion,
  );
}

my $check_int_type = object {
  prop blessed => 'Type::Tiny';
  call name => 'Int';
};

my $foo = Foo->new(adder => sub { $_[0] + $_[1] });
is $foo->adder, object {
  prop blessed => 'Sub::WrapInType';
  call params => array {
    item $check_int_type;
    item $check_int_type;
    end();
  };
  call returns => $check_int_type;
};

{
  package Bar;
  use Moo;
  use Types::Standard qw( Int );
  use Types::TypedCodeRef -types;

  has adder => (
    is     => 'ro',
    isa    => TypedCodeRef[ [ Int, Int ] => Int ],
    coerce => 1,
  );
}

like dies { Bar->new(adder => undef) }, do {
  my $str = quotemeta 'Undef did not pass type constraint "TypedCodeRef[ [Int, Int] => Int ]"';
  qr/$str/;
};

done_testing;
