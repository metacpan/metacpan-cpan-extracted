package Test::Mocha::Types;
# ABSTRACT: Internal type constraints
$Test::Mocha::Types::VERSION = '0.67';
use Type::Library
  -base,
  -declare => qw(
  Matcher
  NumRange
  Slurpy
);

use Type::Utils -all;
use Types::Standard 0.008 qw( Dict InstanceOf Num Tuple );

union Matcher,
  [
    class_type( { class => 'Type::Tiny' } ),
    class_type( { class => 'Moose::Meta::TypeConstraint' } ),
  ];

declare NumRange, as Tuple [ Num, Num ], where { $_->[0] < $_->[1] };

# this hash structure is created by Types::Standard::slurpy()
declare Slurpy, as Dict [ slurpy => InstanceOf ['Type::Tiny'] ];

1;
